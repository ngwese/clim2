;;; -*- Mode: Lisp; Syntax: ANSI-Common-Lisp; Package: CL-USER; Base: 10; Lowercase: Yes -*-

;; $fiHeader: sysdcl.lisp,v 1.49 1995/11/08 06:13:01 georgej Exp $

(in-package :cl-user)

;; this defines a number of symbols and functions allowing the
;; successful compilation of CLIM in a non-ICS lisp (cim 2/26/96)
#+ignore (require :ics)

(let ((*enable-package-locked-errors* nil))
  (export '(excl::codeset-0 excl::codeset-1 excl::codeset-2 excl::codeset-3
	    excl::string-to-euc excl::euc-to-string)
	  (find-package :excl))
  (export '(ff::euc-to-char* ff::char*-to-euc) (find-package :ff))
  (export 'excl::ics-target-case (find-package :excl)))

(let ((*enable-package-locked-errors* nil))
  (defmacro excl::ics-target-case (&rest cases)
    `(comp::ics-target-ecase
      ,@cases
      ,@(unless (assoc :+ics cases)
	  '((:+ics nil)))
      ,@(unless (assoc :-ics cases)
	  '((:-ics nil))))))

"Copyright (c) 1990, 1991, 1992 Symbolics, Inc.  All rights reserved."

(eval-when (compile load eval)

;;; Tell the world that we're here
;;;--- These need to be in the CLIM.fasl also.
;;;--- Currently they're in EXCL-VERIFICATION but that does not seem the best place.
(pushnew :clim *features*)
(pushnew :clim-2 *features*)
(pushnew :clim-2.1 *features*)
(pushnew :silica *features*)

)	;eval-when



;;; CLIM is implemented using the "Gray Stream Proposal" (STREAM-DEFINITION-BY-USER)
;;; a proposal to X3J13 in March, 1989 by David Gray of Texas Instruments.  In that
;;; proposal, stream objects are built on certain CLOS classes, and stream functions
;;; (e.g., WRITE-CHAR) are non-generic interfaces to generic functions (e.g.,
;;; STREAM-WRITE-CHAR).  These "trampoline" functions are required because their
;;; STREAM argument is often optional, which means it cannot be used to dispatch to
;;; different methods.

;;; Various Lisp vendors have their own stream implementations, some of which are
;;; identical to the Gray proposal, some of which implement just the trampoline
;;; functions and not the classes, etc.  If the Lisp vendor has not implemented the
;;; classes, we will shadow those class names (and the predicate functions for them)
;;; in the CLIM-LISP package, and define the classes ourselves.  If the vendor has
;;; not implemented the trampoline functions, we will shadow their names, and write
;;; our own trampolines which will call our generic function, and then write default
;;; methods which will invoke the COMMON-LISP package equivalents.

(eval-when (compile load eval)

(pushnew :clim-uses-lisp-stream-classes *features*)
(pushnew :clim-uses-lisp-stream-functions *features*)

;;; CLIM-ANSI-Conditions means this lisp truly supports the ANSI CL condition system
;;; CLIM-Conditions      means that it has a macro called DEFINE-CONDITION but that it works
;;;                      like Allegro 3.1.13 or Lucid.
(pushnew :CLIM-ANSI-Conditions *features*)

(pushnew :allegro-v4.0-constructors *features*)

)					;eval-when

;; We extend defsystem to have a new module class compile-always
;; which always recompiles the module even if not required. This
;; allows us to put defpackage forms within ics-target-case so that at
;; load time only the one case takes effect while at compile time both
;; forms are processed. (cim 2/28/96)

(defclass compile-always (defsystem:lisp-module)
  ())

(defvar *compiled-modules* nil)

(defmethod defsystem:product-newer-than-source ((module compile-always))
  (member module *compiled-modules*))

(defmethod defsystem:compile-module :after ((module compile-always) &key)
  (pushnew module *compiled-modules*))

;; This defsystem module class only compiles the module if it's not
;; ever been compiled - this is used to deal with files that can only
;; be validly compiled with an ics image - see japanese-input-editor
;; (cim 2/28/96)

(defclass compile-once (defsystem:lisp-module)
  ())

(defmethod defsystem:product-newer-than-source ((module compile-once))
  (probe-file (defsystem:product-pathname module)))




(defsystem clim-utils
    (:default-pathname "clim2:;utils;")
  ;; These files establish a uniform Lisp environment
  (:serial
   "excl-verification"
   ("packages" (:module-class compile-always))
   "defun-utilities" ;; extract-declarations and friends
   #+(or Genera (not ANSI-90)) "defun"
   "reader"
   "clos-patches"
   "clos"
   #+CLIM-conditions "condpat" ;get the define-condition macro

   ;; General Lisp extensions
   "utilities"
   "lisp-utilities"
   "processes"
   "queue"
   ("timers" (:load-before-compile "queue" "processes"))
   "protocols"

   ;; Establish a uniform stream model
   "clim-streams"
   #-clim-uses-lisp-stream-classes "cl-stream-classes"
   #+Minima "minima-stream-classes"
   #+(and (not clim-uses-lisp-stream-functions) (not Lucid)) "cl-stream-functions"
   #+Lucid "lucid-stream-functions"
   #+Genera "genera-streams"
   #+Allegro "excl-streams"
   #+CCL-2 "ccl-streams"

   ;; Basic utilities for Silica and CLIM
   "clim-macros"
   ("transformations" #+CLIM-conditions (:load-before-compile "condpat"))
   "regions"
   "region-arithmetic"
   "extended-regions"
   "base-designs"
   "designs"
   ))

(defsystem clim-silica
    (:default-pathname "clim2:;silica;")
  (:serial
   clim-utils

   ;; "Silica"
   "macros"
   "classes"
   "text-style"
   "sheet"
   "mirror"
   "event"
   "port"
   "medium"
   "framem"
   "graphics"
   "pixmaps"
   "std-sheet"

   ;; "Windshield", aka "DashBoard"
   ;; First the layout gadgets
   "layout"
   "db-layout"
   "db-box"
   "db-table"

   ;; Then the "physical" gadgets
   "gadgets"
   "db-border"
   "db-scroll"
   ))

(defsystem clim-standalone
    (:default-pathname "clim2:;clim;")
  (:serial
   clim-utils
   clim-silica

   ;; Basic tools
   "gestures"
   "defprotocol"
   "stream-defprotocols"
   "defresource"
   "temp-strings"
   #+CCL-2 "coral-defs"
   "clim-defs"

   ;; Definitions and protocols
   "stream-class-defs"
   "interactive-defs"
   "cursor"
   "view-defs"
   "input-defs"
   "input-protocol"
   "output-protocol"

   ;; Output recording
   ("recording-defs" (:load-before-compile "clim-defs"))
   "formatted-output-defs"
   ("recording-protocol" (:load-before-compile "recording-defs"))
   ("text-recording" (:load-before-compile "recording-protocol"))
   ("graphics-recording" (:load-before-compile "recording-protocol"))
   ("design-recording" (:load-before-compile "graphics-recording"))

   ;; Input editing
   ("interactive-protocol" (:load-before-compile "clim-defs"))
   "input-editor-commands"

   ;; only compile with non-ICS if no fasl file exist
   ;; always compile with ICS in case it was previously compiled by
   ;; non-ICS
   ("japanese-input-editor" (:module-class #-ics compile-once
					   #+ics compile-always))

   ;; Incremental redisplay
   ("incremental-redisplay" (:load-before-compile "clim-defs" "recording-protocol"))

   ;; Windows
   "coordinate-sorted-set"
   "r-tree"
   "window-stream"
   "pixmap-streams"

   ;; Presentation types
   ("ptypes1" (:load-before-compile "clim-defs"))
   ("completer" (:load-before-compile "ptypes1"))
   ("presentations" (:load-before-compile "ptypes1"))
   ("translators" (:load-before-compile "presentations"))
   ("histories" (:load-before-compile "presentations"))
   ("ptypes2" (:load-before-compile "translators"))
   ("standard-types" (:load-before-compile "ptypes2"))
   #+Allegro ("excl-presentations" (:load-before-compile "presentations"))

   ;; Formatted output
   ("table-formatting" (:load-before-compile "clim-defs" "incremental-redisplay"))
   ("graph-formatting" (:load-before-compile "clim-defs" "incremental-redisplay"))
   ("surround-output" (:load-before-compile "clim-defs" "incremental-redisplay"))
   ("text-formatting" (:load-before-compile "clim-defs" "incremental-redisplay"))

   ;; Pointer tracking
   "tracking-pointer"
   ("dragging-output" (:load-before-compile "tracking-pointer"))

   ;; Gadgets
   "db-stream"
   "gadget-output"

   ;; Application building substrate
   ("accept" (:load-before-compile "clim-defs" "ptypes2"))
   ("present" (:load-before-compile "clim-defs" "ptypes2"))
   ("command" (:load-before-compile "clim-defs" "ptypes2"))
   ("command-processor" (:load-before-compile "clim-defs" "command"))
   ("basic-translators" (:load-before-compile "ptypes2" "command"))
   ("frames" (:load-before-compile "clim-defs" "command-processor"))
   ("panes" (:load-before-compile "frames"))
   ("default-frame" (:load-before-compile "frames"))
   ("activities" (:load-before-compile "frames"))
   ("noting-progress" (:load-before-compile "frames"))
   ("menus" (:load-before-compile "defresource" "clim-defs"))
   ("accept-values" (:load-before-compile "clim-defs" "incremental-redisplay" "frames"))
   ("drag-and-drop" (:load-before-compile "frames"))
   "item-list-manager"

   ;; Bootstrap everything
   ("stream-trampolines" (:load-before-compile "defprotocol" "stream-defprotocols"))
   #+lucid "lucid-after"
   #+(or Genera Cloe-Runtime) "prefill"
   ))

(defsystem clim-homegrown
    (:default-pathname "clim2:;homegrown;")
  (:serial
   clim-standalone
   clim-silica
   "scroll-pane"
   "db-button"
   "db-label"
   "db-slider"
   "db-menu"
   ("db-list" (:load-before-compile "db-menu"))
   "db-text"
   "last"))


#+Allegro
(defsystem xlib
    (:default-pathname "clim2:;xlib;")
  (:serial
   clim-standalone
   "pkg"
   "ffi"
   ("load-xlib")
   ("xlib-defs" (:load-before-compile "ffi"))
   ("xlib-funs" (:load-before-compile "ffi"))
   ("x11-keysyms" (:load-before-compile "ffi"))
   ("last" (:load-before-compile "load-xlib" "xlib-funs"))
   ))

#+Allegro
(defsystem wnn
    (:default-pathname "clim2:;wnn;")
  (:serial
   clim-standalone
   "pkg"
   "load-wnn"
   "jl-defs"
   "jl-funs"
   "jserver"))

#+Allegro
(macrolet ((define-xt-system (name file &rest modules)
	       `(defsystem ,name
		    (:default-pathname "clim2:;tk;")
		  (:serial
		   xlib
		   (,file)
		   ("pkg")
		   ("macros")
		   ("xt-defs")
		   ("xt-funs")
		   ("foreign-obj")
		   ;; Xlib stuff
		   ("xlib")
		   ("font")
		   ("gcontext")
		   ("graphics")

		   ;; Toolkit stuff
		   ("meta-tk")
		   ("make-classes")
		   ("foreign")
		   ("widget")
		   ("resources")
		   ("event")
		   ("callbacks")
		   ("xt-classes")
		   ("xt-init")
		   ,@modules))))

(define-xt-system xm-tk "load-xm"
  ("xm-defs")
  ("xm-funs")
  ("xm-classes")
  ("xm-callbacks")
  ("xm-init")
  ("xm-widgets")
  ("xm-font-list")
  ("xm-protocols")
  ("convenience")
  ("make-widget"))

(define-xt-system ol-tk "load-ol"
  ("ol-defs")
  ("ol-funs")
  ("ol-classes")
  ("ol-init")
  ("ol-widgets")
  ("ol-callbacks")
  ("make-widget")))

#+Allegro
(defsystem motif-clim
    (:default-pathname "clim2:;tk-silica;")
  (:serial
   clim-standalone
   xm-tk
   ("pkg")
   ("xt-silica")
   ("xt-stipples")
   ("xm-silica")
   ("xt-graphics")
   ("image")
   ("xt-frames")
   ("xm-frames")
   ("xm-dialogs")
   ("xt-gadgets")
   ("xm-gadgets")
   ("xt-pixmaps")
   ("gc-cursor")
   ("last")))

#+Allegro
(defsystem openlook-clim
    (:default-pathname "clim2:;tk-silica;")
  (:serial
   clim-standalone
   ol-tk

   ("pkg")
   ("xt-silica")
   ("xt-stipples")
   ("ol-silica")
   ("xt-graphics")
   ("image")
   ("xt-frames")
   ("ol-frames")
   ("xt-gadgets")
   ("ol-gadgets")
   ("xt-pixmaps")
   ("gc-cursor")
   ("last")))


#+CCL-2
(clim-defsys:defsystem ccl-clim
    (:default-pathname #+Genera "SYS:CLIM;REL-2;CCL;"
		       #-Genera (frob-pathname "ccl")
     :default-binary-pathname #+Genera "SYS:CLIM;REL-2;CCL;"
			      #-Genera (frob-pathname "ccl")
     :needed-systems (clim-standalone)
     :load-before-compile (clim-standalone))
  ("pkgdcl")
  ("ccl-port")
  ("ccl-mirror")
  ("ccl-medium")
  ("ccl-frames")
  ("ccl-gadgets")
  ("ccl-menus"))


#+Genera (progn

(clim-defsys:import-into-sct 'clim-utils :subsystem t
  :pretty-name "CLIM Utilities"
  :default-pathname "SYS:CLIM;REL-2;UTILS;")

(clim-defsys:import-into-sct 'clim-silica :subsystem t
  :pretty-name "CLIM Silica"
  :default-pathname "SYS:CLIM;REL-2;SILICA;")

(clim-defsys:import-into-sct 'clim-standalone :subsystem t
  :pretty-name "CLIM Standalone"
  :default-pathname "SYS:CLIM;REL-2;CLIM;")

(sct:defsystem clim
    (:pretty-name "CLIM"
     :default-pathname "SYS:CLIM;REL-2;"
     :journal-directory "SYS:CLIM;REL-2;PATCH;"
     :default-module-type :system
     :bug-reports "Bug-CLIM"
     :patches-reviewed "Bug-CLIM-Doc"
     :source-category :optional)
  (:module defsystem "sys:clim;rel-2;sys;defsystem"
	   (:type :lisp) (:root-module nil))
  (:serial "clim-utils"
	   "clim-silica"
	   "clim-standalone"))

#+++ignore
(progn
(clim-defsys:import-into-sct 'motif-clim :subsystem t
  :pretty-name "Motif CLIM"
  :default-pathname "SYS:CLIM;REL-2;TK-SILICA;")

(clim-defsys:import-into-sct 'openlook-clim :subsystem t
  :pretty-name "OpenLook CLIM"
  :default-pathname "SYS:CLIM;REL-2;TK-SILICA;")

(sct:defsystem clim-tags-table
    (:pretty-name "CLIM Tags Table"
     :default-pathname "SYS:CLIM;REL-2;CLIM;"
     :maintain-journals nil
     :default-module-type :system)
  (:serial "clim"
	   "clim-compatibility"
	   "genera-clim"
	   "clx-clim"
	   "postscript-clim"
	   "cloe-clim"
	   "motif-clim"
	   "openlook-clim"
	   "clim-demo"))
)	;#+++ignore

)	;#+Genera

#+Minima-Developer (progn

(clim-defsys:import-into-sct 'clim-utils :subsystem t
  :sct-name :minima-clim-utils :pretty-name "Minima CLIM Utilities"
  :default-pathname "SYS:CLIM;REL-2;UTILS;")

(clim-defsys:import-into-sct 'clim-silica :subsystem t
  :sct-name :minima-clim-silica :pretty-name "Minima CLIM Silica"
  :default-pathname "SYS:CLIM;REL-2;SILICA;")

(clim-defsys:import-into-sct 'clim-standalone :subsystem t
  :sct-name :minima-clim-standalone :pretty-name "Minima CLIM Standalone"
  :default-pathname "SYS:CLIM;REL-2;CLIM;")

(zl:::sct:defsystem minima-clim
    (:pretty-name "Minima CLIM"
     :default-pathname "SYS:CLIM;REL-2;"
     :journal-directory "SYS:CLIM;REL-2;PATCH;"
     :maintain-journals nil
     :default-module-type :system
     :patches-reviewed "Bug-CLIM-Doc"
     :source-category :optional)
  (:module defsystem "sys:clim;rel-2;sys;defsystem"
	   (:type :minima-lisp) (:root-module nil))
  (:serial "minima-clim-utils"
	   "minima-clim-silica"
	   "minima-clim-standalone"))

)	;#+Minima-Developer


#||

;; You get the general idea...
(defun clone-CLIM ()
  (sct:copy-system 'clim
    :copy-sources t :copy-binaries nil
    :destination '((#p"S:>sys>clim>sys>*.*.*" #p"S:>rel-8-0>sys>clim>sys>*.*.*")
		   (#p"S:>sys>clim>utils>*.*.*" #p"S:>rel-8-0>sys>clim>utils>*.*.*")
		   (#p"S:>sys>clim>silica>*.*.*" #p"S:>rel-8-0>sys>clim>silica>*.*.*")
		   (#p"S:>sys>clim>clim>*.*.*" #p"S:>rel-8-0>sys>clim>clim>*.*.*")))
  (sct:copy-system 'genera-clim
    :copy-sources t :copy-binaries nil
    :destination '((#p"S:>sys>clim>genera>*.*.*" #p"S:>rel-8-0>sys>clim>genera>*.*.*")))
  (sct:copy-system 'clx-clim
    :copy-sources t :copy-binaries nil
    :destination '((#p"S:>sys>clim>clx>*.*.*" #p"S:>rel-8-0>sys>clim>clx>*.*.*")))
  (sct:copy-system 'postscript-clim
    :copy-sources t :copy-binaries nil
    :destination '((#p"S:>sys>clim>postscript>*.*.*" #p"S:>rel-8-0>sys>clim>postscript>*.*.*")))
  (sct:copy-system 'clim-demo
    :copy-sources t :copy-binaries nil
    :destination '((#p"S:>sys>clim>demo>*.*.*" #p"S:>rel-8-0>sys>clim>demo>*.*.*"))))

||#

#||
()

(defun compare-system-files (system dir1 dir2)
  (setq dir1 (pathname-directory (cl:translate-logical-pathname (pathname dir1))))
  (setq dir2 (pathname-directory (cl:translate-logical-pathname (pathname dir2))))
  (let ((files (sct:get-all-system-input-files (sct:find-system-named system)
					       :version :newest :include-components nil)))
    (dolist (file files)
      (let* ((file (cl:translate-logical-pathname file))
	     (directory (nthcdr (mismatch dir1 (pathname-directory file) :from-end t)
				(pathname-directory file)))
	     (file1 (make-pathname :directory (append dir1 directory)
				   :version :newest
				   :defaults file))
	     (file2 (make-pathname :directory (append dir2 directory)
				   :version :newest
				   :defaults file)))
	(when (y-or-n-p "Do comparison for ~A.~A ? "
	        (pathname-name file) (pathname-type file))
	  (srccom:source-compare file1 file2))
	(when (y-or-n-p "Copy ~A.~A ? "
	        (pathname-name file) (pathname-type file))
	  (scl:copy-file file1 (make-pathname :version :wild :defaults file2)))))))

(compare-system-files 'clim "sys:clim;rel-2;" "sys:clim;rel-2;shared;")

||#
