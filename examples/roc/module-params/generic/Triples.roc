## Representation 2: a node is an index into one list of triples.
module [Triples, Slot, empty, add, get]

import Ast exposing [Expr]

Slot := U64

Triples := List I64

empty : Triples
empty = @Triples([])

add : Triples, Expr Slot -> { pool : Triples, ref : Slot }
add = |@Triples(triples), expr|
    triple =
        when expr is
            Binary(op, @Slot(l), @Slot(r)) -> [Ast.code(op), Num.to_i64(l), Num.to_i64(r)]
            Literal(num) -> [0, num, 0]
    { pool: @Triples(List.concat(triples, triple)), ref: @Slot(List.len(triples) // 3) }

get : Triples, Slot -> Expr Slot
get = |@Triples(triples), @Slot(i)|
    at = |k|
        when List.get(triples, 3 * i + k) is
            Ok(x) -> x
            Err(OutOfBounds) -> crash "dangling Slot"
    when at(0) is
        0 -> Literal(at(1))
        op -> Binary(Ast.op_of(op), @Slot(Num.to_u64(at(1))), @Slot(Num.to_u64(at(2))))
