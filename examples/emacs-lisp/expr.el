;;; -*- lexical-binding: t -*-
;; A `defvar` variable is dynamically bound even under lexical binding.
(defvar pool)

(defun node (n) (setq pool (vconcat pool (vector n))) (1- (length pool)))
(defun lit (n) (node (list 'lit n)))
(defun add (l r) (node (list 'add l r)))
(defun mul (l r) (node (list 'mul l r)))

(defun ev (e)
  (pcase (aref pool e)
    (`(lit ,n) n)
    (`(add ,l ,r) (+ (ev l) (ev r)))
    (`(mul ,l ,r) (* (ev l) (ev r)))))

(let* ((pool [])
       (e (mul (add (lit 1) (lit 2)) (add (lit 3) (lit 4)))))
  (princ (format "%d\n" (ev e)))
  (let ((pool []))
    (princ (format "%d\n" (ev (add (lit 4) (lit 4))))))
  (princ (format "%d\n" (ev e))))
