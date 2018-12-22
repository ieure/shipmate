;;; shipmate-org.el --- Track packages from org-mode  -*- lexical-binding: t; -*-

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

;; Support for shipmate links in Org files.
;;
;; Links can be in the format:
;;
;; shipmate:TRACKING-NUMBER
;;
;; This will match TRACKING-NUMBER against SHIPMATE-SHIPPERS.
;;
;; Alternately, you can specify the name of a symbol:
;;
;; shipmate:SHIPPER-SYMBOL/TRACKING-NUMBER
;;
;; This will force the link to use SHIPPER-SYMBOL from
;; SHIPMATE-SHIPPERS.

;;; Code:

(require 'shipmate)
(require 'org)

(if (fboundp 'org-link-set-parameters)
    (org-link-set-parameters "shipmate"
                             :follow #'shipmate-org-open
                             :export #'shipmate-org-export)
  ;; For older Org mode
  (org-add-link-type "shipmate"
                     #'shipmate-org-open
                     #'shipmate-org-export))

(defun shipmate-org--shipper (link-target)
  "Detect or extract shipper from LINK-TARGET.

   LINK-TARGET is in the form:

     TRACKING-NUMBER
     or
     SHIPPER/TRACKING-NUMBER

     Returns list of: (tracking-number shipper-symbol)."
  (save-match-data
    (pcase (split-string link-target "/" t "\\s-+")
      (`(,tracking-number)
       (list tracking-number (shipmate--detect tracking-number)))

      (`(,shipper ,tracking-number) (list tracking-number (intern shipper))))))

(defun shipmate-org--url (link-target)
  "Return a URL for LINK-TARGET."
  (apply #'shipmate-tracking-url (shipmate-org--shipper link-target)))

(defun shipmate-org-open (link-target)
  "Open URL for LINK-TARGET."
  (if-let ((url (shipmate-org--url link-target)))
      (browse-url url)
    (error "Link `%s' is malformed" link-target)))

(defun shipmate-org-export (path desc format)
  "Handle Org export of Shipmate links.

  PATH is the link path.
  DESC is the link description (if any).
  FORMAT is the export format."
  (cl-destructuring-bind (tracking shipper) (shipmate-org--shipper path)
    (let ((url (shipmate-tracking-url tracking shipper))
          (desc (or desc
                    (format "%s shipment %s" shipper tracking))))

      (pcase (list format url)
        (`(html nil) (prog1 desc
                       (warn "Link `%s' is malformed" path)))
        (`(html ,url)
         (format "<a href=\"%s\">%s</a>" url desc))
        (`(ascii _) desc)
        (`(_ url) url)
        (_ desc)))))

(provide 'shipmate-org)
;;; shipmate-org.el ends here
