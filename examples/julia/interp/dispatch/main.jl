# Parametric types and multiple dispatch: the pool is a value whose type picks
# its methods, and `Expr{R}` is parameterized by its reference type, but the
# arithmetic and the tracer are types that aren't the type of any argument,
# so `interp` and `report` take both (`interp(pool, V, T, e)`) and pass them
# on; a `Traced` node calls `interp(pool, V, Loud, inner)`. Each arithmetic
# is a wrapper type, since Int32's own `/` returns a float. Julia compiles a
# specialized method for each combination of types, so nothing dispatches at
# run time.
@enum BinOp Add = 1 Sub Mul Div

struct Binary{R}
    op::BinOp
    lhs::R
    rhs::R
end
struct Literal
    n::Int32
end
# Evaluate the inner expression with tracing on.
struct Traced{R}
    inner::R
end
const Expr{R} = Union{Binary{R},Literal,Traced{R}}

# The pool: a method `node(pool, ::R)::Expr{R}` to read a node through a
# reference, and `add!(pool, ::Expr{R})::R` to make one.

# The arithmetic of the interpreted language: a value type `V` with a
# constructor `V(n)` for a literal, the operators `+ - * /`, and
# `print_value(::V)`.

# Called with every intermediate value.
struct Quiet end
struct Loud end

trace(::Type{Quiet}, v) = nothing
function trace(::Type{Loud}, v)
    print("  ")
    print_value(v)
end

# Written once, against the methods alone.
function interp(pool, ::Type{V}, ::Type{T}, e) where {V,T}
    expr = node(pool, e)
    v = if expr isa Binary
        l, r = interp(pool, V, T, expr.lhs), interp(pool, V, T, expr.rhs)
        expr.op == Add ? l + r :
        expr.op == Sub ? l - r :
        expr.op == Mul ? l * r :
        l / r
    elseif expr isa Literal
        V(expr.n)
    else
        interp(pool, V, Loud, expr.inner)
    end
    trace(T, v)
    v
end

report(pool, ::Type{V}, ::Type{T}, e) where {V,T} = print_value(interp(pool, V, T, e))

lit(pool, n) = add!(pool, Literal(n))
bin(pool, op, lhs, rhs) = add!(pool, Binary(op, lhs, rhs))
traced(pool, inner) = add!(pool, Traced(inner))

# A pool: a node is an index into one list of triples.
struct Slot
    i::Int
end

struct Triples
    triples::Vector{Int32}
end
Triples() = Triples([])

function node(pool::Triples, (; i)::Slot)
    code, a, b = pool.triples[3i-2:3i]
    code == 0 ? Literal(a) :
    code == 5 ? Traced(Slot(a)) :
    Binary(BinOp(code), Slot(a), Slot(b))
end

encode(expr::Binary{Slot}) = (Int(expr.op), expr.lhs.i, expr.rhs.i)
encode(expr::Literal) = (0, expr.n, 0)
encode(expr::Traced{Slot}) = (5, expr.inner.i, 0)

function add!(pool::Triples, expr::Expr{Slot})
    append!(pool.triples, encode(expr))
    Slot(length(pool.triples) ÷ 3)
end

# Three meanings for the interpreted language's arithmetic.
struct Wrapping
    n::Int32
end
# Int32 arithmetic wraps, and `÷` truncates toward zero.
Base.:+(l::Wrapping, r::Wrapping) = Wrapping(l.n + r.n)
Base.:-(l::Wrapping, r::Wrapping) = Wrapping(l.n - r.n)
Base.:*(l::Wrapping, r::Wrapping) = Wrapping(l.n * r.n)
Base.:/(l::Wrapping, r::Wrapping) = Wrapping(l.n ÷ r.n)
print_value(v::Wrapping) = println(v.n)

struct Saturating
    n::Int32
end
# A Float64 holds every Int32 sum, difference and quotient exactly enough,
# and every product below 2^53, so convert, compute, truncate and clamp.
saturate(x) = Saturating(clamp(trunc(x), typemin(Int32), typemax(Int32)))
Base.:+(l::Saturating, r::Saturating) = saturate(Float64(l.n) + Float64(r.n))
Base.:-(l::Saturating, r::Saturating) = saturate(Float64(l.n) - Float64(r.n))
Base.:*(l::Saturating, r::Saturating) = saturate(Float64(l.n) * Float64(r.n))
Base.:/(l::Saturating, r::Saturating) = saturate(Float64(l.n) / Float64(r.n))
print_value(v::Saturating) = println(v.n)

struct Floating
    x::Float64
end
Base.:+(l::Floating, r::Floating) = Floating(l.x + r.x)
Base.:-(l::Floating, r::Floating) = Floating(l.x - r.x)
Base.:*(l::Floating, r::Floating) = Floating(l.x * r.x)
Base.:/(l::Floating, r::Floating) = Floating(l.x / r.x)
# `round` rounds ties to even.
print_value(v::Floating) = println(round(Int32, v.x))

let pool = Triples()
    # 50000 * 50000 / 100000 + traced((7 - 10) * 7 / 8)
    big = bin(pool, Div, bin(pool, Mul, lit(pool, 50000), lit(pool, 50000)), lit(pool, 100000))
    diff = bin(pool, Sub, lit(pool, 7), lit(pool, 10))
    small = bin(pool, Div, bin(pool, Mul, diff, lit(pool, 7)), lit(pool, 8))
    e = bin(pool, Add, big, traced(pool, small))
    report(pool, Wrapping, Quiet, e)
    report(pool, Saturating, Quiet, e)
    report(pool, Floating, Quiet, e)
end
