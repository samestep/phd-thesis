// Generic over the representation: the index type is an associated type,
// and every function that touches an `Expr` takes a type parameter and the
// pool, though the compiler infers the type at each call. Each instance is
// specialized at compile time. Slang has no heap, so a pool is fixed-size
// arrays in a struct; no sum types, so a node is a struct with no operator
// for a literal; and no recursion (slangc's C++ backend aborts on a call
// cycle), so `interp` walks the tree with stacks of its own.

[UnscopedEnum]
enum BinOp
{
    Add = 1, // 0 means a literal.
    Sub,
    Mul,
    Div,
}

struct Expr<R>
{
    Optional<BinOp> op; // `none` for a literal.
    R lhs, rhs;
    int64_t num;
}

interface IAst
{
    associatedtype Ref;
    [mutating] Ref add(Expr<Ref> expr);
    Expr<Ref> get(Ref expr);
}

static const int kCapacity = 16;

struct Stack<T, let N : int>
{
    T items[N] = {};
    int size = 0;

    bool empty() { return size == 0; }
    [mutating] void push(T item) { items[size++] = item; }
    [mutating] T pop() { return items[--size]; }
}

// A node still to evaluate, and whether its operands are done.
struct Visit<R>
{
    R expr;
    bool ready;
}

int64_t interp<A : IAst>(A ast, A.Ref expr)
{
    // Nodes still to visit, and the values computed so far.
    Stack<Visit<A.Ref>, kCapacity> todo = {};
    Stack<int64_t, kCapacity> values = {};
    todo.push({ expr, false });
    while (!todo.empty())
    {
        let visit = todo.pop();
        let e = ast.get(visit.expr);
        if (e.op == none)
        {
            values.push(e.num);
        }
        else if (!visit.ready)
        {
            todo.push({ visit.expr, true });
            todo.push({ e.rhs, false });
            todo.push({ e.lhs, false });
        }
        else
        {
            // Wrapping arithmetic, through unsigned integers.
            let rhs = values.pop();
            let lhs = values.pop();
            switch (e.op.value)
            {
            case Add: values.push(int64_t(uint64_t(lhs) + uint64_t(rhs))); break;
            case Sub: values.push(int64_t(uint64_t(lhs) - uint64_t(rhs))); break;
            case Mul: values.push(int64_t(uint64_t(lhs) * uint64_t(rhs))); break;
            case Div: values.push(rhs == 0 ? 0 : lhs / rhs); break;
            }
        }
    }
    return values.pop();
}

A.Ref lit<A : IAst>(inout A ast, int64_t n)
{
    return ast.add({ none, {}, {}, n });
}

A.Ref bin<A : IAst>(inout A ast, BinOp op, A.Ref lhs, A.Ref rhs)
{
    return ast.add({ op, lhs, rhs, 0 });
}

// Representation 1: a node is an index into parallel arrays.
struct Idx
{
    uint index;
}

struct Columns : IAst
{
    typealias Ref = Idx;

    int64_t ops[kCapacity] = {}, lhs[kCapacity] = {}, rhs[kCapacity] = {};
    uint count = 0;

    [mutating]
    Idx add(Expr<Idx> expr)
    {
        if (expr.op == none)
            set(0, expr.num, 0);
        else
            set(int64_t(expr.op.value), expr.lhs.index, expr.rhs.index);
        return { count++ };
    }

    [mutating]
    void set(int64_t op, int64_t l, int64_t r)
    {
        ops[count] = op;
        lhs[count] = l;
        rhs[count] = r;
    }

    Expr<Idx> get(Idx expr)
    {
        let i = expr.index;
        if (ops[i] == 0)
            return { none, {}, {}, lhs[i] };
        return { BinOp(ops[i]), { uint(lhs[i]) }, { uint(rhs[i]) }, 0 };
    }
}

// Representation 2: a node is an index into one array of triples.
struct Slot
{
    uint index;
}

struct Triples : IAst
{
    typealias Ref = Slot;

    int64_t triples[3 * kCapacity] = {};
    uint count = 0;

    [mutating]
    Slot add(Expr<Slot> expr)
    {
        if (expr.op == none)
            set(0, expr.num, 0);
        else
            set(int64_t(expr.op.value), expr.lhs.index, expr.rhs.index);
        return { count++ };
    }

    [mutating]
    void set(int64_t op, int64_t a, int64_t b)
    {
        triples[3 * count] = op;
        triples[3 * count + 1] = a;
        triples[3 * count + 2] = b;
    }

    Expr<Slot> get(Slot expr)
    {
        let i = 3 * expr.index;
        if (triples[i] == 0)
            return { none, {}, {}, triples[i + 1] };
        return { BinOp(triples[i]), { uint(triples[i + 1]) }, { uint(triples[i + 2]) }, 0 };
    }
}

export __extern_cpp int main()
{
    Columns pool = {};
    let e = bin(pool, Div, bin(pool, Mul, bin(pool, Sub, lit(pool, 7), lit(pool, 10)), lit(pool, 7)), lit(pool, 2));
    printf("%lld\n", interp(pool, e));
    {
        Triples pool = {};
        let f = bin(pool, Div, bin(pool, Add, lit(pool, 4), lit(pool, 4)), bin(pool, Sub, lit(pool, 4), lit(pool, 4)));
        printf("%lld\n", interp(pool, f));
    }
    printf("%lld\n", interp(pool, e));
    return 0;
}
