// Implicit parameters: each call site fills `?nodes` with whatever `nodes` is in scope there.
type node
  Lit(n : int)
  Add(l : int, r : int)
  Mul(l : int, r : int)

fun push(n : node, ?nodes : ref<h, list<node>>) : <read<h>, write<h>> int
  nodes := !nodes ++ [n]
  (!nodes).length - 1

fun lit(n, ?nodes) push(Lit(n))
fun add(l, r, ?nodes) push(Add(l, r))
fun mul(l, r, ?nodes) push(Mul(l, r))

fun eval(e : int, ?nodes : ref<h, list<node>>) : <read<h>, div> int
  match (!nodes)[e]
    Just(Lit(n)) -> n
    Just(Add(l, r)) -> eval(l) + eval(r)
    Just(Mul(l, r)) -> eval(l) * eval(r)
    Nothing -> 0

fun elsewhere()
  val nodes = ref([])
  println(eval(add(lit(4), lit(4))))

fun main()
  val nodes = ref([])
  val e = mul(add(lit(1), lit(2)), add(lit(3), lit(4)))
  println(eval(e))
  elsewhere()
  println(eval(e))
