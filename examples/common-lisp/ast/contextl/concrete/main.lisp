;; A ContextL layer: `with-active-layers` rebinds its special slot to a pool
;; and gives `pool-add` and `pool-get` a meaning for that dynamic extent. The
;; layer is one global name, so a fresh pool rebinds its slot, not a new layer.
(require :asdf)
(asdf:load-system :contextl)
(defpackage :expr (:use :contextl-common-lisp))
(in-package :expr)

(defun new-pool () (make-array 0 :adjustable t :fill-pointer t))

(deflayer pooled () ((pool :initarg :pool :special t :reader pool)))

(define-layered-function pool-add (expr))
(define-layered-function pool-get (ref))

(define-layered-method pool-add :in (layer pooled) (expr)
  (vector-push-extend expr (pool layer))
  (1- (length (pool layer))))

(define-layered-method pool-get :in (layer pooled) (ref)
  (aref (pool layer) ref))

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

(with-active-layers ((pooled :pool (new-pool)))
  (let ((e (bin :div (bin :mul (bin :sub (lit 7) (lit 10)) (lit 7)) (lit 2))))
    (format t "~a~%" (interp e))
    (with-active-layers ((pooled :pool (new-pool)))
      (format t "~a~%" (interp (bin :div (bin :add (lit 4) (lit 4)) (bin :sub (lit 4) (lit 4))))))
    (format t "~a~%" (interp e))))
