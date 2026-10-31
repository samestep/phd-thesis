app [main!] { pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.20.0/X73hGh05nNTkDHU06FHC0YfFaQB1pimX7gncRcao5mU.tar.br" }

# Module params over the representation: `Build` and `Interp` take the
# representation's functions as params (and `Interp` the pool too), so each
# import picks one. A module's params can't be annotated, nor can its own
# definitions mention their types, so the interface is never written down,
# only inferred per import; abilities can't state it either, since one can't
# tie a pool type to its index type.

import pf.Stdout
import Columns
import Triples
import Build { empty: Columns.empty, add: Columns.add } as C

a = C.build(C.bin(Div, C.bin(Mul, C.bin(Sub, C.lit(7), C.lit(10)), C.lit(7)), C.lit(2)))

import Interp { pool: a.pool, get: Columns.get } as A

elsewhere =
    import Build { empty: Triples.empty, add: Triples.add } as T
    b = T.build(T.bin(Div, T.bin(Add, T.lit(4), T.lit(4)), T.bin(Sub, T.lit(4), T.lit(4))))
    import Interp { pool: b.pool, get: Triples.get } as B
    B.interp(b.ref)

main! = |_args|
    Stdout.line!(Num.to_str(A.interp(a.ref)))?
    Stdout.line!(Num.to_str(elsewhere))?
    Stdout.line!(Num.to_str(A.interp(a.ref)))
