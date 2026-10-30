-- No dynamic scoping: a global, swapped and restored around the inner scope.
pool = {}

local function add(expr) pool[#pool + 1] = expr; return #pool end
local function get(ref) return pool[ref] end

local function interp(ref)
  local expr = get(ref)
  if expr.tag == "literal" then return expr.num end
  local l, r = interp(expr.lhs), interp(expr.rhs)
  if expr.op == "add" then return l + r end
  if expr.op == "sub" then return l - r end
  if expr.op == "mul" then return l * r end
  if r == 0 then return 0 end
  return (l - math.fmod(l, r)) // r -- truncating, where // alone floors
end

local function lit(n) return add { tag = "literal", num = n } end
local function bin(op, l, r) return add { tag = "binary", op = op, lhs = l, rhs = r } end

local function with_pool(p, f)
  local old = pool
  pool = p
  local ok, err = pcall(f)
  pool = old
  assert(ok, err)
end

local e = bin("div", bin("mul", bin("sub", lit(7), lit(10)), lit(7)), lit(2))
print(interp(e))
with_pool({}, function()
  print(interp(bin("div", bin("add", lit(4), lit(4)), bin("sub", lit(4), lit(4)))))
end)
print(interp(e))
