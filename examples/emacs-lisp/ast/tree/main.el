;;; -*- lexical-binding: t -*-
;; The tree Sampson starts from: each node is a list holding its children,
;; so nothing needs a pool, but every node is its own garbage-collected cons.
(defun interp (expr)
  (pcase expr
    (`(literal ,n) n)
    (`(binary ,op ,lhs ,rhs)
     (let ((l (interp lhs)) (r (interp rhs)))
       (pcase op
         ('add (+ l r))
         ('sub (- l r))
         ('mul (* l r))
         ('div (if (zerop r) 0 (/ l r))))))))

(defun lit (n) (list 'literal n))
(defun bin (op l r) (list 'binary op l r))

(let ((e (bin 'div (bin 'mul (bin 'sub (lit 7) (lit 10)) (lit 7)) (lit 2))))
  (princ (format "%d\n" (interp e)))
  (let ((f (bin 'div (bin 'add (lit 4) (lit 4)) (bin 'sub (lit 4) (lit 4)))))
    (princ (format "%d\n" (interp f))))
  (princ (format "%d\n" (interp e))))
