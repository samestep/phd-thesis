app [main!] { pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.20.0/X73hGh05nNTkDHU06FHC0YfFaQB1pimX7gncRcao5mU.tar.br" }

# The tree Sampson starts from: a recursive tag union, whose nodes Roc
# allocates on the heap and reference-counts, so nothing needs a pool.

import pf.Stdout

BinOp : [Add, Sub, Mul, Div]

Expr : [Binary BinOp Expr Expr, Literal I64]

interp : Expr -> I64
interp = |expr|
    when expr is
        Binary(op, lhs, rhs) ->
            l = interp(lhs)
            r = interp(rhs)
            when op is
                Add -> l + r
                Sub -> l - r
                Mul -> l * r
                Div -> if r == 0 then 0 else Num.div_trunc(l, r)

        Literal(num) -> num

lit : I64 -> Expr
lit = |n| Literal(n)

bin : BinOp, Expr, Expr -> Expr
bin = |op, lhs, rhs| Binary(op, lhs, rhs)

main! = |_args|
    e = bin(Div, bin(Mul, bin(Sub, lit(7), lit(10)), lit(7)), lit(2))
    Stdout.line!(Num.to_str(interp(e)))?
    f = bin(Div, bin(Add, lit(4), lit(4)), bin(Sub, lit(4), lit(4)))
    Stdout.line!(Num.to_str(interp(f)))?
    Stdout.line!(Num.to_str(interp(e)))
