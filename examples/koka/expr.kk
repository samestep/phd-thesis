// The pool is an effect; `with pool` installs a handler for the rest of the scope.
type node
  Lit(n : int)
  Add(l : int, r : int)
  Mul(l : int, r : int)

effect pool
  fun push(n : node) : int
  fun get(i : int) : node

fun lit(n) push(Lit(n))
fun add(l, r) push(Add(l, r))
fun mul(l, r) push(Mul(l, r))

fun eval(e : int) : <pool, div> int
  match get(e)
    Lit(n) -> n
    Add(l, r) -> eval(l) + eval(r)
    Mul(l, r) -> eval(l) * eval(r)

fun pool(action)
  var nodes := []
  with handler
    fun push(n)
      nodes := nodes ++ [n]
      nodes.length - 1
    fun get(i)
      match nodes[i]
        Just(n) -> n
        Nothing -> Lit(0)
  action()

fun main()
  with pool
  val e = mul(add(lit(1), lit(2)), add(lit(3), lit(4)))
  println(eval(e))
  pool
    println(eval(add(lit(4), lit(4))))
  println(eval(e))
