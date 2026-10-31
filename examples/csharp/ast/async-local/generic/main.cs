// A generic interface: IAst<R> leaves the index type open, but an AsyncLocal's
// type is fixed where it's declared, so the pool comes back through a cast
// checked at run time, and since C# can't infer a type argument from a return
// type, every `Num` names its index type.
var pool = new AsyncLocal<object>();

IAst<R> Ast<R>() => (IAst<R>)pool.Value!;

long Interp<R>(R expr) => Ast<R>().Get(expr) switch
{
    Expr<R>.Binary(var op, var lhs, var rhs) => (op, Interp(lhs), Interp(rhs)) switch
    {
        (BinOp.Add, var l, var r) => unchecked(l + r),
        (BinOp.Sub, var l, var r) => unchecked(l - r),
        (BinOp.Mul, var l, var r) => unchecked(l * r),
        (BinOp.Div, var l, var r) => r == 0 ? 0 : l / r,
        _ => throw new InvalidOperationException(),
    },
    Expr<R>.Literal(var num) => num,
    _ => throw new InvalidOperationException(),
};

R Num<R>(long n) => Ast<R>().Add(new Expr<R>.Literal(n));
R Bin<R>(BinOp op, R l, R r) => Ast<R>().Add(new Expr<R>.Binary(op, l, r));

async Task Elsewhere()
{
    pool.Value = new Triples();
    Console.WriteLine(Interp(Bin(BinOp.Div, Bin(BinOp.Add, Num<Slot>(4), Num<Slot>(4)), Bin(BinOp.Sub, Num<Slot>(4), Num<Slot>(4)))));
    await Task.CompletedTask;
}

pool.Value = new Columns();
var e = Bin(BinOp.Div, Bin(BinOp.Mul, Bin(BinOp.Sub, Num<Idx>(7), Num<Idx>(10)), Num<Idx>(7)), Num<Idx>(2));
Console.WriteLine(Interp(e));
await Elsewhere();
Console.WriteLine(Interp(e));

enum BinOp { Add = 1, Sub, Mul, Div } // 0 means a literal.

abstract record Expr<R>
{
    public record Binary(BinOp Op, R Lhs, R Rhs) : Expr<R>;
    public record Literal(long Num) : Expr<R>;
}

interface IAst<R>
{
    R Add(Expr<R> expr);
    Expr<R> Get(R expr);
}

static class Node
{
    public static Expr<R> Of<R>(long op, long lhs, long rhs, Func<long, R> r) =>
        op == 0 ? new Expr<R>.Literal(lhs) : new Expr<R>.Binary((BinOp)op, r(lhs), r(rhs));
}

// Representation 1: a node is an index into parallel lists.
readonly record struct Idx(int Index);

class Columns : IAst<Idx>
{
    readonly List<long> ops = [], lhs = [], rhs = [];

    public Idx Add(Expr<Idx> expr)
    {
        var (op, l, r) = expr switch
        {
            Expr<Idx>.Binary(var o, var x, var y) => ((long)o, (long)x.Index, (long)y.Index),
            Expr<Idx>.Literal(var num) => (0L, num, 0L),
            _ => throw new InvalidOperationException(),
        };
        ops.Add(op);
        lhs.Add(l);
        rhs.Add(r);
        return new Idx(ops.Count - 1);
    }

    public Expr<Idx> Get(Idx expr) => Node.Of(ops[expr.Index], lhs[expr.Index], rhs[expr.Index], i => new Idx((int)i));
}

// Representation 2: a node is an index into one list of triples.
readonly record struct Slot(int Index);

class Triples : IAst<Slot>
{
    readonly List<long> triples = [];

    public Slot Add(Expr<Slot> expr)
    {
        triples.AddRange(expr switch
        {
            Expr<Slot>.Binary(var op, var l, var r) => [(long)op, l.Index, r.Index],
            Expr<Slot>.Literal(var num) => [0, num, 0],
            _ => throw new InvalidOperationException(),
        });
        return new Slot(triples.Count / 3 - 1);
    }

    public Expr<Slot> Get(Slot expr)
    {
        var i = 3 * expr.Index;
        return Node.Of(triples[i], triples[i + 1], triples[i + 2], j => new Slot((int)j));
    }
}
