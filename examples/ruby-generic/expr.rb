# Duck typing: fiber storage holds any object with `add` and `get`, and its
# references can be anything at all.
Binary = Struct.new(:op, :lhs, :rhs)
Literal = Struct.new(:num)

def with_ast(ast)
  old, Fiber[:ast] = Fiber[:ast], ast
  yield
ensure
  Fiber[:ast] = old
end

def interp(ref)
  case Fiber[:ast].get(ref)
  in Binary[op, lhs, rhs]
    l, r = interp(lhs), interp(rhs)
    case op
    in :add then l + r
    in :sub then l - r
    in :mul then l * r
    in :div then r.zero? ? 0 : l.quo(r).truncate
    end
  in Literal[num] then num
  end
end

def lit(n) = Fiber[:ast].add(Literal[n])
def bin(op, l, r) = Fiber[:ast].add(Binary[op, l, r])

OPS = [nil, :add, :sub, :mul, :div] # 0 is a literal

# Representation 1: a node is an index into parallel lists.
Idx = Data.define(:i)

class Columns
  def initialize
    @ops, @lhs, @rhs = [], [], []
  end

  def add(expr)
    row = case expr
          in Binary[op, Idx[l], Idx[r]] then [OPS.index(op), l, r]
          in Literal[num] then [0, num, 0]
          end
    [@ops, @lhs, @rhs].zip(row) { |column, x| column << x }
    Idx[@ops.size - 1]
  end

  def get(ref)
    i = ref.i
    return Literal[@lhs[i]] if @ops[i].zero?
    Binary[OPS[@ops[i]], Idx[@lhs[i]], Idx[@rhs[i]]]
  end
end

# Representation 2: a node is an index into one list of triples.
Slot = Data.define(:i)

class Triples
  def initialize = @triples = []

  def add(expr)
    case expr
    in Binary[op, Slot[l], Slot[r]] then @triples.push(OPS.index(op), l, r)
    in Literal[num] then @triples.push(0, num, 0)
    end
    Slot[@triples.size / 3 - 1]
  end

  def get(ref)
    op, l, r = @triples[3 * ref.i, 3]
    op.zero? ? Literal[l] : Binary[OPS[op], Slot[l], Slot[r]]
  end
end

with_ast(Columns.new) do
  e = bin(:div, bin(:mul, bin(:sub, lit(7), lit(10)), lit(7)), lit(2))
  puts interp(e)
  with_ast(Triples.new) { puts interp(bin(:div, bin(:add, lit(4), lit(4)), bin(:sub, lit(4), lit(4)))) }
  puts interp(e)
end
