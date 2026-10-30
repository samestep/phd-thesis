# Fiber storage, rebound for the duration of a block.
Binary = Struct.new(:op, :lhs, :rhs)
Literal = Struct.new(:num)

def with_pool(pool)
  old, Fiber[:pool] = Fiber[:pool], pool
  yield
ensure
  Fiber[:pool] = old
end

def add(expr) = (Fiber[:pool] << expr).size - 1
def get(ref) = Fiber[:pool][ref]

def interp(ref)
  case get(ref)
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

def lit(n) = add(Literal[n])
def bin(op, l, r) = add(Binary[op, l, r])

with_pool([]) do
  e = bin(:div, bin(:mul, bin(:sub, lit(7), lit(10)), lit(7)), lit(2))
  puts interp(e)
  with_pool([]) { puts interp(bin(:div, bin(:add, lit(4), lit(4)), bin(:sub, lit(4), lit(4)))) }
  puts interp(e)
end
