app [main!] { pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.20.0/X73hGh05nNTkDHU06FHC0YfFaQB1pimX7gncRcao5mU.tar.br" }

# Module params: `Interp` takes the pool as a parameter, which each import
# supplies, so the same module is imported once per pool. A param is a value,
# so building has to thread the pool by hand; and alpha4 won't compile an
# import inside a function, so each pool is built in a top-level definition.

import pf.Stdout
import Ast exposing [lit, bin]

a = Ast.build(bin(Div, bin(Mul, bin(Sub, lit(7), lit(10)), lit(7)), lit(2)))

import Interp { pool: a.pool } as A

elsewhere =
    b = Ast.build(bin(Div, bin(Add, lit(4), lit(4)), bin(Sub, lit(4), lit(4))))
    import Interp { pool: b.pool } as B
    B.interp(b.ref)

main! = |_args|
    Stdout.line!(Num.to_str(A.interp(a.ref)))?
    Stdout.line!(Num.to_str(elsewhere))?
    Stdout.line!(Num.to_str(A.interp(a.ref)))
