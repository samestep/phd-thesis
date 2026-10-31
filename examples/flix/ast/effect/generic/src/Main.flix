// The pool is an effect whose declaration takes the index type as a
// parameter, so everything that uses it is generic in `r` and says `\ Ast[r]`.
// An effect set can't hold `Ast` at two index types, so the inner pool's
// computation has to be split off into a function whose signature hides it.
enum BinOp {
    case Add,
    case Sub,
    case Mul,
    case Div
}

enum Expr[r] {
    case Binary(BinOp, r, r),
    case Literal(Int32)
}

eff Ast[r] {
    def add(e: Expr[r]): r
    def get(r: r): Expr[r]
}

def interp(e: r): Int32 \ Ast[r] = match Ast.get(e) {
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

def lit(n: Int32): r \ Ast[r] = Ast.add(Expr.Literal(n))
def bin(op: BinOp, l: r, r: r): r \ Ast[r] = Ast.add(Expr.Binary(op, l, r))

def code(op: BinOp): Int32 = match op {
    case BinOp.Add => 1
    case BinOp.Sub => 2
    case BinOp.Mul => 3
    case BinOp.Div => 4
}

def opOf(code: Int32): BinOp = match code {
    case 1 => BinOp.Add
    case 2 => BinOp.Sub
    case 3 => BinOp.Mul
    case _ => BinOp.Div
}

// Representation 1: a node is an index into parallel lists.
enum Idx(Int32)

def withColumns(f: Unit -> a \ ef): a \ (ef - Ast[Idx]) = region rc {
    let ops = MutList.empty(rc);
    let lhs = MutList.empty(rc);
    let rhs = MutList.empty(rc);
    run f() with handler Ast {
        def add(e, k) = {
            let (op, l, r) = match e {
                case Expr.Binary(op, Idx.Idx(l), Idx.Idx(r)) => (code(op), l, r)
                case Expr.Literal(num) => (0, num, 0)
            };
            MutList.push(op, ops);
            MutList.push(l, lhs);
            MutList.push(r, rhs);
            k(Idx.Idx(MutList.size(ops) - 1))
        }
        def get(idx, k) = {
            let Idx.Idx(i) = idx;
            match MutList.get(i, ops) {
                case 0 => k(Expr.Literal(MutList.get(i, lhs)))
                case op => k(Expr.Binary(opOf(op), Idx.Idx(MutList.get(i, lhs)), Idx.Idx(MutList.get(i, rhs))))
            }
        }
    }
}

// Representation 2: a node is an index into one list of triples.
enum Slot(Int32)

def withTriples(f: Unit -> a \ ef): a \ (ef - Ast[Slot]) = region rc {
    let triples = MutList.empty(rc);
    run f() with handler Ast {
        def add(e, k) = {
            match e {
                case Expr.Binary(op, Slot.Slot(l), Slot.Slot(r)) =>
                    MutList.push(code(op), triples); MutList.push(l, triples); MutList.push(r, triples)
                case Expr.Literal(num) =>
                    MutList.push(0, triples); MutList.push(num, triples); MutList.push(0, triples)
            };
            k(Slot.Slot(MutList.size(triples) / 3 - 1))
        }
        def get(slot, k) = {
            let Slot.Slot(i) = slot;
            let at = j -> MutList.get(3 * i + j, triples);
            match at(0) {
                case 0 => k(Expr.Literal(at(1)))
                case op => k(Expr.Binary(opOf(op), Slot.Slot(at(1)), Slot.Slot(at(2))))
            }
        }
    }
}

def elsewhere(): Unit \ IO = withTriples(() ->
    println(interp(bin(BinOp.Div, bin(BinOp.Add, lit(4), lit(4)), bin(BinOp.Sub, lit(4), lit(4)))))
)

def main(): Unit \ IO = withColumns(() -> {
    let e = bin(BinOp.Div, bin(BinOp.Mul, bin(BinOp.Sub, lit(7), lit(10)), lit(7)), lit(2));
    println(interp(e));
    elsewhere();
    println(interp(e))
})
