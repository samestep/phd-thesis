# The tree Sampson starts from: each node holds references to its children,
# so nothing needs a pool, and the GC reclaims nodes nobody points to.
@enum BinOp Add Sub Mul Div

abstract type Expr end
struct Binary <: Expr
    op::BinOp
    lhs::Expr
    rhs::Expr
end
struct Literal <: Expr
    num::Int
end

interp(expr::Literal) = expr.num
function interp(expr::Binary)
    l, r = interp(expr.lhs), interp(expr.rhs)
    expr.op == Add ? l + r :
    expr.op == Sub ? l - r :
    expr.op == Mul ? l * r :
    r == 0 ? 0 : div(l, r)
end

lit(n) = Literal(n)
bin(op, l, r) = Binary(op, l, r)

let
    e = bin(Div, bin(Mul, bin(Sub, lit(7), lit(10)), lit(7)), lit(2))
    println(interp(e))
    let
        f = bin(Div, bin(Add, lit(4), lit(4)), bin(Sub, lit(4), lit(4)))
        println(interp(f))
    end
    println(interp(e))
end
