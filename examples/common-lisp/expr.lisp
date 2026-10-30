;; A special (dynamically scoped) variable, rebound with `let`.
(defvar *pool*)

(defun new-pool () (make-array 0 :adjustable t :fill-pointer t))
(defun pool-add (expr) (vector-push-extend expr *pool*) (1- (length *pool*)))
(defun pool-get (ref) (aref *pool* ref))

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

(let* ((*pool* (new-pool))
       (e (bin :div (bin :mul (bin :sub (lit 7) (lit 10)) (lit 7)) (lit 2))))
  (format t "~a~%" (interp e))
  (let ((*pool* (new-pool)))
    (format t "~a~%" (interp (bin :div (bin :add (lit 4) (lit 4)) (bin :sub (lit 4) (lit 4))))))
  (format t "~a~%" (interp e)))
