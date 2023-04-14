;;; calibre.el --- Interact with Calibre libraries from Emacs -*- lexical-binding:t -*-

;; Copyright (C) 2023  Kjartan Oli Agustsson

;; Author: Kjartan Oli Agustsson <kjartanoli@disroot.org>
;; Maintainer: Kjartan Oli Agustsson <kjartanoli@disroot.org>

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
;; Interact with Calibre libraries from within Emacs.
;; View the contents of your library, including much of the metadata
;; associated with each book, and read them, all from within Emacs.

;;; Code:
(require 'calibre-book)
(require 'calibre-db)

(defgroup calibre nil
  "Interact with a Calibre library."
  :group 'calibre)

(defcustom calibre-library-dir "~/Documents/Calibre"
  "The root directory of the Calibre library."
  :type 'directory
  :set (lambda (symbol value)
         (set-default symbol value)
         (setf calibre--db nil))
  :package-version '("calibre" . "0.1.0"))

(defcustom calibre-format-preferences '(pdf epub)
  "The preference order of file formats."
  :type '(repeat symbol :tag "Format")
  :package-version '("calibre" . "0.1.0"))

(defvar calibre--books nil)
(defun calibre--books (&optional force)
  "Return the in memory list of books.
If FORCE is non-nil the list is refreshed from the database."
  (when (or force (not calibre--books))
    (setf calibre--books (calibre-db--get-books)))
  calibre--books)

(provide 'calibre)
;;; calibre.el ends here
