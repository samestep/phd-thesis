// ScopedValue: the pool is bound for the dynamic extent of a call.
import java.util.ArrayList;

sealed interface Node permits Lit, Add, Mul {}
record Lit(long n) implements Node {}
record Add(int l, int r) implements Node {}
record Mul(int l, int r) implements Node {}

class Expr {
    static final ScopedValue<ArrayList<Node>> POOL = ScopedValue.newInstance();

    static int push(Node node) {
        var pool = POOL.get();
        pool.add(node);
        return pool.size() - 1;
    }

    static int lit(long n) { return push(new Lit(n)); }
    static int add(int l, int r) { return push(new Add(l, r)); }
    static int mul(int l, int r) { return push(new Mul(l, r)); }

    static long eval(int e) {
        return switch (POOL.get().get(e)) {
            case Lit(var n) -> n;
            case Add(var l, var r) -> eval(l) + eval(r);
            case Mul(var l, var r) -> eval(l) * eval(r);
        };
    }

    public static void main(String[] args) {
        ScopedValue.where(POOL, new ArrayList<>()).run(() -> {
            int e = mul(add(lit(1), lit(2)), add(lit(3), lit(4)));
            System.out.println(eval(e));
            ScopedValue.where(POOL, new ArrayList<>()).run(() -> {
                System.out.println(eval(add(lit(4), lit(4))));
            });
            System.out.println(eval(e));
        });
    }
}
