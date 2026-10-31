## Representation 1: a node is an index into parallel lists.
module [Columns, Idx, empty, add, get]

import Ast exposing [Expr]

Idx := U64

Columns := { ops : List I64, lhs : List I64, rhs : List I64 }

empty : Columns
empty = @Columns({ ops: [], lhs: [], rhs: [] })

add : Columns, Expr Idx -> { pool : Columns, ref : Idx }
add = |@Columns({ ops, lhs, rhs }), expr|
    (op, l, r) =
        when expr is
            Binary(o, @Idx(i), @Idx(j)) -> (Ast.code(o), Num.to_i64(i), Num.to_i64(j))
            Literal(num) -> (0, num, 0)
    pool = @Columns(
        {
            ops: List.append(ops, op),
            lhs: List.append(lhs, l),
            rhs: List.append(rhs, r),
        },
    )
    { pool, ref: @Idx(List.len(ops)) }

get : Columns, Idx -> Expr Idx
get = |@Columns({ ops, lhs, rhs }), @Idx(i)|
    when at(ops, i) is
        0 -> Literal(at(lhs, i))
        op -> Binary(Ast.op_of(op), @Idx(Num.to_u64(at(lhs, i))), @Idx(Num.to_u64(at(rhs, i))))

at = |list, i|
    when List.get(list, i) is
        Ok(x) -> x
        Err(OutOfBounds) -> crash "dangling Idx"
