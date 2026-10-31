// Implicit parameters: each call site fills `?pool` with whatever `pool` is in scope there.
type binop
  Add
  Sub
  Mul
  Div

alias expr-ref = int

type expr
  Binary(op : binop, lhs : expr-ref, rhs : expr-ref)
  Literal(num : int)

fun add(e : expr, ?pool : ref<h, list<expr>>) : <read<h>, write<h>> expr-ref
  pool := !pool ++ [e]
  (!pool).length - 1

fun get(e : expr-ref, ?pool : ref<h, list<expr>>) : read<h> expr
  match (!pool)[e]
    Just(x) -> x
    Nothing -> Literal(0)

// Koka's `/` is Euclidean; the post's division truncates toward zero.
fun quot(x : int, y : int) : int
  val q = x.abs / y.abs
  if (x < 0) == (y < 0) then q else 0 - q

fun interp(e : expr-ref, ?pool : ref<h, list<expr>>) : <read<h>, div> int
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

fun lit(n, ?pool) add(Literal(n))
fun bin(op, l, r, ?pool) add(Binary(op, l, r))

fun elsewhere()
  val pool = ref([])
  println(interp(bin(Div, bin(Add, lit(4), lit(4)), bin(Sub, lit(4), lit(4)))))

fun main()
  val pool = ref([])
  val e = bin(Div, bin(Mul, bin(Sub, lit(7), lit(10)), lit(7)), lit(2))
  println(interp(e))
  elsewhere()
  println(interp(e))
