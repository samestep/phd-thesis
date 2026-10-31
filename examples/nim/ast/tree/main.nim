# The tree Sampson starts from: each node is a `ref` to its children, so nothing
# needs a pool, but every node is its own heap allocation for ARC to free.
type
  BinOp = enum Add, Sub, Mul, Div
  ExprKind = enum Binary, Literal
  Expr = ref object
    case kind: ExprKind
    of Binary:
      op: BinOp
      lhs, rhs: Expr
    of Literal:
      num: int64

# Nim checks for overflow, so wrap explicitly; `div` truncates.
proc interp(e: Expr): int64 =
  case e.kind
  of Literal: e.num
  of Binary:
    let (lhs, rhs) = (interp(e.lhs), interp(e.rhs))
    case e.op
    of Add: cast[int64](cast[uint64](lhs) + cast[uint64](rhs))
    of Sub: cast[int64](cast[uint64](lhs) - cast[uint64](rhs))
    of Mul: cast[int64](cast[uint64](lhs) * cast[uint64](rhs))
    of Div: (if rhs == 0: 0'i64 else: lhs div rhs)

proc lit(n: int64): Expr = Expr(kind: Literal, num: n)
proc bin(op: BinOp, lhs, rhs: Expr): Expr = Expr(kind: Binary, op: op, lhs: lhs, rhs: rhs)

let e = bin(Div, bin(Mul, bin(Sub, lit(7), lit(10)), lit(7)), lit(2))
echo interp(e)
block:
  let f = bin(Div, bin(Add, lit(4), lit(4)), bin(Sub, lit(4), lit(4)))
  echo interp(f)
echo interp(e)
