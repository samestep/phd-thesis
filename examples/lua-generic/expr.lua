-- Duck typing: the global holds any table with `add` and `get`, and its
-- references can be anything at all.
ast = nil

local function interp(ref)
  local expr = ast:get(ref)
  if expr.tag == "literal" then return expr.num end
  local l, r = interp(expr.lhs), interp(expr.rhs)
  if expr.op == "add" then return l + r end
  if expr.op == "sub" then return l - r end
  if expr.op == "mul" then return l * r end
  if r == 0 then return 0 end
  return (l - math.fmod(l, r)) // r -- truncating, where // alone floors
end

local function lit(n) return ast:add { tag = "literal", num = n } end
local function bin(op, l, r) return ast:add { tag = "binary", op = op, lhs = l, rhs = r } end

local ops = { "add", "sub", "mul", "div" } -- 0 is a literal
local code = {}
for i, op in ipairs(ops) do code[op] = i end

local function encode(expr)
  if expr.tag == "literal" then return 0, expr.num, 0 end
  return code[expr.op], expr.lhs.i, expr.rhs.i
end

local function decode(ref, op, l, r)
  if op == 0 then return { tag = "literal", num = l } end
  return { tag = "binary", op = ops[op], lhs = ref(l), rhs = ref(r) }
end

-- Representation 1: a node is an index into parallel lists.
local function Idx(i) return { i = i } end

local Columns = {}
Columns.__index = Columns

function Columns.new() return setmetatable({ ops = {}, lhs = {}, rhs = {} }, Columns) end

function Columns:add(expr)
  local i = #self.ops + 1
  self.ops[i], self.lhs[i], self.rhs[i] = encode(expr)
  return Idx(i)
end

function Columns:get(ref)
  local i = ref.i
  return decode(Idx, self.ops[i], self.lhs[i], self.rhs[i])
end

-- Representation 2: a node is an index into one list of triples.
local function Slot(i) return { i = i } end

local Triples = {}
Triples.__index = Triples

function Triples.new() return setmetatable({}, Triples) end

function Triples:add(expr)
  local op, l, r = encode(expr)
  table.move({ op, l, r }, 1, 3, #self + 1, self)
  return Slot(#self // 3)
end

function Triples:get(ref)
  return decode(Slot, table.unpack(self, 3 * ref.i - 2, 3 * ref.i))
end

local function with_ast(a, f)
  local old = ast
  ast = a
  local ok, err = pcall(f)
  ast = old
  assert(ok, err)
end

ast = Columns.new()
local e = bin("div", bin("mul", bin("sub", lit(7), lit(10)), lit(7)), lit(2))
print(interp(e))
with_ast(Triples.new(), function()
  print(interp(bin("div", bin("add", lit(4), lit(4)), bin("sub", lit(4), lit(4)))))
end)
print(interp(e))
