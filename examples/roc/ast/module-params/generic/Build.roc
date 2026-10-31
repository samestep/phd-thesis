module { empty, add } -> [lit, bin, build]

## Adding a node to a pool makes a new pool, so a builder threads it through.
lit = |n| |pool| add(pool, Literal(n))

bin = |op, lhs, rhs|
    |pool|
        l = lhs(pool)
        r = rhs(l.pool)
        add(r.pool, Binary(op, l.ref, r.ref))

build = |builder| builder(empty)
