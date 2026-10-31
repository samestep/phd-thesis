# A global pool, swapped for the body of a template and restored after it.
type
  BinOp = enum Add, Sub, Mul, Div
  ExprRef = distinct uint32
  ExprKind = enum Binary, Literal
  Expr = object
    case kind: ExprKind
    of Binary:
      op: BinOp
      lhs, rhs: ExprRef
    of Literal:
      num: int64
  ExprPool = seq[Expr]

var pool: ExprPool

template withPool(body: untyped) =
  let saved = move pool
  try: body
  finally: pool = saved

proc add(expr: Expr): ExprRef =
  pool.add expr
  ExprRef(pool.high)

proc get(expr: ExprRef): Expr = pool[int(expr)]

# Nim checks for overflow, so wrap explicitly; `div` truncates.
proc interp(expr: ExprRef): int64 =
  let e = get(expr)
  case e.kind
  of Literal: e.num
  of Binary:
    let (lhs, rhs) = (interp(e.lhs), interp(e.rhs))
    case e.op
    of Add: cast[int64](cast[uint64](lhs) + cast[uint64](rhs))
    of Sub: cast[int64](cast[uint64](lhs) - cast[uint64](rhs))
    of Mul: cast[int64](cast[uint64](lhs) * cast[uint64](rhs))
    of Div: (if rhs == 0: 0'i64 else: lhs div rhs)

proc lit(n: int64): ExprRef = add(Expr(kind: Literal, num: n))
proc bin(op: BinOp, lhs, rhs: ExprRef): ExprRef = add(Expr(kind: Binary, op: op, lhs: lhs, rhs: rhs))

let e = bin(Div, bin(Mul, bin(Sub, lit(7), lit(10)), lit(7)), lit(2))
echo interp(e)
withPool:
  echo interp(bin(Div, bin(Add, lit(4), lit(4)), bin(Sub, lit(4), lit(4))))
echo interp(e)
