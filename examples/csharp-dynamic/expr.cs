// A plain interface: the AsyncLocal holds any `IAst`, with no cast, because
// `ExprRef` is fixed once for every representation, so the types no longer
// tell one pool's references from another's.
var pool = new AsyncLocal<IAst>();

long Interp(ExprRef expr) => pool.Value!.Get(expr) switch
{
    Expr.Binary(var op, var lhs, var rhs) => (op, Interp(lhs), Interp(rhs)) switch
    {
        (BinOp.Add, var l, var r) => unchecked(l + r),
        (BinOp.Sub, var l, var r) => unchecked(l - r),
        (BinOp.Mul, var l, var r) => unchecked(l * r),
        (BinOp.Div, var l, var r) => r == 0 ? 0 : l / r,
        _ => throw new InvalidOperationException(),
    },
    Expr.Literal(var num) => num,
    _ => throw new InvalidOperationException(),
};

ExprRef Num(long n) => pool.Value!.Add(new Expr.Literal(n));
ExprRef Bin(BinOp op, ExprRef l, ExprRef r) => pool.Value!.Add(new Expr.Binary(op, l, r));

async Task Elsewhere()
{
    pool.Value = new Triples();
    Console.WriteLine(Interp(Bin(BinOp.Div, Bin(BinOp.Add, Num(4), Num(4)), Bin(BinOp.Sub, Num(4), Num(4)))));
    await Task.CompletedTask;
}

pool.Value = new Columns();
var e = Bin(BinOp.Div, Bin(BinOp.Mul, Bin(BinOp.Sub, Num(7), Num(10)), Num(7)), Num(2));
Console.WriteLine(Interp(e));
await Elsewhere();
Console.WriteLine(Interp(e));

enum BinOp { Add = 1, Sub, Mul, Div } // 0 means a literal.

readonly record struct ExprRef(int Index);

abstract record Expr
{
    public record Binary(BinOp Op, ExprRef Lhs, ExprRef Rhs) : Expr;
    public record Literal(long Num) : Expr;
}

interface IAst
{
    ExprRef Add(Expr expr);
    Expr Get(ExprRef expr);
}

static class Node
{
    public static Expr Of(long op, long lhs, long rhs) =>
        op == 0 ? new Expr.Literal(lhs) : new Expr.Binary((BinOp)op, new ExprRef((int)lhs), new ExprRef((int)rhs));
}

// Representation 1: a node is an index into parallel lists.
class Columns : IAst
{
    readonly List<long> ops = [], lhs = [], rhs = [];

    public ExprRef Add(Expr expr)
    {
        var (op, l, r) = expr switch
        {
            Expr.Binary(var o, var x, var y) => ((long)o, (long)x.Index, (long)y.Index),
            Expr.Literal(var num) => (0L, num, 0L),
            _ => throw new InvalidOperationException(),
        };
        ops.Add(op);
        lhs.Add(l);
        rhs.Add(r);
        return new ExprRef(ops.Count - 1);
    }

    public Expr Get(ExprRef expr) => Node.Of(ops[expr.Index], lhs[expr.Index], rhs[expr.Index]);
}

// Representation 2: a node is an index into one list of triples.
class Triples : IAst
{
    readonly List<long> triples = [];

    public ExprRef Add(Expr expr)
    {
        triples.AddRange(expr switch
        {
            Expr.Binary(var op, var l, var r) => [(long)op, l.Index, r.Index],
            Expr.Literal(var num) => [0, num, 0],
            _ => throw new InvalidOperationException(),
        });
        return new ExprRef(triples.Count / 3 - 1);
    }

    public Expr Get(ExprRef expr)
    {
        var i = 3 * expr.Index;
        return Node.Of(triples[i], triples[i + 1], triples[i + 2]);
    }
}
