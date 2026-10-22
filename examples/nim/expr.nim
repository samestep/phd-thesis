# A global pool, swapped for the body of a template and restored after it.
type
  Op = enum Lit, Add, Mul
  Node = tuple[op: Op, a, b: int]

var pool: seq[Node]

template withPool(body: untyped) =
  let saved = move pool
  try: body
  finally: pool = saved

proc push(op: Op, a, b: int): int =
  pool.add (op, a, b)
  pool.high

proc lit(n: int): int = push(Lit, n, 0)
proc add(l, r: int): int = push(Add, l, r)
proc mul(l, r: int): int = push(Mul, l, r)

proc eval(e: int): int =
  let n = pool[e]
  case n.op
  of Lit: n.a
  of Add: eval(n.a) + eval(n.b)
  of Mul: eval(n.a) * eval(n.b)

let e = mul(add(lit(1), lit(2)), add(lit(3), lit(4)))
echo eval(e)
withPool:
  echo eval(add(lit(4), lit(4)))
echo eval(e)
