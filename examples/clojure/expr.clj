;; Dynamic var: `binding` rebinds the pool for the dynamic extent of a form.
(def ^:dynamic *pool*)

;; An expression is [:binary op lhs rhs] or [:literal num]; an ExprRef is its index.
(defn add [expr]
  (swap! *pool* conj expr)
  (dec (count @*pool*)))

(defn get-expr [expr] (nth @*pool* expr))

(defn interp [expr]
  (let [[kind a b c] (get-expr expr)]
    (case kind
      :binary (let [l (interp b) r (interp c)]
                (case a
                  :add (unchecked-add l r)
                  :sub (unchecked-subtract l r)
                  :mul (unchecked-multiply l r)
                  :div (if (zero? r) 0 (quot l r))))
      :literal a)))

(defn lit [n] (add [:literal n]))
(defn bin [op l r] (add [:binary op l r]))

(binding [*pool* (atom [])]
  (let [e (bin :div (bin :mul (bin :sub (lit 7) (lit 10)) (lit 7)) (lit 2))]
    (println (interp e))
    (binding [*pool* (atom [])]
      (println (interp (bin :div (bin :add (lit 4) (lit 4)) (bin :sub (lit 4) (lit 4))))))
    (println (interp e))))
