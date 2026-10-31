// The tree Sampson starts from: each node holds its children directly, and
// the garbage collector frees them, so nothing needs a pool.
enum BinOp {
    case Add,
    case Sub,
    case Mul,
    case Div
}

enum Expr {
    case Binary(BinOp, Expr, Expr),
    case Literal(Int32)
}

def interp(e: Expr): Int32 = match e {
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

def lit(n: Int32): Expr = Expr.Literal(n)
def bin(op: BinOp, l: Expr, r: Expr): Expr = Expr.Binary(op, l, r)

def main(): Unit \ IO = {
    let e = bin(BinOp.Div, bin(BinOp.Mul, bin(BinOp.Sub, lit(7), lit(10)), lit(7)), lit(2));
    println(interp(e));
    {
        let f = bin(BinOp.Div, bin(BinOp.Add, lit(4), lit(4)), bin(BinOp.Sub, lit(4), lit(4)));
        println(interp(f))
    };
    println(interp(e))
}
