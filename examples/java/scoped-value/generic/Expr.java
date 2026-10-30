// A generic interface: Ast<R> leaves the index type open, but a ScopedValue's
// type is fixed where it's declared, so the pool comes back through an
// unchecked cast: R is whatever each caller declares it to be (`Idx e = ...`).
import java.util.ArrayList;
import java.util.List;

class Main {
    static final ScopedValue<Ast<?>> AST = ScopedValue.newInstance();

    @SuppressWarnings("unchecked")
    static <R> Ast<R> ast() { return (Ast<R>) AST.get(); }

    static <R> long interp(R expr) {
        return switch (Main.<R>ast().get(expr)) {
            case Binary<R>(var op, var lhs, var rhs) -> {
                long l = interp(lhs), r = interp(rhs);
                yield switch (op) {
                    case ADD -> l + r;
                    case SUB -> l - r;
                    case MUL -> l * r;
                    case DIV -> r == 0 ? 0 : l / r;
                };
            }
            case Literal<R>(var num) -> num;
        };
    }

    static <R> R num(long n) { return Main.<R>ast().add(new Literal<>(n)); }
    static <R> R bin(BinOp op, R l, R r) { return Main.<R>ast().add(new Binary<>(op, l, r)); }

    public static void main(String[] args) {
        ScopedValue.where(AST, new Columns()).run(() -> {
            Idx e = bin(BinOp.DIV, bin(BinOp.MUL, bin(BinOp.SUB, num(7), num(10)), num(7)), num(2));
            System.out.println(interp(e));
            ScopedValue.where(AST, new Triples()).run(() -> {
                Slot f = bin(BinOp.DIV, bin(BinOp.ADD, num(4), num(4)), bin(BinOp.SUB, num(4), num(4)));
                System.out.println(interp(f));
            });
            System.out.println(interp(e));
        });
    }
}

enum BinOp { ADD, SUB, MUL, DIV }

sealed interface Expr<R> permits Binary, Literal {}
record Binary<R>(BinOp op, R lhs, R rhs) implements Expr<R> {}
record Literal<R>(long num) implements Expr<R> {}

interface Ast<R> {
    R add(Expr<R> expr);
    Expr<R> get(R expr);
}

// Representation 1: a node is an index into parallel lists.
record Idx(int index) {}

class Columns implements Ast<Idx> {
    final ArrayList<Long> ops = new ArrayList<>(), lhs = new ArrayList<>(), rhs = new ArrayList<>();

    public Idx add(Expr<Idx> expr) {
        switch (expr) {
            case Binary<Idx>(var op, var l, var r) -> { ops.add(op.ordinal() + 1L); lhs.add((long) l.index()); rhs.add((long) r.index()); }
            case Literal<Idx>(var num) -> { ops.add(0L); lhs.add(num); rhs.add(0L); }
        }
        return new Idx(ops.size() - 1);
    }

    public Expr<Idx> get(Idx expr) {
        int i = expr.index(), op = ops.get(i).intValue();
        if (op == 0) return new Literal<>(lhs.get(i));
        return new Binary<>(BinOp.values()[op - 1], new Idx(lhs.get(i).intValue()), new Idx(rhs.get(i).intValue()));
    }
}

// Representation 2: a node is an index into one list of triples.
record Slot(int index) {}

class Triples implements Ast<Slot> {
    final ArrayList<Long> triples = new ArrayList<>();

    public Slot add(Expr<Slot> expr) {
        switch (expr) {
            case Binary<Slot>(var op, var l, var r) -> triples.addAll(List.of(op.ordinal() + 1L, (long) l.index(), (long) r.index()));
            case Literal<Slot>(var num) -> triples.addAll(List.of(0L, num, 0L));
        }
        return new Slot(triples.size() / 3 - 1);
    }

    public Expr<Slot> get(Slot expr) {
        int i = 3 * expr.index(), op = triples.get(i).intValue();
        if (op == 0) return new Literal<>(triples.get(i + 1));
        return new Binary<>(BinOp.values()[op - 1], new Slot(triples.get(i + 1).intValue()), new Slot(triples.get(i + 2).intValue()));
    }
}
