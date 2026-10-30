// A protocol with a primary associated type: Ast<Ref> leaves the index type
// open, but a task-local is a static stored property, which can't be generic,
// so the pool comes back through a cast checked at run time, and `Ref` is
// whatever each caller declares it to be (`let e: Idx = ...`).
enum BinOp: Int64 { case add = 1, sub, mul, div } // 0 means a literal.

enum Expr<Ref> {
    case binary(BinOp, Ref, Ref)
    case literal(Int64)
}

protocol Ast<Ref>: AnyObject, Sendable {
    associatedtype Ref
    func add(_ expr: Expr<Ref>) -> Ref
    func get(_ expr: Ref) -> Expr<Ref>
}

enum Context {
    @TaskLocal static var ast: (any Ast)?
}

func ast<Ref>() -> any Ast<Ref> { Context.ast as! any Ast<Ref> }

func interp<Ref>(_ expr: Ref) -> Int64 {
    switch ast().get(expr) {
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

func num<Ref>(_ n: Int64) -> Ref { ast().add(.literal(n)) }
func bin<Ref>(_ op: BinOp, _ l: Ref, _ r: Ref) -> Ref { ast().add(.binary(op, l, r)) }

func node<Ref>(_ op: Int64, _ lhs: Int64, _ rhs: Int64, _ ref: (Int64) -> Ref) -> Expr<Ref> {
    op == 0 ? .literal(lhs) : .binary(BinOp(rawValue: op)!, ref(lhs), ref(rhs))
}

// Representation 1: a node is an index into parallel lists.
struct Idx { let index: Int }

final class Columns: Ast, @unchecked Sendable {
    private var ops: [Int64] = [], lhs: [Int64] = [], rhs: [Int64] = []

    func add(_ expr: Expr<Idx>) -> Idx {
        let (op, l, r): (Int64, Int64, Int64) = switch expr {
        case .binary(let op, let l, let r): (op.rawValue, Int64(l.index), Int64(r.index))
        case .literal(let num): (0, num, 0)
        }
        ops.append(op)
        lhs.append(l)
        rhs.append(r)
        return Idx(index: ops.count - 1)
    }

    func get(_ expr: Idx) -> Expr<Idx> {
        let i = expr.index
        return node(ops[i], lhs[i], rhs[i]) { Idx(index: Int($0)) }
    }
}

// Representation 2: a node is an index into one list of triples.
struct Slot { let index: Int }

final class Triples: Ast, @unchecked Sendable {
    private var triples: [Int64] = []

    func add(_ expr: Expr<Slot>) -> Slot {
        switch expr {
        case .binary(let op, let l, let r): triples += [op.rawValue, Int64(l.index), Int64(r.index)]
        case .literal(let num): triples += [0, num, 0]
        }
        return Slot(index: triples.count / 3 - 1)
    }

    func get(_ expr: Slot) -> Expr<Slot> {
        let i = 3 * expr.index
        return node(triples[i], triples[i + 1], triples[i + 2]) { Slot(index: Int($0)) }
    }
}

Context.$ast.withValue(Columns()) {
    let e: Idx = bin(.div, bin(.mul, bin(.sub, num(7), num(10)), num(7)), num(2))
    print(interp(e))
    Context.$ast.withValue(Triples()) {
        let f: Slot = bin(.div, bin(.add, num(4), num(4)), bin(.sub, num(4), num(4)))
        print(interp(f))
    }
    print(interp(e))
}
