// Three interfaces, one per choice, each a type parameter: the pool is passed
// as a value and its index type is an associated type, while the arithmetic
// and the tracer are types whose methods are all static. Every function that
// builds or reads an `Expr` takes the pool, and `interp` and `report` take
// all three; nothing in their arguments mentions the tracer, so every call
// names it, and with it the others. Each instance is specialized at compile
// time, as fast as hand-written code.
//
// Slang has no recursion (slangc's C++ backend aborts on a call cycle), so
// `interp` walks the tree with stacks of its own, and a `Traced` node can't
// just call `interp<P, V, Loud>`: in that instance the call would be
// recursive. So a tracer says whether it is already `loud`; if so, the
// `Traced` node's inner expression is pushed onto the same stacks, and the
// call, in a branch that is statically false, is gone before code
// generation. Slang has no heap, so the pool is a fixed-size array in a
// struct, and no sum types, so a node is a struct with a kind.

enum BinOp
{
    Add = 1, // 0 means a literal, 5 traced.
    Sub,
    Mul,
    Div,
}

enum Kind
{
    Binary,
    Literal,
    // Evaluate the inner expression, `lhs`, with tracing on.
    Traced,
}

struct Expr<R>
{
    Kind kind;
    BinOp op;
    R lhs, rhs;
    int num;
}

// The pool: an index type, how to read a node through one, and how to make
// one.
interface IPool
{
    associatedtype Ref;
    Expr<Ref> node(Ref expr);
    [mutating] Ref add(Expr<Ref> expr);
}

// The arithmetic of the interpreted language: what a value is, what a
// literal means, and what integer one prints as.
interface IArith
{
    static This value(int n);
    static This add(This l, This r);
    static This sub(This l, This r);
    static This mul(This l, This r);
    static This div(This l, This r);
    int shown();
}

V operator+<V : IArith>(V l, V r) { return V.add(l, r); }
V operator-<V : IArith>(V l, V r) { return V.sub(l, r); }
V operator*<V : IArith>(V l, V r) { return V.mul(l, r); }
V operator/<V : IArith>(V l, V r) { return V.div(l, r); }

// Called with every intermediate value.
interface ITrace
{
    static const bool loud;
    static void trace<V : IArith>(V v);
}

struct Quiet : ITrace
{
    static const bool loud = false;
    static void trace<V : IArith>(V v) {}
}

struct Loud : ITrace
{
    static const bool loud = true;
    static void trace<V : IArith>(V v)
    {
        printf("  %d\n", v.shown());
    }
}

static const int kCapacity = 32;

struct Stack<T, let N : int>
{
    T items[N] = {};
    int size = 0;

    bool empty() { return size == 0; }
    [mutating] void push(T item) { items[size++] = item; }
    [mutating] T pop() { return items[--size]; }
    T top() { return items[size - 1]; }
}

// A node still to evaluate, and whether its operands are done.
struct Visit<R>
{
    R expr;
    bool ready;
}

// Written once, against the interfaces alone.
V interp<P : IPool, V : IArith, T : ITrace>(P pool, P.Ref e)
{
    // Nodes still to visit, and the values computed so far.
    Stack<Visit<P.Ref>, kCapacity> todo = {};
    Stack<V, kCapacity> values = {};
    todo.push({ e, false });
    while (!todo.empty())
    {
        let visit = todo.pop();
        let expr = pool.node(visit.expr);
        if (!visit.ready)
        {
            switch (expr.kind)
            {
            case Kind.Binary:
                todo.push({ visit.expr, true });
                todo.push({ expr.rhs, false });
                todo.push({ expr.lhs, false });
                continue;
            case Kind.Literal:
                values.push(V.value(expr.num));
                break;
            case Kind.Traced:
                if (T.loud)
                {
                    todo.push({ visit.expr, true });
                    todo.push({ expr.lhs, false });
                    continue;
                }
                values.push(interp<P, V, Loud>(pool, expr.lhs));
                break;
            }
        }
        else if (expr.kind == Kind.Binary)
        {
            let r = values.pop();
            let l = values.pop();
            switch (expr.op)
            {
            case BinOp.Add: values.push(l + r); break;
            case BinOp.Sub: values.push(l - r); break;
            case BinOp.Mul: values.push(l * r); break;
            case BinOp.Div: values.push(l / r); break;
            }
        }
        T.trace(values.top());
    }
    return values.pop();
}

void report<P : IPool, V : IArith, T : ITrace>(P pool, P.Ref e)
{
    printf("%d\n", interp<P, V, T>(pool, e).shown());
}

P.Ref lit<P : IPool>(inout P pool, int n)
{
    return pool.add({ Kind.Literal, {}, {}, {}, n });
}

P.Ref bin<P : IPool>(inout P pool, BinOp op, P.Ref lhs, P.Ref rhs)
{
    return pool.add({ Kind.Binary, op, lhs, rhs, 0 });
}

P.Ref traced<P : IPool>(inout P pool, P.Ref inner)
{
    return pool.add({ Kind.Traced, {}, inner, {}, 0 });
}

// A pool: a node is an index into one array of triples.
struct Slot
{
    uint index;
}

struct Triples : IPool
{
    typealias Ref = Slot;

    int triples[3 * kCapacity] = {};
    uint count = 0;

    Expr<Slot> node(Slot e)
    {
        let i = 3 * e.index;
        let code = triples[i];
        Slot a = { uint(triples[i + 1]) };
        Slot b = { uint(triples[i + 2]) };
        if (code == 0)
            return { Kind.Literal, {}, {}, {}, triples[i + 1] };
        if (code == 5)
            return { Kind.Traced, {}, a, {}, 0 };
        return { Kind.Binary, BinOp(code), a, b, 0 };
    }

    [mutating]
    Slot add(Expr<Slot> expr)
    {
        switch (expr.kind)
        {
        case Kind.Binary: set(int(expr.op), expr.lhs.index, expr.rhs.index); break;
        case Kind.Literal: set(0, expr.num, 0); break;
        case Kind.Traced: set(5, expr.lhs.index, 0); break;
        }
        return { count++ };
    }

    [mutating]
    void set(int code, int a, int b)
    {
        triples[3 * count] = code;
        triples[3 * count + 1] = a;
        triples[3 * count + 2] = b;
    }
}

// Three meanings for the interpreted language's arithmetic.

// Through unsigned integers, which wrap.
struct Wrapping : IArith
{
    int n;
    static Wrapping value(int n) { return { n }; }
    static Wrapping add(Wrapping l, Wrapping r) { return { int(uint(l.n) + uint(r.n)) }; }
    static Wrapping sub(Wrapping l, Wrapping r) { return { int(uint(l.n) - uint(r.n)) }; }
    static Wrapping mul(Wrapping l, Wrapping r) { return { int(uint(l.n) * uint(r.n)) }; }
    static Wrapping div(Wrapping l, Wrapping r) { return { l.n / r.n }; }
    int shown() { return n; }
}

// Through 64-bit integers, which hold every 32-bit result, clamped back.
struct Saturating : IArith
{
    int n;
    static Saturating saturate(int64_t x) { return { int(clamp(x, int64_t(int::minValue), int64_t(int::maxValue))) }; }
    static Saturating value(int n) { return { n }; }
    static Saturating add(Saturating l, Saturating r) { return saturate(int64_t(l.n) + r.n); }
    static Saturating sub(Saturating l, Saturating r) { return saturate(int64_t(l.n) - r.n); }
    static Saturating mul(Saturating l, Saturating r) { return saturate(int64_t(l.n) * r.n); }
    static Saturating div(Saturating l, Saturating r) { return saturate(int64_t(l.n) / r.n); }
    int shown() { return n; }
}

extension double : IArith
{
    static double value(int n) { return n; }
    static double add(double l, double r) { return l + r; }
    static double sub(double l, double r) { return l - r; }
    static double mul(double l, double r) { return l * r; }
    static double div(double l, double r) { return l / r; }
    // `rint` rounds ties to even.
    int shown() { return int(rint(this)); }
}

export __extern_cpp int main()
{
    Triples pool = {};
    // 50000 * 50000 / 100000 + traced((7 - 10) * 7 / 8)
    let big = bin(pool, BinOp.Div, bin(pool, BinOp.Mul, lit(pool, 50000), lit(pool, 50000)), lit(pool, 100000));
    let diff = bin(pool, BinOp.Sub, lit(pool, 7), lit(pool, 10));
    let small = bin(pool, BinOp.Div, bin(pool, BinOp.Mul, diff, lit(pool, 7)), lit(pool, 8));
    let e = bin(pool, BinOp.Add, big, traced(pool, small));
    report<Triples, Wrapping, Quiet>(pool, e);
    report<Triples, Saturating, Quiet>(pool, e);
    report<Triples, double, Quiet>(pool, e);
    return 0;
}
