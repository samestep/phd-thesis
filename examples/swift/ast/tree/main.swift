// The tree Sampson starts from: an `indirect` enum boxes its children, so
// nothing needs a pool, but every node is its own reference-counted allocation.
enum BinOp { case add, sub, mul, div }

indirect enum Expr {
    case binary(BinOp, Expr, Expr)
    case literal(Int64)
}

func interp(_ expr: Expr) -> Int64 {
    switch expr {
    case .binary(let op, let lhs, let rhs):
        let l = interp(lhs), r = interp(rhs)
        switch op {
        case .add: return l &+ r
        case .sub: return l &- r
        case .mul: return l &* r
        case .div: return r == 0 ? 0 : l / r
        }
    case .literal(let num): return num
    }
}

func num(_ n: Int64) -> Expr { .literal(n) }
func bin(_ op: BinOp, _ l: Expr, _ r: Expr) -> Expr { .binary(op, l, r) }

let e = bin(.div, bin(.mul, bin(.sub, num(7), num(10)), num(7)), num(2))
print(interp(e))
do {
    let f = bin(.div, bin(.add, num(4), num(4)), bin(.sub, num(4), num(4)))
    print(interp(f))
}
print(interp(e))
