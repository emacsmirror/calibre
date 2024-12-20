;;; calibre-device.el --- Interact with external reading devices  -*- lexical-binding: t; -*-

;; Copyright (C) 2024  Free Software Foundation, Inc.

;; This file is part of calibre.el.

;; calibre.el is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; calibre.el is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with calibre.el.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;; This file file contains the infrastructure to interact with external
;; reading devices, such as transfering books to those devices.

;;; Code:
(require 'calibre-book)
(require 'calibre-core)

(defconst calibre-device--process-buffer "*ebook-device*"
  "The name of the buffer containing output from ebook-device processes.")

(defun calibre-device-send-book (book &optional force)
  "Transfer BOOK to an external device.

Overwrite an existing file if FORCE is non-nil."
  (let* ((library-path (calibre-book--file book
                                           (calibre-book--pick-format book)))
         (name (file-relative-name
                library-path
               (expand-file-name (calibre-book-path book)
                                 (calibre--library))))
         (device-path
          (file-name-concat "dev:/"
                            (car (calibre-book-authors book))
                            name)))
    (make-process
     :name "ebook-device - transfer"
     :command `(,calibre-ebook-device-executable
                "cp" ,@(if force '("--force") nil) ,library-path ,device-path)
     :buffer (get-buffer-create calibre-device--process-buffer)
     :sentinel (lambda (_ event)
                 (unless (string= event "finished\n")
                   (message "Error transfering \"%s\" to device" (calibre-book-title book)))))))

(defun calibre-device-send-books (books &optional force)
  "Transfer BOOKS to an external device.

Overwrite existing files if FORCE is non-nil."
  (interactive (list (calibre--get-active-books)
                     current-prefix-arg)
               calibre-librar-mode)
  (dolist (book books)
    (calibre-device-send-book book force)))

(defun calibre-device-eject ()
  "Eject an external device."
  (interactive)
  (make-process
   :name "ebook-device - eject"
   :command `(,calibre-ebook-device-executable "eject")
   :buffer (get-buffer-create calibre-device--process-buffer)
   :sentinel (lambda (_ event)
               (if (string= event "finished\n")
                   (message "Device ejected")
                 (message "Error ejecting device")))))

(provide 'calibre-device)
;;; calibre-device.el ends here
