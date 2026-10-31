# A ScopedValue, rebound with `with`.
using Base.ScopedValues

@enum BinOp Add Sub Mul Div
const ExprRef = Int

struct Binary
    op::BinOp
    lhs::ExprRef
    rhs::ExprRef
end
struct Literal
    num::Int
end
const Expr = Union{Binary,Literal}

const pool = ScopedValue{Vector{Expr}}()

add!(expr) = (push!(pool[], expr); length(pool[]))
getexpr(ref) = pool[][ref]

function interp(ref)
    expr = getexpr(ref)
    expr isa Literal && return expr.num
    l, r = interp(expr.lhs), interp(expr.rhs)
    expr.op == Add ? l + r :
    expr.op == Sub ? l - r :
    expr.op == Mul ? l * r :
    r == 0 ? 0 : div(l, r)
end

lit(n) = add!(Literal(n))
bin(op, l, r) = add!(Binary(op, l, r))

with(pool => Expr[]) do
    e = bin(Div, bin(Mul, bin(Sub, lit(7), lit(10)), lit(7)), lit(2))
    println(interp(e))
    with(pool => Expr[]) do
        println(interp(bin(Div, bin(Add, lit(4), lit(4)), bin(Sub, lit(4), lit(4)))))
    end
    println(interp(e))
end
