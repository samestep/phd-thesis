;; Protocol: the dynamic var holds any value implementing `Ast`, and its
;; references can be anything at all.
(def ^:dynamic *ast*)

(defprotocol Ast
  (add [ast expr])
  (get-expr [ast ref]))

;; An expression is [:binary op lhs rhs] or [:literal num]; lhs and rhs are refs.
(defn interp [expr]
  (let [[kind a b c] (get-expr *ast* expr)]
    (case kind
      :binary (let [l (interp b) r (interp c)]
                (case a
                  :add (unchecked-add l r)
                  :sub (unchecked-subtract l r)
                  :mul (unchecked-multiply l r)
                  :div (if (zero? r) 0 (quot l r))))
      :literal a)))

(defn lit [n] (add *ast* [:literal n]))
(defn bin [op l r] (add *ast* [:binary op l r]))

(def binops [:add :sub :mul :div])

;; A node as three ints: 0 for a literal (num second), else 1..4 for its op.
(defn encode [[kind a b c] index]
  (case kind
    :binary [(inc (.indexOf binops a)) (index b) (index c)]
    :literal [0 a 0]))

(defn decode [[op l r] ref]
  (if (zero? op) [:literal l] [:binary (binops (dec op)) (ref l) (ref r)]))

;; Representation 1: a node is an index into parallel lists.
(defrecord Idx [i])

(defrecord Columns [ops lhs rhs]
  Ast
  (add [_ expr]
    (let [[op l r] (encode expr :i)]
      (swap! ops conj op)
      (swap! lhs conj l)
      (swap! rhs conj r)
      (->Idx (dec (count @ops)))))
  (get-expr [_ {i :i}]
    (decode [(@ops i) (@lhs i) (@rhs i)] ->Idx)))

;; Representation 2: a node is an index into one list of triples.
(defrecord Slot [i])

(defrecord Triples [triples]
  Ast
  (add [_ expr]
    (swap! triples into (encode expr :i))
    (->Slot (dec (quot (count @triples) 3))))
  (get-expr [_ {i :i}]
    (decode (subvec @triples (* 3 i) (* 3 (inc i))) ->Slot)))

(binding [*ast* (->Columns (atom []) (atom []) (atom []))]
  (let [e (bin :div (bin :mul (bin :sub (lit 7) (lit 10)) (lit 7)) (lit 2))]
    (println (interp e))
    (binding [*ast* (->Triples (atom []))]
      (println (interp (bin :div (bin :add (lit 4) (lit 4)) (bin :sub (lit 4) (lit 4))))))
    (println (interp e))))
