#lang racket/base
;; A parameter, rebound with `parameterize`.
(require racket/match data/gvector)

(define pool (make-parameter #f))

(define (node n) (gvector-add! (pool) n) (sub1 (gvector-count (pool))))
(define (lit n) (node `(lit ,n)))
(define (add l r) (node `(add ,l ,r)))
(define (mul l r) (node `(mul ,l ,r)))

(define (ev e)
  (match (gvector-ref (pool) e)
    [`(lit ,n) n]
    [`(add ,l ,r) (+ (ev l) (ev r))]
    [`(mul ,l ,r) (* (ev l) (ev r))]))

(parameterize ([pool (make-gvector)])
  (define e (mul (add (lit 1) (lit 2)) (add (lit 3) (lit 4))))
  (displayln (ev e))
  (parameterize ([pool (make-gvector)])
    (displayln (ev (add (lit 4) (lit 4)))))
  (displayln (ev e)))
