;;; calibre-library.el --- View and interact with the Calibre library -*- lexical-binding:t -*-

;; Copyright (C) 2023  Free Software Foundation, Inc.

;; Author: Kjartan Oli Agustsson <kjartanoli@disroot.org>
;; Maintainer: Kjartan Oli Agustsson <kjartanoli@disroot.org>

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;; View the contents of a Library, add new books, remove books, and
;; open books in Emacs.

;;; Code:
(require 'dired)
(require 'compat)
(require 'calibre-db)
(require 'calibre-book)
(require 'calibre-search)
(require 'calibre-virtual-library)
(require 'calibre-edit)

(defcustom calibre-external-programs nil
  "A mapping of formats to external programs used to read them.

This is an alist, where each entry is of the form (FORMAT
. PROGRAM).  FORMAT is a symbol identifying a book format and
PROGRAM is a string naming an external program to use when
opening books in that format."
  :type '(repeat (cons (symbol :tag "Format") (string :tag "Program")))
  :group 'calibre
  :package-version '("calibre" . "1.4.0"))

;;;###autoload
(defun calibre-library-add-book (file)
  "Add FILE to the Calibre library."
  (interactive "f")
  (calibre-library-add-books (list file)))

(defun calibre-library-add-books (files)
  "Add FILES to the Calibre library."
  (calibre-exec--queue-command
   `("add" "-r" ,@(mapcar #'expand-file-name files)))
  (calibre-exec--start-execution))

;;;###autoload
(defun calibre-dired-add ()
  "Add marked files to the Calibre library."
    (interactive)
    (if (derived-mode-p 'dired-mode)
        (calibre-library-add-books (dired-get-marked-files))))

(defun calibre-library-remove-books (books)
  "Remove BOOKS from the Calibre library."
  (let ((ids (mapcar #'int-to-string (mapcar #'calibre-book-id books))))
    (calibre-exec--queue-command `("remove" ,(string-join ids ",")))))

(defun calibre-library-mark-remove (&optional _num)
  "Mark a book for removal and move to the next line."
  (interactive "p" calibre-library-mode)
  (tabulated-list-put-tag (char-to-string calibre-del-marker) t))

(defun calibre-library-mark-unmark (&optional _num)
  "Clear any marks on a book and move to the next line."
  (interactive "p" calibre-library-mode)
  (let ((book (tabulated-list-get-id)))
    (beginning-of-line)
    (when (char-equal (char-after) ?M)
      (calibre-edit-revert book))
    (calibre-library--find-book book)
    (tabulated-list-put-tag " " t)))

(defun calibre-library-execute ()
  "Performed marked Library actions."
  (interactive nil calibre-library-mode)
  (let (remove-list modified-list)
    (save-excursion
      (goto-char (point-min))
      (while (not (eobp))
        (let ((book (tabulated-list-get-id))
              (mark (char-after)))
          (cond
            ((eql mark calibre-del-marker) (push book remove-list))
            ((eql mark calibre-mod-marker) (push book modified-list))))
        (forward-line)))
    (when remove-list (calibre-library-remove-books remove-list))
    (when modified-list (calibre-edit-commit-edits modified-list)))
  (calibre-library-revert)
  (setf calibre-edit--edited-books nil)
  (calibre-exec--start-execution)
  (tabulated-list-clear-all-tags))

(defun calibre-library-revert (&rest _IGNORED)
  "Revert the *LIBRARY* buffer."
  (let ((pos (tabulated-list-get-id)))
    (calibre-library--refresh t)
    (if (not pos)
        (goto-char (point-max))
      (calibre-library--find-book pos))))

(defun calibre-library-open-book (book &optional arg)
  "Open BOOK in its preferred format.
If called with a prefix argument prompt the user for the format."
  (interactive (list (tabulated-list-get-id)
                     current-prefix-arg)
               calibre-library-mode)
  (let ((format (if arg
                    (completing-read "Format: " (calibre-book-formats book) nil t)
                  (calibre-book--pick-format book))))
    (let ((program (alist-get format calibre-external-programs)))
      (if program
          (calibre-library-open-book-external book program)
        (find-file (calibre-book--file book format))))))

(defun calibre-library-open-book-other-window (book &optional arg)
  "Open BOOK in its preferred format, in another window.
If called with a prefix argument prompt the user for the format."
  (interactive (list (tabulated-list-get-id)
                     current-prefix-arg)
               calibre-library-mode)
  (let ((format (if arg
                    (completing-read "Format: " (calibre-book-formats book) nil t)
                  (calibre-book--pick-format book))))
    (find-file-other-window (calibre-book--file book format))))

(defun calibre-library-open-book-external (book &optional command arg)
  "Open BOOK in an external program.
If called with a prefix argument prompt the user for the format."
  (interactive (list (tabulated-list-get-id)
                     nil
                     current-prefix-arg)
               calibre-library-mode)
  (let* ((format (if arg
                    (completing-read "Format: " (calibre-book-formats book) nil t)
                  (calibre-book--pick-format book)))
         (command (if command
                      command
                    (read-shell-command "Open with: " (alist-get format calibre-external-programs)))))
    (start-process (format "%s-external" (calibre-book-title book))
                   nil
                   command
                   (calibre-book--file book format))))

(defvar-keymap calibre-library-mode-map
  :doc "Local keymap for Calibre Library buffers."
  :parent tabulated-list-mode-map
  "d" #'calibre-library-mark-remove
  "u" #'calibre-library-mark-unmark
  "e" #'calibre-edit-book
  "x" #'calibre-library-execute
  "a" #'calibre-library-add-book
  "v" #'calibre-select-virtual-library
  "s" #'calibre-search
  "RET" #'calibre-library-open-book
  "o" #'calibre-library-open-book-other-window)

(define-derived-mode calibre-library-mode tabulated-list-mode
  "Library Mode"
  (setf tabulated-list-padding 2
        mode-line-process '(calibre-exec--commands ":Updating"))
  (setq-local revert-buffer-function #'calibre-library-revert)
  (setq-local font-lock-defaults
              '(calibre-font-lock-keywords t nil nil beginning-of-line))
  (calibre-library--set-header))

;;;###autoload
(defun calibre-library ()
  "List all books in Calibre Library `calibrary-dir'."
  (interactive)
  (let ((buffer (get-buffer-create calibre-library-buffer)))
    (with-current-buffer buffer
      (calibre-library-mode)
      (calibre-library--refresh t)
      (display-buffer buffer))))

(provide 'calibre-library)
;;; calibre-library.el ends here
