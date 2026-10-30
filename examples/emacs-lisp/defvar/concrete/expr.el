;;; -*- lexical-binding: t -*-
;; A `defvar` variable is dynamically bound even under lexical binding.
(defvar pool)

(defun pool-add (expr) (setq pool (vconcat pool (vector expr))) (1- (length pool)))
(defun pool-get (ref) (aref pool ref))

(defun interp (ref)
  (pcase (pool-get ref)
    (`(literal ,n) n)
    (`(binary ,op ,lhs ,rhs)
     (let ((l (interp lhs)) (r (interp rhs)))
       (pcase op
         ('add (+ l r))
         ('sub (- l r))
         ('mul (* l r))
         ('div (if (zerop r) 0 (/ l r))))))))

(defun lit (n) (pool-add (list 'literal n)))
(defun bin (op l r) (pool-add (list 'binary op l r)))

(let* ((pool [])
       (e (bin 'div (bin 'mul (bin 'sub (lit 7) (lit 10)) (lit 7)) (lit 2))))
  (princ (format "%d\n" (interp e)))
  (let ((pool []))
    (princ (format "%d\n" (interp (bin 'div (bin 'add (lit 4) (lit 4)) (bin 'sub (lit 4) (lit 4)))))))
  (princ (format "%d\n" (interp e))))
