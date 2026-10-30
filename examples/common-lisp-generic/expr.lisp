;; CLOS generic functions: the special variable holds any pool with methods
;; for `pool-add` and `pool-get`, and its references can be anything at all.
(defpackage :expr (:use :cl))
(in-package :expr)

(defvar *pool*)

(defgeneric pool-add (pool expr))
(defgeneric pool-get (pool ref))

(defun interp (ref)
  (destructuring-bind (tag a &optional lhs rhs) (pool-get *pool* ref)
    (ecase tag
      (:literal a)
      (:binary
       (let ((l (interp lhs)) (r (interp rhs)))
         (ecase a
           (:add (+ l r))
           (:sub (- l r))
           (:mul (* l r))
           (:div (if (zerop r) 0 (values (truncate l r))))))))))

(defun lit (n) (pool-add *pool* (list :literal n)))
(defun bin (op l r) (pool-add *pool* (list :binary op l r)))

;; A node as three ints: 0 for a literal (num second), else 1..4 for its op.
(defparameter *binops* '(:add :sub :mul :div))

(defun encode (expr index)
  (destructuring-bind (tag a &optional lhs rhs) expr
    (ecase tag
      (:literal (list 0 a 0))
      (:binary (list (1+ (position a *binops*)) (funcall index lhs) (funcall index rhs))))))

(defun decode (op l r ref)
  (if (zerop op)
      (list :literal l)
      (list :binary (nth (1- op) *binops*) (funcall ref l) (funcall ref r))))

(defun new-vector () (make-array 0 :adjustable t :fill-pointer t))

;; Representation 1: a node is an index into parallel lists.
(defstruct (idx (:constructor idx (i))) i)
(defstruct columns (ops (new-vector)) (lhs (new-vector)) (rhs (new-vector)))

(defmethod pool-add ((pool columns) expr)
  (let ((ops (columns-ops pool)))
    (mapc #'vector-push-extend (encode expr #'idx-i)
          (list ops (columns-lhs pool) (columns-rhs pool)))
    (idx (1- (length ops)))))

(defmethod pool-get ((pool columns) ref)
  (let ((i (idx-i ref)))
    (decode (aref (columns-ops pool) i) (aref (columns-lhs pool) i) (aref (columns-rhs pool) i)
            #'idx)))

;; Representation 2: a node is an index into one list of triples.
(defstruct (slot (:constructor slot (i))) i)
(defstruct triples (nodes (new-vector)))

(defmethod pool-add ((pool triples) expr)
  (let ((nodes (triples-nodes pool)))
    (dolist (x (encode expr #'slot-i)) (vector-push-extend x nodes))
    (slot (1- (floor (length nodes) 3)))))

(defmethod pool-get ((pool triples) ref)
  (let ((nodes (triples-nodes pool)) (i (* 3 (slot-i ref))))
    (decode (aref nodes i) (aref nodes (+ i 1)) (aref nodes (+ i 2)) #'slot)))

(let* ((*pool* (make-columns))
       (e (bin :div (bin :mul (bin :sub (lit 7) (lit 10)) (lit 7)) (lit 2))))
  (format t "~a~%" (interp e))
  (let ((*pool* (make-triples)))
    (format t "~a~%" (interp (bin :div (bin :add (lit 4) (lit 4)) (bin :sub (lit 4) (lit 4))))))
  (format t "~a~%" (interp e)))
