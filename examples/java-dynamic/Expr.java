// A plain interface: the ScopedValue holds any `Ast`, with no cast, because
// `ExprRef` is fixed once for every representation, so the types no longer
// tell one pool's references from another's.
import java.util.ArrayList;
import java.util.List;

class Main {
    static final ScopedValue<Ast> AST = ScopedValue.newInstance();

    static long interp(ExprRef expr) {
        return switch (AST.get().get(expr)) {
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

    static ExprRef num(long n) { return AST.get().add(new Literal(n)); }
    static ExprRef bin(BinOp op, ExprRef l, ExprRef r) { return AST.get().add(new Binary(op, l, r)); }

    public static void main(String[] args) {
        ScopedValue.where(AST, new Columns()).run(() -> {
            var e = bin(BinOp.DIV, bin(BinOp.MUL, bin(BinOp.SUB, num(7), num(10)), num(7)), num(2));
            System.out.println(interp(e));
            ScopedValue.where(AST, new Triples()).run(() -> {
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

interface Ast {
    ExprRef add(Expr expr);
    Expr get(ExprRef expr);
}

// Representation 1: a node is an index into parallel lists.
class Columns implements Ast {
    final ArrayList<Long> ops = new ArrayList<>(), lhs = new ArrayList<>(), rhs = new ArrayList<>();

    public ExprRef add(Expr expr) {
        switch (expr) {
            case Binary(var op, var l, var r) -> { ops.add(op.ordinal() + 1L); lhs.add((long) l.index()); rhs.add((long) r.index()); }
            case Literal(var num) -> { ops.add(0L); lhs.add(num); rhs.add(0L); }
        }
        return new ExprRef(ops.size() - 1);
    }

    public Expr get(ExprRef expr) {
        int i = expr.index(), op = ops.get(i).intValue();
        if (op == 0) return new Literal(lhs.get(i));
        return new Binary(BinOp.values()[op - 1], new ExprRef(lhs.get(i).intValue()), new ExprRef(rhs.get(i).intValue()));
    }
}

// Representation 2: a node is an index into one list of triples.
class Triples implements Ast {
    final ArrayList<Long> triples = new ArrayList<>();

    public ExprRef add(Expr expr) {
        switch (expr) {
            case Binary(var op, var l, var r) -> triples.addAll(List.of(op.ordinal() + 1L, (long) l.index(), (long) r.index()));
            case Literal(var num) -> triples.addAll(List.of(0L, num, 0L));
        }
        return new ExprRef(triples.size() / 3 - 1);
    }

    public Expr get(ExprRef expr) {
        int i = 3 * expr.index(), op = triples.get(i).intValue();
        if (op == 0) return new Literal(triples.get(i + 1));
        return new Binary(BinOp.values()[op - 1], new ExprRef(triples.get(i + 1).intValue()), new ExprRef(triples.get(i + 2).intValue()));
    }
}
