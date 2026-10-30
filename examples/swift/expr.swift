// @TaskLocal: `withValue` binds the pool for the duration of a closure.
enum BinOp { case add, sub, mul, div }

struct ExprRef { let index: Int }

enum Expr {
    case binary(BinOp, ExprRef, ExprRef)
    case literal(Int64)
}

final class ExprPool: @unchecked Sendable {
    private var exprs: [Expr] = []

    func add(_ expr: Expr) -> ExprRef {
        exprs.append(expr)
        return ExprRef(index: exprs.count - 1)
    }

    func get(_ expr: ExprRef) -> Expr { exprs[expr.index] }
}

enum Context {
    @TaskLocal static var pool = ExprPool()
}

func interp(_ expr: ExprRef) -> Int64 {
    switch Context.pool.get(expr) {
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

func num(_ n: Int64) -> ExprRef { Context.pool.add(.literal(n)) }
func bin(_ op: BinOp, _ l: ExprRef, _ r: ExprRef) -> ExprRef { Context.pool.add(.binary(op, l, r)) }

Context.$pool.withValue(ExprPool()) {
    let e = bin(.div, bin(.mul, bin(.sub, num(7), num(10)), num(7)), num(2))
    print(interp(e))
    Context.$pool.withValue(ExprPool()) {
        print(interp(bin(.div, bin(.add, num(4), num(4)), bin(.sub, num(4), num(4)))))
    }
    print(interp(e))
}
