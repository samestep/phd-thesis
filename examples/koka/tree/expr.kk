// The tree Sampson starts from: each node holds its children directly, and
// reference counting frees them, so nothing needs a pool.
type binop
  Add
  Sub
  Mul
  Div

type expr
  Binary(op : binop, lhs : expr, rhs : expr)
  Literal(num : int)

// Koka's `/` is Euclidean; the post's division truncates toward zero.
fun quot(x : int, y : int) : int
  val q = x.abs / y.abs
  if (x < 0) == (y < 0) then q else 0 - q

fun interp(e : expr) : int
  match e
    Binary(op, lhs, rhs) ->
      val l = interp(lhs)
      val r = interp(rhs)
      match op
        Add -> l + r
        Sub -> l - r
        Mul -> l * r
        Div -> if r == 0 then 0 else quot(l, r)
    Literal(num) -> num

fun lit(n) Literal(n)
fun bin(op, l, r) Binary(op, l, r)

fun main()
  val e = bin(Div, bin(Mul, bin(Sub, lit(7), lit(10)), lit(7)), lit(2))
  println(interp(e))
  // Koka has no bare block statement, and with no pool there's nothing to scope.
  println(interp(bin(Div, bin(Add, lit(4), lit(4)), bin(Sub, lit(4), lit(4)))))
  println(interp(e))
