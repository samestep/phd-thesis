#lang racket/base
;; A parameter, rebound with `parameterize`.
(require racket/match data/gvector)

(struct binary (op lhs rhs))
(struct literal (num))

(define pool (make-parameter #f))

(define (add expr) (gvector-add! (pool) expr) (sub1 (gvector-count (pool))))
(define (get ref) (gvector-ref (pool) ref))

(define (interp ref)
  (match (get ref)
    [(binary op lhs rhs)
     (define l (interp lhs))
     (define r (interp rhs))
     (case op
       [(add) (+ l r)]
       [(sub) (- l r)]
       [(mul) (* l r)]
       [(div) (if (zero? r) 0 (quotient l r))])]
    [(literal num) num]))

(define (lit n) (add (literal n)))
(define (bin op l r) (add (binary op l r)))

(parameterize ([pool (make-gvector)])
  (define e (bin 'div (bin 'mul (bin 'sub (lit 7) (lit 10)) (lit 7)) (lit 2)))
  (displayln (interp e))
  (parameterize ([pool (make-gvector)])
    (displayln (interp (bin 'div (bin 'add (lit 4) (lit 4)) (bin 'sub (lit 4) (lit 4))))))
  (displayln (interp e)))
