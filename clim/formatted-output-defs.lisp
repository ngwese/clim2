;;; -*- Mode: Lisp; Syntax: ANSI-Common-Lisp; Package: CLIM-INTERNALS; Base: 10; Lowercase: Yes -*-

;; $fiHeader: formatted-output-defs.lisp,v 1.7 92/11/06 18:59:32 cer Exp $

(in-package :clim-internals)

"Copyright (c) 1990, 1991, 1992 Symbolics, Inc.  All rights reserved.
 Portions copyright (c) 1989, 1990 International Lisp Associates."

;;; We want to evaluate the user's :RECORD-TYPE option, right?
(defmacro formatting-table ((&optional stream
			     &rest options
			     &key x-spacing y-spacing
				  multiple-columns multiple-columns-x-spacing	
				  equalize-column-widths
				  record-type (move-cursor t)
			     &allow-other-keys)
			    &body body)
  (declare (ignore x-spacing y-spacing 
		   multiple-columns multiple-columns-x-spacing
		   equalize-column-widths record-type move-cursor))
  #+Genera (declare (zwei:indentation 0 3 1 1))
  (default-output-stream stream formatting-table)
  `(flet ((formatting-table-body (,stream) ,@body))
     (declare (dynamic-extent #'formatting-table-body))
     (invoke-formatting-table ,stream #'formatting-table-body ,@options)))

(defmacro formatting-row ((&optional stream
			   &rest options &key record-type &allow-other-keys)
			  &body body)
  #+Genera (declare (zwei:indentation 0 3 1 1))
  (default-output-stream stream formatting-row)
  (setq options (remove-keywords options '(:record-type)))
  (unless record-type (setq record-type `'standard-row-output-record))
  `(with-new-output-record (,stream ,record-type nil ,@options)
     ,@body))

(defmacro formatting-column ((&optional stream
			      &rest options &key record-type &allow-other-keys)
			     &body body)
  #+Genera (declare (zwei:indentation 0 3 1 1))
  (default-output-stream stream formatting-column)
  (setq options (remove-keywords options '(:record-type)))
  (unless record-type (setq record-type `'standard-column-output-record))
  `(with-new-output-record (,stream ,record-type nil ,@options)
     ,@body))

(defmacro formatting-cell ((&optional stream
			    &rest options
			    &key (align-x ':left) (align-y ':top)
				 min-width min-height record-type
			    &allow-other-keys)
			   &body body)
  (declare (ignore align-x align-y min-width min-height record-type))
  #+Genera (declare (zwei:indentation 0 3 1 1))
  (default-output-stream stream formatting-cell)
  `(flet ((formatting-cell-body (,stream) ,@body))
     (declare (dynamic-extent #'formatting-cell-body))
     (invoke-formatting-cell ,stream #'formatting-cell-body ,@options)))

(defmacro formatting-item-list ((&optional stream
				 &rest options
				 &key record-type
				      x-spacing y-spacing initial-spacing
				      n-columns n-rows
				      max-width max-height
				      stream-width stream-height
				      (row-wise t) (move-cursor t)
				 &allow-other-keys)
				&body body)
  (declare (ignore x-spacing y-spacing initial-spacing
		   record-type n-columns n-rows max-width max-height
		   stream-width stream-height row-wise move-cursor))
  #+Genera (declare (zwei:indentation 0 3 1 1))
  (default-output-stream stream formatting-item-list)
  `(flet ((formatting-item-list-body (,stream) ,@body))
     (declare (dynamic-extent #'formatting-item-list-body))
     (invoke-formatting-item-list ,stream #'formatting-item-list-body ,@options)))


(defmacro surrounding-output-with-border ((&optional stream
					   &rest drawing-options
					   &key (shape ':rectangle) (move-cursor t)
					   &allow-other-keys)
					  &body body)
  #+Genera (declare (zwei:indentation 0 3 1 1))
  (declare (ignore move-cursor))
  (default-output-stream stream surrounding-output-with-border)
  (with-keywords-removed (drawing-options drawing-options '(:shape))
    `(flet ((surrounding-output-with-border-body (,stream) ,@body))
       (declare (dynamic-extent #'surrounding-output-with-border-body))
       (invoke-surrounding-output-with-border
	 ,stream #'surrounding-output-with-border-body ,shape
	 ,@(copy-list drawing-options)))))

(defmacro filling-output ((&optional stream &rest keys
			   &key (fill-width '(80 :character))
				(break-characters '(#\space))
				after-line-break after-line-break-initially)
			  &body body)
  #+Genera (declare (zwei:indentation 0 3 1 1))
  (declare (ignore fill-width break-characters after-line-break after-line-break-initially))
  (default-output-stream stream filling-output)
  `(flet ((filling-output-body (,stream) ,@body))
     (declare (dynamic-extent #'filling-output-body))
     (invoke-filling-output ,stream #'filling-output-body ,@keys)))

(defmacro indenting-output ((stream indentation &key (move-cursor t))
			    &body body)
  #+Genera (declare (zwei:indentation 0 3 1 1))
  (default-output-stream stream indenting-output)
  `(flet ((indenting-output-body (,stream) ,@body))
     (declare (dynamic-extent #'indenting-output-body))
     (invoke-indenting-output ,stream #'indenting-output-body 
			      ,indentation :move-cursor ,move-cursor)))


(defmacro updating-output
	  ((stream &rest args
		   &key (record-type `'standard-updating-output-record)
			(unique-id `'assign-sequential-unique-IDs) (id-test `#'eql)
			(cache-value `'unsupplied-cache-value) (cache-test `#'eql)
			copy-cache-value parent-cache
			output-record fixed-position all-new
		   &allow-other-keys)
	   &body body)
  (declare (ignore fixed-position all-new))
  #+Genera (declare (zwei:indentation 0 3 1 1))
  (default-output-stream stream updating-output)
  `(flet ((updating-output-body (,stream) ,@body))
     (invoke-updating-output ,stream #'updating-output-body
			     ,record-type ,unique-id ,id-test
			     ,cache-value ,cache-test
			     ,copy-cache-value ,parent-cache ,output-record 
			     ,@(remove-keywords args
				 ;; Remove all args that aren't initargs to the record.
				 '(:record-type :id-test :cache-test :copy-cache-value
				   :parent-cache :output-record)))))
