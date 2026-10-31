;; An SRFI-39 parameter, rebound with `parameterize`.
(use-modules (ice-9 match))

;; A pool is a one-element list holding its nodes, newest first.
(define pool (make-parameter #f))

(define (add expr)
  (set-car! (pool) (cons expr (car (pool))))
  (- (length (car (pool))) 1))
(define (get ref)
  (let ((nodes (car (pool))))
    (list-ref nodes (- (length nodes) 1 ref))))

(define (interp ref)
  (match (get ref)
    (('binary op lhs rhs)
     (let ((l (interp lhs)) (r (interp rhs)))
       (case op
         ((add) (+ l r))
         ((sub) (- l r))
         ((mul) (* l r))
         ((div) (if (zero? r) 0 (truncate-quotient l r))))))
    (('literal num) num)))

(define (lit n) (add `(literal ,n)))
(define (bin op l r) (add `(binary ,op ,l ,r)))

(parameterize ((pool (list '())))
  (let ((e (bin 'div (bin 'mul (bin 'sub (lit 7) (lit 10)) (lit 7)) (lit 2))))
    (display (interp e)) (newline)
    (parameterize ((pool (list '())))
      (display (interp (bin 'div (bin 'add (lit 4) (lit 4)) (bin 'sub (lit 4) (lit 4)))))
      (newline))
    (display (interp e)) (newline)))
