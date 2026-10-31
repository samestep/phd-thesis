;; The tree Sampson starts from: each node is a list holding its children,
;; so nothing needs a pool, but every node is its own garbage-collected cons.
(defun interp (expr)
  (destructuring-bind (tag a &optional lhs rhs) expr
    (ecase tag
      (:literal a)
      (:binary
       (let ((l (interp lhs)) (r (interp rhs)))
         (ecase a
           (:add (+ l r))
           (:sub (- l r))
           (:mul (* l r))
           (:div (if (zerop r) 0 (values (truncate l r))))))))))

(defun lit (n) (list :literal n))
(defun bin (op l r) (list :binary op l r))

(let ((e (bin :div (bin :mul (bin :sub (lit 7) (lit 10)) (lit 7)) (lit 2))))
  (format t "~a~%" (interp e))
  (let ((f (bin :div (bin :add (lit 4) (lit 4)) (bin :sub (lit 4) (lit 4)))))
    (format t "~a~%" (interp f)))
  (format t "~a~%" (interp e)))
