# The tree Sampson starts from: each node holds references to its children,
# so nothing needs a pool, but every node is its own heap object.
Binary = Struct.new(:op, :lhs, :rhs)
Literal = Struct.new(:num)

def interp(expr)
  case expr
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

def lit(n) = Literal[n]
def bin(op, l, r) = Binary[op, l, r]

e = bin(:div, bin(:mul, bin(:sub, lit(7), lit(10)), lit(7)), lit(2))
puts interp(e)
begin
  f = bin(:div, bin(:add, lit(4), lit(4)), bin(:sub, lit(4), lit(4)))
  puts interp(f)
end
puts interp(e)
