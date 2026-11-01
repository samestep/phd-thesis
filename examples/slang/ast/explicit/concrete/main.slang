// The pool has to be passed to everything that touches an `Expr`. Slang has
// no heap, so the pool is a fixed-size array in a struct, and no sum types,
// so a node is a struct with no operator for a literal. Recursion is out
// too (slangc's C++ backend aborts on a call cycle), so `interp` walks the
// tree with stacks of its own.

[UnscopedEnum]
enum BinOp
{
    Add,
    Sub,
    Mul,
    Div,
}

struct ExprRef
{
    uint index;
}

struct Expr
{
    Optional<BinOp> op; // `none` for a literal.
    ExprRef lhs, rhs;
    int64_t num;
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
struct Visit
{
    ExprRef expr;
    bool ready;
}

struct ExprPool
{
    Expr exprs[kCapacity] = {};
    uint count = 0;

    [mutating]
    ExprRef add(Expr expr)
    {
        exprs[count] = expr;
        return { count++ };
    }

    Expr get(ExprRef expr)
    {
        return exprs[expr.index];
    }

    int64_t interp(ExprRef expr)
    {
        // Nodes still to visit, and the values computed so far.
        Stack<Visit, kCapacity> todo = {};
        Stack<int64_t, kCapacity> values = {};
        todo.push({ expr, false });
        while (!todo.empty())
        {
            let visit = todo.pop();
            let e = get(visit.expr);
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

    [mutating]
    ExprRef lit(int64_t n)
    {
        return add({ none, {}, {}, n });
    }

    [mutating]
    ExprRef bin(BinOp op, ExprRef lhs, ExprRef rhs)
    {
        return add({ op, lhs, rhs, 0 });
    }
}

export __extern_cpp int main()
{
    ExprPool pool = {};
    let e = pool.bin(Div, pool.bin(Mul, pool.bin(Sub, pool.lit(7), pool.lit(10)), pool.lit(7)), pool.lit(2));
    printf("%lld\n", pool.interp(e));
    {
        ExprPool pool = {};
        let f = pool.bin(Div, pool.bin(Add, pool.lit(4), pool.lit(4)), pool.bin(Sub, pool.lit(4), pool.lit(4)));
        printf("%lld\n", pool.interp(f));
    }
    printf("%lld\n", pool.interp(e));
    return 0;
}
