// The pool is an effect; `withPool` handles it for one computation.
enum BinOp {
    case Add,
    case Sub,
    case Mul,
    case Div
}

enum Expr {
    case Binary(BinOp, Int32, Int32),
    case Literal(Int32)
}

eff ExprPool {
    def add(e: Expr): Int32
    def get(r: Int32): Expr
}

def interp(e: Int32): Int32 \ ExprPool = match ExprPool.get(e) {
    case Expr.Binary(op, lhs, rhs) =>
        let l = interp(lhs);
        let r = interp(rhs);
        match op {
            case BinOp.Add => l + r
            case BinOp.Sub => l - r
            case BinOp.Mul => l * r
            case BinOp.Div => if (r == 0) 0 else l / r
        }
    case Expr.Literal(num) => num
}

def withPool(f: Unit -> a \ ef): a \ (ef - ExprPool) = region rc {
    let nodes = MutList.empty(rc);
    run f() with handler ExprPool {
        def add(e, k) = { MutList.push(e, nodes); k(MutList.size(nodes) - 1) }
        def get(i, k) = k(MutList.get(i, nodes))
    }
}

def lit(n: Int32): Int32 \ ExprPool = ExprPool.add(Expr.Literal(n))
def bin(op: BinOp, l: Int32, r: Int32): Int32 \ ExprPool = ExprPool.add(Expr.Binary(op, l, r))

def main(): Unit \ IO = withPool(() -> {
    let e = bin(BinOp.Div, bin(BinOp.Mul, bin(BinOp.Sub, lit(7), lit(10)), lit(7)), lit(2));
    println(interp(e));
    withPool(() -> println(interp(bin(BinOp.Div, bin(BinOp.Add, lit(4), lit(4)), bin(BinOp.Sub, lit(4), lit(4))))));
    println(interp(e))
})
