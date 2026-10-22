// @TaskLocal: `withValue` binds the pool for the duration of a closure.
enum Node {
    case lit(Int)
    case add(Int, Int)
    case mul(Int, Int)
}

final class Pool: @unchecked Sendable {
    var nodes: [Node] = []
}

enum Context {
    @TaskLocal static var pool = Pool()
}

func push(_ node: Node) -> Int {
    Context.pool.nodes.append(node)
    return Context.pool.nodes.count - 1
}

func lit(_ n: Int) -> Int { push(.lit(n)) }
func add(_ l: Int, _ r: Int) -> Int { push(.add(l, r)) }
func mul(_ l: Int, _ r: Int) -> Int { push(.mul(l, r)) }

func eval(_ e: Int) -> Int {
    switch Context.pool.nodes[e] {
    case .lit(let n): n
    case .add(let l, let r): eval(l) + eval(r)
    case .mul(let l, let r): eval(l) * eval(r)
    }
}

Context.$pool.withValue(Pool()) {
    let e = mul(add(lit(1), lit(2)), add(lit(3), lit(4)))
    print(eval(e))
    Context.$pool.withValue(Pool()) {
        print(eval(add(lit(4), lit(4))))
    }
    print(eval(e))
}
