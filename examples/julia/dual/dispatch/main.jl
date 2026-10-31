# Parametric types and multiple dispatch: `Dual{T}` is a subtype of `Real`
# whose operators are methods for any `T`, so duals nest, and promotion rules
# convert any other real to a dual as a constant, so `f` is written once with
# plain literals, and no function names a type. Promotion also decides what
# adding the outer variable as it is (`x + variable(y0)`) does in `nested`:
# with `y0` a dual like `x`, it promotes `x` to a constant of the inner type,
# just as `still(x)` does, and gives the right answer, 1. But `y0` takes its
# type from `oftype(x, 1.0)`, not from where it is used; were it a plain
# `1.0`, both variables would be `Dual{Float64}`, and `x + variable(y0)`
# would silently add their derivatives and give 2 (and even `still(x) +
# variable(y0)` would promote the inner variable to a constant and give 0).
# Julia compiles a specialized method for each combination of types, so
# promotion happens at compile time and nothing dispatches at run time.
struct Dual{T<:Real} <: Real
    v::T
    d::T
end

f(x) = x * x * x - 2.0 * x - 5.0

variable(x) = Dual(x, one(x))
still(x) = Dual(x, zero(x))

# A real becomes a constant dual, and duals of different depths meet at the
# deeper one.
Base.convert(::Type{D}, x::D) where {D<:Dual} = x
Base.convert(::Type{Dual{T}}, x::Real) where {T} = still(convert(T, x))
Base.promote_rule(::Type{Dual{T}}, ::Type{S}) where {T,S<:Real} = Dual{promote_type(T, S)}
Base.promote_rule(::Type{Dual{T}}, ::Type{Dual{S}}) where {T,S} = Dual{promote_type(T, S)}

Base.:+(a::Dual{T}, b::Dual{T}) where {T} = Dual(a.v + b.v, a.d + b.d)
Base.:-(a::Dual{T}, b::Dual{T}) where {T} = Dual(a.v - b.v, a.d - b.d)
Base.:*(a::Dual{T}, b::Dual{T}) where {T} = Dual(a.v * b.v, a.d * b.v + a.v * b.d)
Base.:/(a::Dual{T}, b::Dual{T}) where {T} =
    Dual(a.v / b.v, (a.d * b.v - a.v * b.d) / (b.v * b.v))

# `round` rounds half to even.
show(x) = println(round(Int, x * 1000000.0))

function derivatives(x)
    show(f(x))
    show(f(variable(x)).d)
    show(f(variable(variable(x))).d.d)
end

function newton(x0, steps)
    x = x0
    for _ in 1:steps
        y = f(variable(x))
        x = x - y.v / y.d
        show(x)
    end
end

# d/dx (x * d/dy (x + y)) at x = 1, y = 1.
function nested(at)
    x = variable(at)
    y0 = oftype(x, 1.0)
    inner = (still(x) + variable(y0)).d
    (x * inner).d
end

derivatives(2.0)
newton(2.0, 4)
show(nested(1.0))
