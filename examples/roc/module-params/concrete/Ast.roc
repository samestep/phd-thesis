module [BinOp, ExprRef, Expr, ExprPool, Builder, get, lit, bin, build]

BinOp : [Add, Sub, Mul, Div]

ExprRef := U64

Expr : [Binary BinOp ExprRef ExprRef, Literal I64]

ExprPool := List Expr

get : ExprPool, ExprRef -> Expr
get = |@ExprPool(exprs), @ExprRef(i)|
    when List.get(exprs, i) is
        Ok(expr) -> expr
        Err(OutOfBounds) -> crash "dangling ExprRef"

## A pool is a value like any other, so adding a node makes a new one.
Builder : ExprPool -> { pool : ExprPool, ref : ExprRef }

add : ExprPool, Expr -> { pool : ExprPool, ref : ExprRef }
add = |@ExprPool(exprs), expr|
    { pool: @ExprPool(List.append(exprs, expr)), ref: @ExprRef(List.len(exprs)) }

lit : I64 -> Builder
lit = |n| |pool| add(pool, Literal(n))

bin : BinOp, Builder, Builder -> Builder
bin = |op, lhs, rhs|
    |pool|
        l = lhs(pool)
        r = rhs(l.pool)
        add(r.pool, Binary(op, l.ref, r.ref))

build : Builder -> { pool : ExprPool, ref : ExprRef }
build = |builder| builder(@ExprPool([]))
