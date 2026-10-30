# Parametric types and multiple dispatch: `Expr{R}` is parameterized by the
# reference type and each representation's methods are picked by it, but a
# ScopedValue has one declared type, so it holds an abstract `Ast` and every
# access dispatches (and checks `R`) at run time.
using Base.ScopedValues

@enum BinOp Add = 1 Sub Mul Div

struct Binary{R}
    op::BinOp
    lhs::R
    rhs::R
end
struct Literal
    num::Int
end
const Expr{R} = Union{Binary{R},Literal}

# A subtype of `Ast{R}` has methods `add!(ast, ::Expr{R})::R` and
# `getexpr(ast, ::R)::Expr{R}`.
abstract type Ast{R} end

const ast = ScopedValue{Ast}()

function interp(ref)
    expr = getexpr(ast[], ref)
    expr isa Literal && return expr.num
    l, r = interp(expr.lhs), interp(expr.rhs)
    expr.op == Add ? l + r :
    expr.op == Sub ? l - r :
    expr.op == Mul ? l * r :
    r == 0 ? 0 : div(l, r)
end

lit(n) = add!(ast[], Literal(n))
bin(op, l, r) = add!(ast[], Binary(op, l, r))

# A row of three ints; op code 0 is a literal.
encode(expr::Literal) = (0, expr.num, 0)
encode(expr::Binary) = (Int(expr.op), expr.lhs.i, expr.rhs.i)
decode(R, op, l, r) = op == 0 ? Literal(l) : Binary(BinOp(op), R(l), R(r))

# Representation 1: a node is an index into parallel lists.
struct Idx
    i::Int
end

struct Columns <: Ast{Idx}
    ops::Vector{Int}
    lhs::Vector{Int}
    rhs::Vector{Int}
end
Columns() = Columns([], [], [])

function add!(c::Columns, expr::Expr{Idx})
    foreach(push!, (c.ops, c.lhs, c.rhs), encode(expr))
    Idx(length(c.ops))
end

getexpr(c::Columns, (; i)::Idx) = decode(Idx, c.ops[i], c.lhs[i], c.rhs[i])

# Representation 2: a node is an index into one list of triples.
struct Slot
    i::Int
end

struct Triples <: Ast{Slot}
    triples::Vector{Int}
end
Triples() = Triples([])

function add!(t::Triples, expr::Expr{Slot})
    append!(t.triples, encode(expr))
    Slot(length(t.triples) ÷ 3)
end

getexpr(t::Triples, (; i)::Slot) = decode(Slot, t.triples[3i-2:3i]...)

with(ast => Columns()) do
    e = bin(Div, bin(Mul, bin(Sub, lit(7), lit(10)), lit(7)), lit(2))
    println(interp(e))
    with(ast => Triples()) do
        println(interp(bin(Div, bin(Add, lit(4), lit(4)), bin(Sub, lit(4), lit(4)))))
    end
    println(interp(e))
end
