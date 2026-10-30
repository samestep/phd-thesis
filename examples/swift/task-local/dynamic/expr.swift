// A plain protocol: the task-local holds any `Ast`, with no cast, because
// `ExprRef` is fixed once for every representation, so the types no longer
// tell one pool's references from another's.
enum BinOp: Int64 { case add = 1, sub, mul, div } // 0 means a literal.

struct ExprRef { let index: Int }

enum Expr {
    case binary(BinOp, ExprRef, ExprRef)
    case literal(Int64)
}

protocol Ast: AnyObject, Sendable {
    func add(_ expr: Expr) -> ExprRef
    func get(_ expr: ExprRef) -> Expr
}

enum Context {
    @TaskLocal static var ast: (any Ast)?
}

func interp(_ expr: ExprRef) -> Int64 {
    switch Context.ast!.get(expr) {
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

func num(_ n: Int64) -> ExprRef { Context.ast!.add(.literal(n)) }
func bin(_ op: BinOp, _ l: ExprRef, _ r: ExprRef) -> ExprRef { Context.ast!.add(.binary(op, l, r)) }

func node(_ op: Int64, _ lhs: Int64, _ rhs: Int64) -> Expr {
    op == 0 ? .literal(lhs) : .binary(BinOp(rawValue: op)!, ExprRef(index: Int(lhs)), ExprRef(index: Int(rhs)))
}

// Representation 1: a node is an index into parallel lists.
final class Columns: Ast, @unchecked Sendable {
    private var ops: [Int64] = [], lhs: [Int64] = [], rhs: [Int64] = []

    func add(_ expr: Expr) -> ExprRef {
        let (op, l, r): (Int64, Int64, Int64) = switch expr {
        case .binary(let op, let l, let r): (op.rawValue, Int64(l.index), Int64(r.index))
        case .literal(let num): (0, num, 0)
        }
        ops.append(op)
        lhs.append(l)
        rhs.append(r)
        return ExprRef(index: ops.count - 1)
    }

    func get(_ expr: ExprRef) -> Expr {
        let i = expr.index
        return node(ops[i], lhs[i], rhs[i])
    }
}

// Representation 2: a node is an index into one list of triples.
final class Triples: Ast, @unchecked Sendable {
    private var triples: [Int64] = []

    func add(_ expr: Expr) -> ExprRef {
        switch expr {
        case .binary(let op, let l, let r): triples += [op.rawValue, Int64(l.index), Int64(r.index)]
        case .literal(let num): triples += [0, num, 0]
        }
        return ExprRef(index: triples.count / 3 - 1)
    }

    func get(_ expr: ExprRef) -> Expr {
        let i = 3 * expr.index
        return node(triples[i], triples[i + 1], triples[i + 2])
    }
}

Context.$ast.withValue(Columns()) {
    let e = bin(.div, bin(.mul, bin(.sub, num(7), num(10)), num(7)), num(2))
    print(interp(e))
    Context.$ast.withValue(Triples()) {
        print(interp(bin(.div, bin(.add, num(4), num(4)), bin(.sub, num(4), num(4)))))
    }
    print(interp(e))
}
