;; -*- mode: common-lisp; package: xm-silica -*-
;;
;;				-[]-
;; 
;; copyright (c) 1985, 1986 Franz Inc, Alameda, CA  All rights reserved.
;; copyright (c) 1986-1991 Franz Inc, Berkeley, CA  All rights reserved.
;;
;; The software, data and information contained herein are proprietary
;; to, and comprise valuable trade secrets of, Franz, Inc.  They are
;; given in confidence by Franz, Inc. pursuant to a written license
;; agreement, and may be stored and used only in accordance with the terms
;; of such license.
;;
;; Restricted Rights Legend
;; ------------------------
;; Use, duplication, and disclosure of the software, data and information
;; contained herein by any agency, department or entity of the U.S.
;; Government are subject to restrictions of Restricted Rights for
;; Commercial Software developed at private expense as specified in FAR
;; 52.227-19 or DOD FAR Supplement 252.227-7013 (c) (1) (ii), as
;; applicable.
;;
;; $fiHeader: xt-pixmaps.lisp,v 1.4 92/03/04 16:20:45 cer Exp Locker: cer $


(in-package :xm-silica)

(defmethod port-allocate-pixmap ((port xt-port) sheet width height)
  (declare (ignore sheet))
  (fix-coordinates width height)
  (let ((root (tk::display-root-window (port-display port))))
    (make-instance 'tk::pixmap
      :drawable root
      :width width
      :height height
      :depth (tk::drawable-depth root))))

(defmethod fetch-medium-drawable ((sheet clim-internals::pixmap-stream) pixmap)
  pixmap)

(defmethod port-copy-from-pixmap ((port xt-port)
				  pixmap pixmap-x pixmap-y width height
				  stream window-x window-y)
  (convert-to-device-coordinates (sheet-native-transformation stream)
    window-x window-y)
  ;; We are in a bad situation if the native-transformation is
  ;; anything other than a scaling transformation
  (with-sheet-medium (medium stream)
    (let* ((drawable (medium-drawable medium))
	   (copy-gc (make-instance 'tk::gcontext :drawable drawable)))
      (tk::copy-area 
       pixmap
       copy-gc pixmap-x pixmap-y width height drawable
       window-x window-y))))
	   
(defmethod port-copy-to-pixmap ((port xt-port)
				stream window-x window-y width height
				pixmap pixmap-x pixmap-y)
  (convert-to-device-coordinates (sheet-native-transformation stream)
    window-x window-y)
  ;; We are in a bad situation if the native-transformation is
  ;; anything other than a scaling transformation
  (with-sheet-medium (medium stream)
    (let* ((drawable (medium-drawable medium))
	   (copy-gc (make-instance 'tk::gcontext :drawable drawable)))
      (tk::copy-area 
	drawable
	copy-gc 
	window-x window-y width height pixmap
	pixmap-x pixmap-y))))

(defmethod pixmap-height ((pixmap tk::pixmap))
  (tk::pixmap-height pixmap))

(defmethod pixmap-width ((pixmap tk::pixmap))
  (tk::pixmap-width pixmap))

(defmethod deallocate-pixmap ((pixmap tk::pixmap))
  (break "implement me"))


