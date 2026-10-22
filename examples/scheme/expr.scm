;; An SRFI-39 parameter, rebound with `parameterize`.
(use-modules (ice-9 match))

(define pool (make-parameter #f))

(define (node n)
  (set-car! (pool) (cons n (car (pool))))
  (- (length (car (pool))) 1))
(define (lit n) (node `(lit ,n)))
(define (add l r) (node `(add ,l ,r)))
(define (mul l r) (node `(mul ,l ,r)))

(define (ev e)
  (let ((nodes (car (pool))))
    (match (list-ref nodes (- (length nodes) 1 e))
      (('lit n) n)
      (('add l r) (+ (ev l) (ev r)))
      (('mul l r) (* (ev l) (ev r))))))

(parameterize ((pool (list '())))
  (let ((e (mul (add (lit 1) (lit 2)) (add (lit 3) (lit 4)))))
    (display (ev e)) (newline)
    (parameterize ((pool (list '())))
      (display (ev (add (lit 4) (lit 4)))) (newline))
    (display (ev e)) (newline)))
