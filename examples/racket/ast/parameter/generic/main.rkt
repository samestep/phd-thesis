#lang racket/base
;; A generic interface: the parameter holds any value implementing `gen:ast`,
;; and its references can be anything at all.
(require racket/match racket/generic racket/list data/gvector)

(struct binary (op lhs rhs))
(struct literal (num))

(define-generics ast
  (add ast expr)
  (get ast ref))

(define pool (make-parameter #f))

(define (interp ref)
  (match (get (pool) ref)
    [(binary op lhs rhs)
     (define l (interp lhs))
     (define r (interp rhs))
     (case op
       [(add) (+ l r)]
       [(sub) (- l r)]
       [(mul) (* l r)]
       [(div) (if (zero? r) 0 (quotient l r))])]
    [(literal num) num]))

(define (lit n) (add (pool) (literal n)))
(define (bin op l r) (add (pool) (binary op l r)))

;; A node as three ints: 0 for a literal (num second), else 1..4 for its op.
(define binops '(add sub mul div))

(define (encode expr index)
  (match expr
    [(binary op l r) (list (add1 (index-of binops op)) (index l) (index r))]
    [(literal num) (list 0 num 0)]))

(define (decode op l r ref)
  (if (zero? op) (literal l) (binary (list-ref binops (sub1 op)) (ref l) (ref r))))

;; Representation 1: a node is an index into parallel lists.
(struct idx (i))

(struct columns (ops lhs rhs)
  #:methods gen:ast
  [(define (add ast expr)
     (for ([column (list (columns-ops ast) (columns-lhs ast) (columns-rhs ast))]
           [x (encode expr idx-i)])
       (gvector-add! column x))
     (idx (sub1 (gvector-count (columns-ops ast)))))
   (define (get ast ref)
     (define i (idx-i ref))
     (decode (gvector-ref (columns-ops ast) i)
             (gvector-ref (columns-lhs ast) i)
             (gvector-ref (columns-rhs ast) i)
             idx))])

;; Representation 2: a node is an index into one list of triples.
(struct slot (i))

(struct triples (nodes)
  #:methods gen:ast
  [(define (add ast expr)
     (apply gvector-add! (triples-nodes ast) (encode expr slot-i))
     (slot (sub1 (quotient (gvector-count (triples-nodes ast)) 3))))
   (define (get ast ref)
     (define i (* 3 (slot-i ref)))
     (define (at j) (gvector-ref (triples-nodes ast) (+ i j)))
     (decode (at 0) (at 1) (at 2) slot))])

(parameterize ([pool (columns (make-gvector) (make-gvector) (make-gvector))])
  (define e (bin 'div (bin 'mul (bin 'sub (lit 7) (lit 10)) (lit 7)) (lit 2)))
  (displayln (interp e))
  (parameterize ([pool (triples (make-gvector))])
    (displayln (interp (bin 'div (bin 'add (lit 4) (lit 4)) (bin 'sub (lit 4) (lit 4))))))
  (displayln (interp e)))
