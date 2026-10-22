;; A special (dynamically scoped) variable, rebound with `let`.
(defvar *pool*)

(defun node (n) (vector-push-extend n *pool*) (1- (length *pool*)))
(defun lit (n) (node (list :lit n)))
(defun add (l r) (node (list :add l r)))
(defun mul (l r) (node (list :mul l r)))

(defun ev (e)
  (destructuring-bind (op a &optional b) (aref *pool* e)
    (ecase op
      (:lit a)
      (:add (+ (ev a) (ev b)))
      (:mul (* (ev a) (ev b))))))

(defun new-pool () (make-array 0 :adjustable t :fill-pointer t))

(let* ((*pool* (new-pool))
       (e (mul (add (lit 1) (lit 2)) (add (lit 3) (lit 4)))))
  (format t "~a~%" (ev e))
  (let ((*pool* (new-pool)))
    (format t "~a~%" (ev (add (lit 4) (lit 4)))))
  (format t "~a~%" (ev e)))
