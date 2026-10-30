;;; -*- lexical-binding: t -*-
;; Generic functions: the `defvar` variable holds any pool with methods for
;; `pool-add` and `pool-get`, and its references can be anything at all.
(require 'cl-lib)
(defvar pool)

(cl-defgeneric pool-add (ast expr))
(cl-defgeneric pool-get (ast ref))

(defun interp (ref)
  (pcase (pool-get pool ref)
    (`(literal ,n) n)
    (`(binary ,op ,lhs ,rhs)
     (let ((l (interp lhs)) (r (interp rhs)))
       (pcase op
         ('add (+ l r))
         ('sub (- l r))
         ('mul (* l r))
         ('div (if (zerop r) 0 (/ l r))))))))

(defun lit (n) (pool-add pool (list 'literal n)))
(defun bin (op l r) (pool-add pool (list 'binary op l r)))

;; A node as three ints: 0 for a literal (num second), else 1..4 for its op.
(defconst binops '(add sub mul div))

(defun encode (expr index)
  (pcase expr
    (`(literal ,n) (list 0 n 0))
    (`(binary ,op ,l ,r) (list (1+ (cl-position op binops)) (funcall index l) (funcall index r)))))

(defun decode (op l r ref)
  (if (zerop op)
      (list 'literal l)
      (list 'binary (nth (1- op) binops) (funcall ref l) (funcall ref r))))

;; Representation 1: a node is an index into parallel lists.
(cl-defstruct (idx (:constructor idx (i))) i)
(cl-defstruct columns (ops []) (lhs []) (rhs []))

(cl-defmethod pool-add ((ast columns) expr)
  (pcase-let ((`(,op ,l ,r) (encode expr #'idx-i)))
    (setf (columns-ops ast) (vconcat (columns-ops ast) (vector op))
          (columns-lhs ast) (vconcat (columns-lhs ast) (vector l))
          (columns-rhs ast) (vconcat (columns-rhs ast) (vector r)))
    (idx (1- (length (columns-ops ast))))))

(cl-defmethod pool-get ((ast columns) ref)
  (let ((i (idx-i ref)))
    (decode (aref (columns-ops ast) i) (aref (columns-lhs ast) i) (aref (columns-rhs ast) i)
            #'idx)))

;; Representation 2: a node is an index into one list of triples.
(cl-defstruct (slot (:constructor slot (i))) i)
(cl-defstruct triples (nodes []))

(cl-defmethod pool-add ((ast triples) expr)
  (setf (triples-nodes ast) (vconcat (triples-nodes ast) (encode expr #'slot-i)))
  (slot (1- (/ (length (triples-nodes ast)) 3))))

(cl-defmethod pool-get ((ast triples) ref)
  (let ((nodes (triples-nodes ast)) (i (* 3 (slot-i ref))))
    (decode (aref nodes i) (aref nodes (+ i 1)) (aref nodes (+ i 2)) #'slot)))

(let* ((pool (make-columns))
       (e (bin 'div (bin 'mul (bin 'sub (lit 7) (lit 10)) (lit 7)) (lit 2))))
  (princ (format "%d\n" (interp e)))
  (let ((pool (make-triples)))
    (princ (format "%d\n" (interp (bin 'div (bin 'add (lit 4) (lit 4)) (bin 'sub (lit 4) (lit 4)))))))
  (princ (format "%d\n" (interp e))))
