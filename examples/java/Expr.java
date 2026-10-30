// ScopedValue: the pool is bound for the dynamic extent of a call.
import java.util.ArrayList;

class Main {
    static final ScopedValue<ExprPool> POOL = ScopedValue.newInstance();

    static long interp(ExprRef expr) {
        return switch (POOL.get().get(expr)) {
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

    static ExprRef num(long n) { return POOL.get().add(new Literal(n)); }
    static ExprRef bin(BinOp op, ExprRef l, ExprRef r) { return POOL.get().add(new Binary(op, l, r)); }

    public static void main(String[] args) {
        ScopedValue.where(POOL, new ExprPool()).run(() -> {
            var e = bin(BinOp.DIV, bin(BinOp.MUL, bin(BinOp.SUB, num(7), num(10)), num(7)), num(2));
            System.out.println(interp(e));
            ScopedValue.where(POOL, new ExprPool()).run(() -> {
                System.out.println(interp(bin(BinOp.DIV, bin(BinOp.ADD, num(4), num(4)), bin(BinOp.SUB, num(4), num(4)))));
            });
            System.out.println(interp(e));
        });
    }
}

enum BinOp { ADD, SUB, MUL, DIV }

record ExprRef(int index) {}

sealed interface Expr permits Binary, Literal {}
record Binary(BinOp op, ExprRef lhs, ExprRef rhs) implements Expr {}
record Literal(long num) implements Expr {}

class ExprPool {
    final ArrayList<Expr> exprs = new ArrayList<>();

    ExprRef add(Expr expr) {
        exprs.add(expr);
        return new ExprRef(exprs.size() - 1);
    }

    Expr get(ExprRef expr) { return exprs.get(expr.index()); }
}
