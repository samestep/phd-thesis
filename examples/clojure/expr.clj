;; Dynamic var: `binding` rebinds the pool for the dynamic extent of a form.
(def ^:dynamic *pool*)

(defn push [node]
  (swap! *pool* conj node)
  (dec (count @*pool*)))

(defn lit [n] (push [:lit n]))
(defn add [l r] (push [:add l r]))
(defn mul [l r] (push [:mul l r]))

(defn eval-expr [e]
  (let [[op a b] (nth @*pool* e)]
    (case op
      :lit a
      :add (+ (eval-expr a) (eval-expr b))
      :mul (* (eval-expr a) (eval-expr b)))))

(binding [*pool* (atom [])]
  (let [e (mul (add (lit 1) (lit 2)) (add (lit 3) (lit 4)))]
    (println (eval-expr e))
    (binding [*pool* (atom [])]
      (println (eval-expr (add (lit 4) (lit 4)))))
    (println (eval-expr e))))
