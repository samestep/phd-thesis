module [BinOp, Expr, code, op_of]

BinOp : [Add, Sub, Mul, Div]

Expr ref : [Binary BinOp ref ref, Literal I64]

code : BinOp -> I64
code = |op|
    when op is
        Add -> 1
        Sub -> 2
        Mul -> 3
        Div -> 4

op_of : I64 -> BinOp
op_of = |c|
    when c is
        1 -> Add
        2 -> Sub
        3 -> Mul
        _ -> Div
