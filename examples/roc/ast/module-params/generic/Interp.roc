module { pool, get } -> [interp]

interp = |expr|
    when get(pool, expr) is
        Binary(op, lhs, rhs) ->
            l = interp(lhs)
            r = interp(rhs)
            when op is
                Add -> l + r
                Sub -> l - r
                Mul -> l * r
                Div -> if r == 0 then 0 else Num.div_trunc(l, r)

        Literal(num) -> num
