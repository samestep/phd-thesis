-- The tree Sampson starts from: each node is a table holding its children,
-- so nothing needs a pool, but every node is its own allocation.
local function interp(expr)
  if expr.tag == "literal" then return expr.num end
  local l, r = interp(expr.lhs), interp(expr.rhs)
  if expr.op == "add" then return l + r end
  if expr.op == "sub" then return l - r end
  if expr.op == "mul" then return l * r end
  if r == 0 then return 0 end
  return (l - math.fmod(l, r)) // r -- truncating, where // alone floors
end

local function lit(n) return { tag = "literal", num = n } end
local function bin(op, l, r) return { tag = "binary", op = op, lhs = l, rhs = r } end

local e = bin("div", bin("mul", bin("sub", lit(7), lit(10)), lit(7)), lit(2))
print(interp(e))
do
  local f = bin("div", bin("add", lit(4), lit(4)), bin("sub", lit(4), lit(4)))
  print(interp(f))
end
print(interp(e))
