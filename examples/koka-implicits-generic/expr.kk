// Implicit parameters: each call site fills `?ast` with whatever `ast` is in
// scope there. To abstract the index type, `ast` is a record of functions, so
// its type carries both the index type and the effect those functions have.
type binop
  Add
  Sub
  Mul
  Div

type expr<r>
  Binary(op : binop, lhs : r, rhs : r)
  Literal(num : int)

struct ast<r, e>
  add-expr : (expr<r>) -> e r
  get-expr : (r) -> e expr<r>

fun add(e : expr<r>, ?ast : ast<r, e>) : e r
  (ast.add-expr)(e)

fun get(e : r, ?ast : ast<r, e>) : e expr<r>
  (ast.get-expr)(e)

// Koka's `/` is Euclidean; the post's division truncates toward zero.
fun quot(x : int, y : int) : int
  val q = x.abs / y.abs
  if (x < 0) == (y < 0) then q else 0 - q

// `interp` diverges, so the record's effect must leave room for `div`. (The
// explicit `<r, e>` works around a Koka 3.2.9 internal error, a kind mismatch.)
fun interp<r, e>(e : r, ?ast : ast<r, <div|e>>) : <div|e> int
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

fun lit(n, ?ast) add(Literal(n))
fun bin(op, l, r, ?ast) add(Binary(op, l, r))

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

fun columns() : alloc<h> ast<idx, <read<h>, write<h>|e>>
  val ops = ref([])
  val lhs = ref([])
  val rhs = ref([])
  fun add-expr(e)
    val (op, l, r) = match e
      Binary(op, Idx(l), Idx(r)) -> (code(op), l, r)
      Literal(num) -> (0, num, 0)
    ops := !ops ++ [op]
    lhs := !lhs ++ [l]
    rhs := !rhs ++ [r]
    Idx((!ops).length - 1)
  fun get-expr(idx : idx)
    val i = idx.i
    match (!ops).at(i)
      0 -> Literal((!lhs).at(i))
      op -> Binary(op-of(op), Idx((!lhs).at(i)), Idx((!rhs).at(i)))
  Ast(add-expr, get-expr)

// Representation 2: a node is an index into one list of triples.
value struct slot
  i : int

fun triples() : alloc<h> ast<slot, <read<h>, write<h>|e>>
  val triples = ref([])
  fun add-expr(e)
    match e
      Binary(op, Slot(l), Slot(r)) -> triples := !triples ++ [code(op), l, r]
      Literal(num) -> triples := !triples ++ [0, num, 0]
    Slot((!triples).length / 3 - 1)
  fun get-expr(slot : slot)
    val i = 3 * slot.i
    match (!triples).at(i)
      0 -> Literal((!triples).at(i + 1))
      op -> Binary(op-of(op), Slot((!triples).at(i + 1)), Slot((!triples).at(i + 2)))
  Ast(add-expr, get-expr)

fun elsewhere()
  val ast = triples()
  println(interp(bin(Div, bin(Add, lit(4), lit(4)), bin(Sub, lit(4), lit(4)))))

fun main()
  val ast = columns()
  val e = bin(Div, bin(Mul, bin(Sub, lit(7), lit(10)), lit(7)), lit(2))
  println(interp(e))
  elsewhere()
  println(interp(e))
