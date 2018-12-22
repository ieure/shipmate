;;; shipmate.el --- Track shipments        -*- lexical-binding: t; -*-

;; Copyright (C) 2018  Ian Eure

;; Author: Ian Eure <ian@retrospec.tv>
;; URL: https://github.com/ieure/shipmate
;; Keywords: hypermedia

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

;; Shipmate is a toolkit for dealing with tracking numbers.

;;; Code:

(defgroup shipmate nil
  "Tools for tracking shipments with Emacs"
  :prefix "shipmate-"
  :group 'applications)

(defconst shipmate--usps-regexp
    (rx
     word-boundary
     (or
      ;; USPS Tracking, Priority or Certified Mail, COD, Priority Mail
      ;; Express, Registered Mail, or Signature Confirmation Mail
      (seq
       ;; "92xx" "93xx" etc
       "9" (or "2" "3" "4") (repeat 2 digit)
       ;; Spaces are printed on the labels for legibility, but
       ;; generally not on electronic tracking numbers.  But we should
       ;; accept either.
       (zero-or-one space)
       ;; 4 sequences of 4 digits
       (repeat 4 (seq
                  (repeat 4 digit)
                  (zero-or-one space)))
       ;; Finish with two digits
       (repeat 2 digit))

      ;; Global Express Guaranteed
      (seq
       "82"
       (zero-or-one space)
       (repeat 2 (seq
                  (repeat 3 digit)
                  (zero-or-one space)))
       (repeat 2 digit))

      ;; International mail
      (seq
       (or "EC" "EA" "CP")
       (zero-or-one space)
       (repeat 3 (seq
                  (repeat 3 digit)
                  (zero-or-one space)))
       (repeat 2 digit)))
     word-boundary)
    "Regexp for USPS tracking numbers.")

(defconst shipmate--fedex-regexp
    (rx
     word-boundary
     (** 12 14 digit)
     word-boundary)
    "Regexp for FedEx tracking numbers.")

(defconst shipmate--ups-regexp
    (rx
     word-boundary
     "1Z"
     (repeat 2 (seq (repeat 3 alnum) (zero-or-one space)))
     (repeat 2 alnum) (zero-or-one space)
     (repeat 4 alnum) (zero-or-one space)
     (repeat 3 alnum) (zero-or-one space)
     (repeat 1 alnum) (zero-or-one space)
     word-boundary)
    "Regexp for UPS tracking numbers.")

(defconst shipmate--japan-post-regexp
  (rx
   word-boundary
   (repeat 2 alpha)
   (repeat 9 digit)
   "JP"
   word-boundary)
  "Regexp for Japan Post tracking numbers.")

(defcustom shipmate-shippers
  '((ups . (:regexp shipmate--ups-regexp
                    :url "https://wwwapps.ups.com/WebTracking/track?track=yes&trackNums=%s"))
    (usps . (:regexp shipmate--usps-regexp
                     :url "https://tools.usps.com/go/TrackConfirmAction?tLabels=%s"))
    (fedex . (:regexp shipmate--fedex-regexp
                      :url "https://www.fedex.com/apps/fedextrack/?tracknumbers=%s"))
    (japan-post . (:regexp shipmate--japan-post-regexp
                            :url "https://trackings.post.japanpost.jp/services/srv/search/direct?locale=en&reqCodeNo1=%s")))

  "Definitions for recognized shippers.

   In :url, the \"%s\" will be replaced with the matched tracking number."
  :type '(alist
          :key-type symbol
          :value-type (plist
                       :options ((:regexp (choice symbol regexp))
                                 (:url string)))))

(defun shipmate--detect* (tracking-number? shippers)
  "Find a shipper matching TRACKING-NUMBER? in SHIPPERS.

   Returns shipper symbol when a match is found, else NIL."

  (let ((set-expr (plist-get (cdar shippers) :regexp)))
    (if (string-match (if (symbolp set-expr) (symbol-value set-expr) set-expr)
                      tracking-number?)
        (caar shippers)
      (shipmate--detect* tracking-number? (cdr shippers)))))

(defun shipmate--detect (tracking-number?)
  "Return the detected shipper for TRACKING-NUMBER?

   Returns the car of the matching entry from SHIPMATE-SHIPPERS, or
   NIL if no match."
  (shipmate--detect* tracking-number? shipmate-shippers))

(defun shipmate--tracking-url (tracking-number &optional shipper)
  "Return the URL to track shipment TRACKING-NUMBER?

   When SHIPPER is set to a symbol in SHIPMATE-SHIPPERS, open that
   shipper's tracking.  Otherwise, try to detect the shipper.

   Returns NIL if TRACKING-NUMBER? doesn't match any expr in
   SHIPPERS."
  (if-let ((shipper (or shipper (shipmate-detect tracking-number))))
      (format (plist-get (cdr (assoc shipper shipmate-shippers)) :url)
              tracking-number)))

(defun shipmate-browse-url (tracking-number &optional shipper)
  "Open tracking for TRACKING-NUMBER.

   When SHIPPER is set to a symbol in SHIPMATE-SHIPPERS, open that
   shipper's tracking.  Otherwise, try to detect the shipper."
  (if-let ((url (shipmate--tracking-url tracking-number shipper)))
      (browse-url url)))

(provide 'shipmate)
;;; shipmate.el ends here
