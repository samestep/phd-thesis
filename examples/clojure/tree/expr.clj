;; The tree Sampson starts from: each node is a vector holding its children,
;; so nothing needs a pool; nodes are immutable values the GC shares.

;; An expression is [:binary op lhs rhs] or [:literal num].
(defn interp [expr]
  (let [[kind a b c] expr]
    (case kind
      :binary (let [l (interp b) r (interp c)]
                (case a
                  :add (unchecked-add l r)
                  :sub (unchecked-subtract l r)
                  :mul (unchecked-multiply l r)
                  :div (if (zero? r) 0 (quot l r))))
      :literal a)))

(defn lit [n] [:literal n])
(defn bin [op l r] [:binary op l r])

(let [e (bin :div (bin :mul (bin :sub (lit 7) (lit 10)) (lit 7)) (lit 2))]
  (println (interp e))
  (let [f (bin :div (bin :add (lit 4) (lit 4)) (bin :sub (lit 4) (lit 4)))]
    (println (interp f)))
  (println (interp e)))
