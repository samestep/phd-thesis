;; ContextL layers as representations: each refines `pool-add` and `pool-get`
;; and keeps its pool in special slots, rebound when it is activated, so one
;; `interp` runs under whichever is active. Unlike special-var, dispatch is on
;; the active layers, not a pool object: activating `triples` leaves `columns`
;; active beneath it, so `pool-get` on an `idx` still reads pool A.
(require :asdf)
(asdf:load-system :contextl)
(defpackage :expr (:use :contextl-common-lisp))
(in-package :expr)

(define-layered-function pool-add (expr))
(define-layered-function pool-get (ref))

(defun interp (ref)
  (destructuring-bind (tag a &optional lhs rhs) (pool-get ref)
    (ecase tag
      (:literal a)
      (:binary
       (let ((l (interp lhs)) (r (interp rhs)))
         (ecase a
           (:add (+ l r))
           (:sub (- l r))
           (:mul (* l r))
           (:div (if (zerop r) 0 (values (truncate l r))))))))))

(defun lit (n) (pool-add (list :literal n)))
(defun bin (op l r) (pool-add (list :binary op l r)))

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
(deflayer columns ()
  ((ops :initarg :ops :special t :reader ops)
   (lhs :initarg :lhs :special t :reader lhs)
   (rhs :initarg :rhs :special t :reader rhs)))

(define-layered-method pool-add :in (layer columns) (expr)
  (mapc #'vector-push-extend (encode expr #'idx-i) (list (ops layer) (lhs layer) (rhs layer)))
  (idx (1- (length (ops layer)))))

(define-layered-method pool-get :in (layer columns) ((ref idx))
  (let ((i (idx-i ref)))
    (decode (aref (ops layer) i) (aref (lhs layer) i) (aref (rhs layer) i) #'idx)))

;; Representation 2: a node is an index into one list of triples.
(defstruct (slot (:constructor slot (i))) i)
(deflayer triples () ((nodes :initarg :nodes :special t :reader nodes)))

(define-layered-method pool-add :in (layer triples) (expr)
  (dolist (x (encode expr #'slot-i)) (vector-push-extend x (nodes layer)))
  (slot (1- (floor (length (nodes layer)) 3))))

(define-layered-method pool-get :in (layer triples) ((ref slot))
  (let ((nodes (nodes layer)) (i (* 3 (slot-i ref))))
    (decode (aref nodes i) (aref nodes (+ i 1)) (aref nodes (+ i 2)) #'slot)))

(with-active-layers ((columns :ops (new-vector) :lhs (new-vector) :rhs (new-vector)))
  (let ((e (bin :div (bin :mul (bin :sub (lit 7) (lit 10)) (lit 7)) (lit 2))))
    (format t "~a~%" (interp e))
    (with-active-layers ((triples :nodes (new-vector)))
      (format t "~a~%" (interp (bin :div (bin :add (lit 4) (lit 4)) (bin :sub (lit 4) (lit 4))))))
    (format t "~a~%" (interp e))))
