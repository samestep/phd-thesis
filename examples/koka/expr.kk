// The pool is an effect; `with pool` installs a handler for the rest of the scope.
type binop
  Add
  Sub
  Mul
  Div

alias expr-ref = int

type expr
  Binary(op : binop, lhs : expr-ref, rhs : expr-ref)
  Literal(num : int)

effect pool
  fun add(e : expr) : expr-ref
  fun get(e : expr-ref) : expr

// Koka's `/` is Euclidean; the post's division truncates toward zero.
fun quot(x : int, y : int) : int
  val q = x.abs / y.abs
  if (x < 0) == (y < 0) then q else 0 - q

fun interp(e : expr-ref) : <pool, div> int
  match get(e)
    Binary(op, lhs, rhs) ->
      val l = interp(lhs)
      val r = interp(rhs)
      match op
        Add -> l + r
        Sub -> l - r
        Mul -> l * r
        Div -> if r == 0 then 0 else quot(l, r)
    Literal(num) -> num

fun pool(action)
  var nodes := []
  with handler
    fun add(e)
      nodes := nodes ++ [e]
      nodes.length - 1
    fun get(i)
      match nodes[i]
        Just(e) -> e
        Nothing -> Literal(0)
  action()

fun lit(n) add(Literal(n))
fun bin(op, l, r) add(Binary(op, l, r))

fun main()
  with pool
  val e = bin(Div, bin(Mul, bin(Sub, lit(7), lit(10)), lit(7)), lit(2))
  println(interp(e))
  pool
    println(interp(bin(Div, bin(Add, lit(4), lit(4)), bin(Sub, lit(4), lit(4)))))
  println(interp(e))
