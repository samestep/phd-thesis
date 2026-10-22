-- No dynamic scoping: a global, swapped and restored around the inner scope.
pool = {}

local function node(n) pool[#pool + 1] = n; return #pool end
local function lit(n) return node { "lit", n } end
local function add(l, r) return node { "add", l, r } end
local function mul(l, r) return node { "mul", l, r } end

local function ev(e)
  local op, a, b = table.unpack(pool[e])
  if op == "lit" then return a end
  if op == "add" then return ev(a) + ev(b) end
  return ev(a) * ev(b)
end

local function with_pool(p, f)
  local old = pool
  pool = p
  local ok, err = pcall(f)
  pool = old
  assert(ok, err)
end

local e = mul(add(lit(1), lit(2)), add(lit(3), lit(4)))
print(ev(e))
with_pool({}, function() print(ev(add(lit(4), lit(4)))) end)
print(ev(e))
