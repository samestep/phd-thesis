// The pool is an effect; `withPool` handles it for one computation.
enum Node {
    case Lit(Int32),
    case Add(Int32, Int32),
    case Mul(Int32, Int32)
}

eff Pool {
    def push(n: Node): Int32
    def get(i: Int32): Node
}

def lit(n: Int32): Int32 \ Pool = Pool.push(Node.Lit(n))
def add(l: Int32, r: Int32): Int32 \ Pool = Pool.push(Node.Add(l, r))
def mul(l: Int32, r: Int32): Int32 \ Pool = Pool.push(Node.Mul(l, r))

def eval(e: Int32): Int32 \ Pool = match Pool.get(e) {
    case Node.Lit(n)    => n
    case Node.Add(l, r) => eval(l) + eval(r)
    case Node.Mul(l, r) => eval(l) * eval(r)
}

def withPool(f: Unit -> a \ ef): a \ (ef - Pool) = region rc {
    let nodes = MutList.empty(rc);
    run f() with handler Pool {
        def push(n, k) = { MutList.push(n, nodes); k(MutList.size(nodes) - 1) }
        def get(i, k) = k(MutList.get(i, nodes))
    }
}

def main(): Unit \ IO = withPool(() -> {
    let e = mul(add(lit(1), lit(2)), add(lit(3), lit(4)));
    println(eval(e));
    withPool(() -> println(eval(add(lit(4), lit(4)))));
    println(eval(e))
})
