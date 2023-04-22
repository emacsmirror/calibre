;;; calibre.el --- Interact with Calibre libraries from Emacs -*- lexical-binding:t -*-

;; Copyright (C) 2023  Kjartan Oli Agustsson

;; Author: Kjartan Oli Agustsson <kjartanoli@disroot.org>
;; Maintainer: Kjartan Oli Agustsson <kjartanoli@disroot.org>
;; Version: 1.0.5
;; Package-Requires: ((emacs "29.1"))
;; URL: https://git.disroot.org/kjartanoli/calibre.el

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

(defgroup calibre nil
  "Interact with a Calibre library."
  :group 'emacs)

(defcustom calibre-calibredb-executable "calibredb"
  "The calibredb executable to use."
  :type 'string
  :package-version '("calibre" . "1.0.4"))

(defcustom calibre-libraries nil
  "An alist mapping library names to directories."
  :type '(repeat :tag "Libraries" (cons :tag "Library"
                                   (string :tag "Name")
                                   (directory :tag "Location")))
  :package-version '("calibre" . "0.1.0"))

(defun calibre--library-names ()
  "Return a list of the names of defined libraries."
  (mapcar #'car calibre-libraries))

(provide 'calibre)
;;; calibre.el ends here
