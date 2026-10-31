// The pool is an effect parameterized by the index type, so every function
// that uses it is polymorphic in `r` and carries `ast<r>` in its effect row.
type binop
  Add
  Sub
  Mul
  Div

type expr<r>
  Binary(op : binop, lhs : r, rhs : r)
  Literal(num : int)

effect ast<r>
  fun add(e : expr<r>) : r
  fun get(e : r) : expr<r>

// Koka's `/` is Euclidean; the post's division truncates toward zero.
fun quot(x : int, y : int) : int
  val q = x.abs / y.abs
  if (x < 0) == (y < 0) then q else 0 - q

fun interp(e : r) : <ast<r>, div> int
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

fun lit(n : int) : ast<r> r
  add(Literal(n))

fun bin(op : binop, l : r, r : r) : ast<r> r
  add(Binary(op, l, r))

fun code(op : binop) : int
  match op
    Add -> 1
    Sub -> 2
    Mul -> 3
    Div -> 4

fun op-of(code : int) : binop
  match code
    1 -> Add
    2 -> Sub
    3 -> Mul
    _ -> Div

fun at(xs : list<int>, i : int) : int
  xs[i].default(0)

// Representation 1: a node is an index into parallel lists.
value struct idx
  i : int

fun columns-pool(action)
  var ops := []
  var lhs := []
  var rhs := []
  with handler
    fun add(e)
      val (op, l, r) = match e
        Binary(op, Idx(l), Idx(r)) -> (code(op), l, r)
        Literal(num) -> (0, num, 0)
      ops := ops ++ [op]
      lhs := lhs ++ [l]
      rhs := rhs ++ [r]
      Idx(ops.length - 1)
    fun get(idx : idx)
      val i = idx.i
      match ops.at(i)
        0 -> Literal(lhs.at(i))
        op -> Binary(op-of(op), Idx(lhs.at(i)), Idx(rhs.at(i)))
  action()

// Representation 2: a node is an index into one list of triples.
value struct slot
  i : int

fun triples-pool(action)
  var triples := []
  with handler
    fun add(e)
      match e
        Binary(op, Slot(l), Slot(r)) -> triples := triples ++ [code(op), l, r]
        Literal(num) -> triples := triples ++ [0, num, 0]
      Slot(triples.length / 3 - 1)
    fun get(slot : slot)
      val i = 3 * slot.i
      match triples.at(i)
        0 -> Literal(triples.at(i + 1))
        op -> Binary(op-of(op), Slot(triples.at(i + 1)), Slot(triples.at(i + 2)))
  action()

fun main()
  with columns-pool
  val e = bin(Div, bin(Mul, bin(Sub, lit(7), lit(10)), lit(7)), lit(2))
  println(interp(e))
  triples-pool
    println(interp(bin(Div, bin(Add, lit(4), lit(4)), bin(Sub, lit(4), lit(4)))))
  println(interp(e))
