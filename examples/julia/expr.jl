# A ScopedValue, rebound with `with`.
using Base.ScopedValues

const pool = ScopedValue{Vector{Tuple}}()

node(n...) = (push!(pool[], n); length(pool[]))
lit(n) = node(:lit, n)
add(l, r) = node(:add, l, r)
mul(l, r) = node(:mul, l, r)

function ev(e)
    op, a, b... = pool[][e]
    op == :lit ? a : op == :add ? ev(a) + ev(b[1]) : ev(a) * ev(b[1])
end

with(pool => Tuple[]) do
    e = mul(add(lit(1), lit(2)), add(lit(3), lit(4)))
    println(ev(e))
    with(pool => Tuple[]) do
        println(ev(add(lit(4), lit(4))))
    end
    println(ev(e))
end
