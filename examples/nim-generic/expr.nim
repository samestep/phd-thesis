# Generics with late binding: `interp` is generic in the index type, and the
# `add` and `get` it calls are resolved by overloading when it's instantiated,
# so each representation has its own global pool, swapped by the template.
type
  BinOp = enum Add = 1, Sub, Mul, Div # 0 means a literal.
  ExprKind = enum Binary, Literal
  Expr[R] = object
    case kind: ExprKind
    of Binary:
      op: BinOp
      lhs, rhs: R
    of Literal:
      num: int64

template withPool(pool: typed, body: untyped) =
  let saved = move pool
  try: body
  finally: pool = saved

# Nim checks for overflow, so wrap explicitly; `div` truncates.
proc interp[R](expr: R): int64 =
  mixin get
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

proc lit[R](n: int64): R =
  mixin add
  add(Expr[R](kind: Literal, num: n))
proc bin[R](op: BinOp, lhs, rhs: R): R =
  mixin add
  add(Expr[R](kind: Binary, op: op, lhs: lhs, rhs: rhs))

proc row[R](expr: Expr[R]): array[3, int64] =
  case expr.kind
  of Binary: [int64(ord(expr.op)), int64(expr.lhs), int64(expr.rhs)]
  of Literal: [0'i64, expr.num, 0]

proc node[R](op, lhs, rhs: int64): Expr[R] =
  if op == 0: Expr[R](kind: Literal, num: lhs)
  else: Expr[R](kind: Binary, op: BinOp(op), lhs: R(lhs), rhs: R(rhs))

# Representation 1: a node is an index into parallel lists.
type Idx = distinct uint32
var columns: tuple[ops, lhs, rhs: seq[int64]]

proc add(expr: Expr[Idx]): Idx =
  let r = row(expr)
  columns.ops.add r[0]
  columns.lhs.add r[1]
  columns.rhs.add r[2]
  Idx(columns.ops.high)

proc get(expr: Idx): Expr[Idx] =
  let i = int(expr)
  node[Idx](columns.ops[i], columns.lhs[i], columns.rhs[i])

# Representation 2: a node is an index into one list of triples.
type Slot = distinct uint32
var triples: seq[int64]

proc add(expr: Expr[Slot]): Slot =
  triples.add row(expr)
  Slot(triples.len div 3 - 1)

proc get(expr: Slot): Expr[Slot] =
  let i = 3 * int(expr)
  node[Slot](triples[i], triples[i + 1], triples[i + 2])

let e = bin(Div, bin(Mul, bin(Sub, lit[Idx](7), lit[Idx](10)), lit[Idx](7)), lit[Idx](2))
echo interp(e)
withPool triples:
  echo interp(bin(Div, bin(Add, lit[Slot](4), lit[Slot](4)), bin(Sub, lit[Slot](4), lit[Slot](4))))
echo interp(e)
