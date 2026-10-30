;; A record of procedures: the SRFI-39 parameter holds any `add` and `get`
;; closures over some pool, and its references can be anything at all.
(use-modules (ice-9 match) (srfi srfi-1) (srfi srfi-9))

(define-record-type <ast> (make-ast add get) ast? (add ast-add) (get ast-get))

(define pool (make-parameter #f))

(define (add expr) ((ast-add (pool)) expr))
(define (get ref) ((ast-get (pool)) ref))

(define (interp ref)
  (match (get ref)
    (('binary op lhs rhs)
     (let ((l (interp lhs)) (r (interp rhs)))
       (case op
         ((add) (+ l r))
         ((sub) (- l r))
         ((mul) (* l r))
         ((div) (if (zero? r) 0 (truncate-quotient l r))))))
    (('literal num) num)))

(define (lit n) (add `(literal ,n)))
(define (bin op l r) (add `(binary ,op ,l ,r)))

;; A node as three ints: 0 for a literal (num second), else 1..4 for its op.
(define binops '(add sub mul div))

(define (encode expr index)
  (match expr
    (('binary op l r)
     (list (+ 1 (list-index (lambda (o) (eq? o op)) binops)) (index l) (index r)))
    (('literal num) (list 0 num 0))))

(define (decode op l r ref)
  (if (zero? op) `(literal ,l) `(binary ,(list-ref binops (- op 1)) ,(ref l) ,(ref r))))

;; Representation 1: a node is an index into parallel lists (newest first).
(define-record-type <idx> (idx i) idx? (i idx-i))

(define (columns)
  (let ((ops '()) (lhs '()) (rhs '()))
    (make-ast
     (lambda (expr)
       (match (encode expr idx-i)
         ((op l r) (set! ops (cons op ops)) (set! lhs (cons l lhs)) (set! rhs (cons r rhs))))
       (idx (- (length ops) 1)))
     (lambda (ref)
       (let ((j (- (length ops) 1 (idx-i ref))))
         (decode (list-ref ops j) (list-ref lhs j) (list-ref rhs j) idx))))))

;; Representation 2: a node is an index into one list of triples (newest first).
(define-record-type <slot> (slot i) slot? (i slot-i))

(define (triples)
  (let ((nodes '()))
    (make-ast
     (lambda (expr)
       (set! nodes (append (encode expr slot-i) nodes))
       (slot (- (/ (length nodes) 3) 1)))
     (lambda (ref)
       (match (list-tail nodes (- (length nodes) (* 3 (+ (slot-i ref) 1))))
         ((op l r . _) (decode op l r slot)))))))

(parameterize ((pool (columns)))
  (let ((e (bin 'div (bin 'mul (bin 'sub (lit 7) (lit 10)) (lit 7)) (lit 2))))
    (display (interp e)) (newline)
    (parameterize ((pool (triples)))
      (display (interp (bin 'div (bin 'add (lit 4) (lit 4)) (bin 'sub (lit 4) (lit 4)))))
      (newline))
    (display (interp e)) (newline)))
