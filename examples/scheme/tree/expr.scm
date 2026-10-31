;; The tree Sampson starts from: each node is a list holding its children,
;; so nothing needs a pool, but every node is its own garbage-collected cons.
(use-modules (ice-9 match))

(define (interp expr)
  (match expr
    (('binary op lhs rhs)
     (let ((l (interp lhs)) (r (interp rhs)))
       (case op
         ((add) (+ l r))
         ((sub) (- l r))
         ((mul) (* l r))
         ((div) (if (zero? r) 0 (truncate-quotient l r))))))
    (('literal num) num)))

(define (lit n) `(literal ,n))
(define (bin op l r) `(binary ,op ,l ,r))

(let ((e (bin 'div (bin 'mul (bin 'sub (lit 7) (lit 10)) (lit 7)) (lit 2))))
  (display (interp e)) (newline)
  (let ((f (bin 'div (bin 'add (lit 4) (lit 4)) (bin 'sub (lit 4) (lit 4)))))
    (display (interp f)) (newline))
  (display (interp e)) (newline))
