;;; -*- Mode: Lisp; Syntax: ANSI-Common-Lisp; Package: ACL-CLIM; Base: 10; Lowercase: Yes -*-

#|****************************************************************************
*                                                                            *
*                                                                            *
*  This file implements the CLIM Pixmap protocol.                            *
*                                                                            *
*                                                                            *
****************************************************************************|#


(in-package :acl-clim)

(defmethod medium-copy-area ((from-medium acl-window-medium) from-x from-y
			     width height
			     (to-medium acl-window-medium) to-x to-y
			     &optional function)
  (unless (eq from-medium to-medium)
    (cerror "Continue" "Can't copy areas."))
  (let ((window (medium-drawable from-medium)))
    (with-dc (window dc)
      (when (select-acl-dc from-medium window dc)
        (let ((transform (sheet-device-transformation
                           (medium-sheet from-medium))))
        (convert-to-device-coordinates transform from-x from-y to-x to-y)
        (convert-to-device-distances transform width height)
        (let ((rleft (min from-x to-x))
	      (rtop (min from-y to-y))
	      (rright (+ (max from-x to-x) width))
	      (rbottom (+ (max from-y to-y) height)))
          (let ((scrollrect (ct::callocate win::rect
                              ; win::left rleft 
                              ; win::top rtop 
                              ; win::right rright
						      ; win::bottom rbottom
                             ))
                (cliprect (ct::callocate win::rect 
                              ; win::left rleft
                              ; win::top rtop 
						      ; win::right rright
						      ; win::bottom rbottom
                             )))
            (setf (ct::cref win::rect scrollrect win::left) rleft)
            (setf (ct::cref win::rect cliprect win::left) rleft)
            (setf (ct::cref win::rect scrollrect win::top) rtop)
            (setf (ct::cref win::rect cliprect win::top) rtop)
            (setf (ct::cref win::rect scrollrect win::right) rright)
            (setf (ct::cref win::rect cliprect win::right) rright)
            (setf (ct::cref win::rect scrollrect win::bottom) rbottom)
            (setf (ct::cref win::rect cliprect win::bottom) rbottom)
            (win::scrollDc dc (- to-x from-x) (- to-y from-y)
		          scrollrect cliprect (ct::null-handle win::hrgn)
			  #+aclpc ct::null #-aclpc 0)
		      )))))))

;; changed bop->winop to return the val let variable rather than the
;; winop let variable. I believe you can take out the winop stuff from
;; the function. (sdj 9/27/96)

(defun bop->winop (bop)
  (let ((val
         (cond
           ((eq bop boole-1)     #xcc0020) ; srccopy
	   ((eq bop boole-2)     #xaa0029) ;
	   ((eq bop boole-clr)   #xff0062) ; whiteness
	   ((eq bop boole-set)   #x42)	   ; blackness
	   ((eq bop boole-c1)    #x330008) ; notsrccopy
	   ((eq bop boole-c2)    #x550009) ; dstinvert
	   ((eq bop boole-and)   #x8800c6) ; srcand
	   ((eq bop boole-ior)   #xee0086) ; srcpaint
	   ((eq bop boole-xor)   #x660046) ; srcinvert
	   ((eq bop boole-eqv)   #x990066) ;
	   ((eq bop boole-nand)  #x7700e6) ; 
	   ((eq bop boole-nor)   #x1100a6) ; notsrcerase
	   ((eq bop boole-andc1) #x220326) ;
	   ((eq bop boole-andc2) #x440328) ; srcerase
	   ((eq bop boole-orc1)  #xbb0226) ; mergepaint 
	   ((eq bop boole-orc2)  #xdd0228) ;
	   (t win::srccopy)
	   ))
        (winop (ct::ccallocate :long)))
     #+aclpcx (ct::%set-long winop 4 0 val)
     #+aclntx (setf (cg::word-vector-long-ref *win-result* 0) val)
     #+ignore
     winop
     val))

#+ignore ; moved to acl-dc
(defclass acl-pixmap (pixmap)
    ((bitmap :initarg :bitmap)
     (for-medium :initarg :for-medium)
     (cdc :initarg :cdc :reader pixmap-cdc)
     (width :initarg :width :reader pixmap-width)
     (height :initarg :height :reader pixmap-height)
     (original-bitmap :initarg :original-bitmap)
))

;;; consider caching instance in port
(defmethod port-allocate-pixmap ((port acl-port) medium width height)
  (fix-coordinates width height)
  (let ((bitmap nil)
	(obitmap nil)
        (cdc nil)
	(window (medium-drawable medium)))
    (with-dc (window dc)
      (setq cdc (win::createCompatibleDC dc))
      (setq bitmap (win::createCompatibleBitmap dc width height))
      (setf obitmap (win::selectObject cdc bitmap)))
    (make-instance 'acl-pixmap 
      :bitmap bitmap
      :for-medium medium
      :width width
      :height height
      :cdc cdc
      :original-bitmap obitmap    
      )))

     
(defmethod port-deallocate-pixmap ((port acl-port) (pixmap acl-pixmap))
  (with-slots (bitmap cdc original-bitmap) pixmap
    (when bitmap
      (win::deleteObject bitmap)
      (setq bitmap nil))
    (when cdc
      (win::selectObject cdc original-bitmap)
      (win::deleteDC cdc)
      (setq bitmap nil cdc nil))))

(defmethod port ((pixmap acl-pixmap))
  *acl-port* ;(port (slot-value pixmap 'for-medium))
  )

(defclass acl-pixmap-medium (acl-medium basic-pixmap-medium)
  ((drawable :initform nil :reader medium-drawable)))

(defmethod make-pixmap-medium ((port acl-port) sheet &key width height)
  (let* ((pixmap (with-sheet-medium (medium sheet)
		   (port-allocate-pixmap port medium width height)))
	 (medium (make-instance 'acl-pixmap-medium
		   :port port
		   :sheet sheet
		   :pixmap pixmap)))
    (setf (slot-value pixmap 'for-medium) medium)
    (setf (slot-value medium 'drawable) pixmap)
    medium))

(defmethod medium-copy-area 
	   ((from-medium acl-medium) from-x from-y width height
	    (to-medium acl-pixmap-medium) to-x to-y &optional (alu boole-1))
  (let ((transform (sheet-device-transformation (medium-sheet from-medium)))
        (window (medium-drawable from-medium))
	(cdc (pixmap-cdc (medium-drawable to-medium))))
    (convert-to-device-coordinates transform from-x from-y)
    (convert-to-device-distances transform width height)
    (with-dc (window dc)
      (when (select-acl-dc from-medium window dc)
	(win::bitblt cdc to-x to-y width height dc from-x from-y 
		    (bop->winop alu))))))

(defmethod medium-copy-area 
	   ((from-medium acl-pixmap-medium) from-x from-y width height
	    (to-medium acl-medium) to-x to-y &optional (alu boole-1))
  (let ((transform (sheet-device-transformation (medium-sheet to-medium)))
	(window (medium-drawable to-medium))
	(cdc (pixmap-cdc (medium-drawable from-medium))))
    (convert-to-device-coordinates transform to-x to-y)
    (with-dc (window dc)
      (when (select-acl-dc to-medium window dc)
        (win::bitblt dc to-x to-y width height cdc from-x from-y 
	            (bop->winop alu))))))

(defmethod medium-copy-area 
	   ((from-medium acl-medium) from-x from-y width height
	    (pixmap acl-pixmap) to-x to-y &optional (alu boole-1))
  (let ((transform (sheet-device-transformation (medium-sheet from-medium)))
	(window (medium-drawable from-medium))
	(cdc (pixmap-cdc pixmap)))
    (convert-to-device-coordinates transform from-x from-y)
    (convert-to-device-distances transform width height)
    (with-dc (window dc)
      (when (select-acl-dc from-medium window dc)
	(win::bitblt cdc to-x to-y width height dc from-x from-y 
		    (bop->winop alu))))))

(defmethod medium-copy-area 
	   ((pixmap acl-pixmap) from-x from-y width height
	    (to-medium acl-medium) to-x to-y &optional (alu boole-1))
  (let ((transform (sheet-device-transformation (medium-sheet to-medium)))
	(window (medium-drawable to-medium))
	(cdc (pixmap-cdc pixmap)))
    (convert-to-device-coordinates transform to-x to-y)
    (with-dc (window dc)
      (when (select-acl-dc to-medium window dc)
        (win::bitblt dc to-x to-y width height cdc from-x from-y 
	            (bop->winop alu))))))

(defmethod medium-draw-pixmap* ((medium acl-medium) pixmap x y
				function)
  (let* ((w (pixmap-width pixmap))
	 (h (pixmap-height pixmap)))
    (copy-from-pixmap pixmap 0 0 w h medium x y function)))




