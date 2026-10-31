#lang racket/base
;; The tree Sampson starts from: each struct holds references to its children,
;; so nothing needs a pool, but every node is its own heap object.
(require racket/match)

(struct binary (op lhs rhs))
(struct literal (num))

(define (interp expr)
  (match expr
    [(binary op lhs rhs)
     (define l (interp lhs))
     (define r (interp rhs))
     (case op
       [(add) (+ l r)]
       [(sub) (- l r)]
       [(mul) (* l r)]
       [(div) (if (zero? r) 0 (quotient l r))])]
    [(literal num) num]))

(define (lit n) (literal n))
(define (bin op l r) (binary op l r))

(let ([e (bin 'div (bin 'mul (bin 'sub (lit 7) (lit 10)) (lit 7)) (lit 2))])
  (displayln (interp e))
  (let ([f (bin 'div (bin 'add (lit 4) (lit 4)) (bin 'sub (lit 4) (lit 4)))])
    (displayln (interp f)))
  (displayln (interp e)))
