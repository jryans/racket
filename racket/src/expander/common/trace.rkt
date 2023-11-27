#lang racket/base

(require '#%linklet)

(provide trace-printf
         guarded-trace-printf)

;; Ideally we would just use the standard Racket logging facility.
;;
;; Unfortunately we are faced with a somewhat unusual requirement to
;; produce a consistently ordered event trace that weaves together
;; messages from several different layers:
;;
;;   - `cs/linklet.sls`
;;   - `cs/main.sps`
;;   - `expander/**`
;;   - `ChezScheme/s/**`
;;
;; To achieve this, we reach for the lowest layer (Chez) and expose
;; its functions as needed in the other layers.

;; This uses the same output path as Chez's nanopass tracer,
;; which helps ensure trace logs from both this layer and Chez
;; appear in the order they occurred.
(define (trace-printf-core fmt . args)
  ;; Schemify appears to handle this in a sane way:
  ;;   - When targeting CS, only the CS branch is kept
  ;;   - What targeting BC, all branches are kept
  ;; TODO: Can this be simplified using `#%` primitive prefix...?
  (case (system-type 'vm)
    [(chez-scheme)
     ;; In some contexts (like `module-path-index-resolve`),
     ;; `call-with-system-wind` appears to be `#f` until after
     ;; `namespace-init!` completes
     (define call-with-system-wind (primitive-lookup 'call-with-system-wind))
     (cond
      [call-with-system-wind
       (define apply (primitive-lookup 'apply))
       (define fprintf (primitive-lookup 'fprintf))
       (define current-error-port (primitive-lookup 'current-error-port))
       (call-with-system-wind
         (lambda ()
           (apply fprintf (current-error-port) fmt args)))]
      [else
       (apply eprintf fmt args)])]
    [else
     (apply eprintf fmt args)]))

(define (trace-printf fmt . args)
  (when (getenv "PLT_TRACE_TIMES")
    (trace-printf-core "[~a] " (current-inexact-monotonic-milliseconds)))
  (apply trace-printf-core fmt args))

;; This is exposed for other parts of CS internals (but not Racket)
;; that may wish to optionally print trace output.
(define (guarded-trace-printf fmt . args)
  (when (getenv "PLT_TRACE")
    (apply trace-printf fmt args)))
