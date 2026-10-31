// The tree Sampson starts from: each record holds references to its children,
// so nothing needs a pool, and the GC reclaims nodes nobody points to.
class Main {
    static long interp(Expr expr) {
        return switch (expr) {
            case Binary(var op, var lhs, var rhs) -> {
                long l = interp(lhs), r = interp(rhs);
                yield switch (op) {
                    case ADD -> l + r;
                    case SUB -> l - r;
                    case MUL -> l * r;
                    case DIV -> r == 0 ? 0 : l / r;
                };
            }
            case Literal(var num) -> num;
        };
    }

    static Expr num(long n) { return new Literal(n); }
    static Expr bin(BinOp op, Expr l, Expr r) { return new Binary(op, l, r); }

    public static void main(String[] args) {
        var e = bin(BinOp.DIV, bin(BinOp.MUL, bin(BinOp.SUB, num(7), num(10)), num(7)), num(2));
        System.out.println(interp(e));
        {
            var f = bin(BinOp.DIV, bin(BinOp.ADD, num(4), num(4)), bin(BinOp.SUB, num(4), num(4)));
            System.out.println(interp(f));
        }
        System.out.println(interp(e));
    }
}

enum BinOp { ADD, SUB, MUL, DIV }

sealed interface Expr permits Binary, Literal {}
record Binary(BinOp op, Expr lhs, Expr rhs) implements Expr {}
record Literal(long num) implements Expr {}
