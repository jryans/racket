;; Ideally we would just use the standard Racket logging facility.
;;
;; Unfortunately we are faced with a somewhat unusual requirement to
;; produce a consistently ordered event trace that weaves together
;; messages from several different layers:
;;
;;   - `cs/linklet.sls`
;;   - `expander/**`
;;   - `ChezScheme/s/**`
;;
;; To achieve this, we reach for the lowest layer (Chez) and expose
;; its functions as needed in the other layers.

;; This uses the same output path as Chez's nanopass tracer,
;; which helps ensure trace logs from both this layer and Chez
;; appear in the order they occurred.
(define trace-printf-core
  (lambda (fmt . args)
    (apply #%fprintf (#%current-error-port) fmt args)
    (#%flush-output-port (#%current-error-port))))

(define trace-printf
  (lambda (fmt . args)
    (when (getenv "PLT_TRACE_TIMES")
      (trace-printf-core "[~a] " (current-inexact-monotonic-milliseconds)))
    (apply trace-printf-core fmt args)))

;; This is exposed for other parts of CS internals (but not Racket)
;; that may wish to optionally print trace output.
(define guarded-trace-printf
  (lambda (fmt . args)
    (when (getenv "PLT_TRACE")
      (apply trace-printf fmt args))))
