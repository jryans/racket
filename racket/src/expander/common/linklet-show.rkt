#lang racket/base

(provide installed-linklet-show-enabled
         install-linklet-show-enabled!)

(define (installed-linklet-show-enabled) #f)
(define (install-linklet-show-enabled! lse)
  (set! installed-linklet-show-enabled lse))
