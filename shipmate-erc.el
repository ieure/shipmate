;;; shipmate-erc.el --- Package tracking support for ERC  -*- lexical-binding: t; -*-

;; Copyright (C) 2018  Ian Eure

;; Author: Ian Eure <ian@retrospec.tv>
;; Keywords: matching, hypermedia

;; This program is free software; you can redistribute it and/or modify
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

;; Turn tracking numbers in chats into ERC buttons.

;;; Code:

(require 'shipmate)
(require 'erc-button)

(defun shipmate-erc-enable ()
  "Enable Shipmate support in ERC.

   Matches tracking numbers and turns them into buttons."
  (add-to-list 'erc-button-alist
               (list (mapcar (lambda (s) (plist-get (cdr s) :regexp)) shipmate-shippers)
                     0 t #'shipmate-browse-url 0)))

(defun shipmate-erc-disable ()
  "Disable Shipmate support in ERC."
  (setq erc-button-alist
        (cl-delete-if (lambda (e) (eq #'shipmate-browse-url (elt e 3))) erc-button-alist)))

(provide 'shipmate-erc)
;;; shipmate-erc.el ends here
