# Fiber storage, rebound for the duration of a block.
def with_pool(pool)
  old, Fiber[:pool] = Fiber[:pool], pool
  yield
ensure
  Fiber[:pool] = old
end

def node(*n) = (Fiber[:pool] << n).size - 1
def lit(n) = node(:lit, n)
def add(l, r) = node(:add, l, r)
def mul(l, r) = node(:mul, l, r)

def ev(e)
  case Fiber[:pool][e]
  in [:lit, n] then n
  in [:add, l, r] then ev(l) + ev(r)
  in [:mul, l, r] then ev(l) * ev(r)
  end
end

with_pool([]) do
  e = mul(add(lit(1), lit(2)), add(lit(3), lit(4)))
  puts ev(e)
  with_pool([]) { puts ev(add(lit(4), lit(4))) }
  puts ev(e)
end
