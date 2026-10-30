// AsyncLocal<T>: a value set inside an async method does not flow back out to its caller.
var pool = new AsyncLocal<ExprPool>();

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
    pool.Value = new ExprPool();
    Console.WriteLine(Interp(Bin(BinOp.Div, Bin(BinOp.Add, Num(4), Num(4)), Bin(BinOp.Sub, Num(4), Num(4)))));
    await Task.CompletedTask;
}

pool.Value = new ExprPool();
var e = Bin(BinOp.Div, Bin(BinOp.Mul, Bin(BinOp.Sub, Num(7), Num(10)), Num(7)), Num(2));
Console.WriteLine(Interp(e));
await Elsewhere();
Console.WriteLine(Interp(e));

enum BinOp { Add, Sub, Mul, Div }

readonly record struct ExprRef(int Index);

abstract record Expr
{
    public record Binary(BinOp Op, ExprRef Lhs, ExprRef Rhs) : Expr;
    public record Literal(long Num) : Expr;
}

class ExprPool
{
    readonly List<Expr> exprs = [];

    public ExprRef Add(Expr expr)
    {
        exprs.Add(expr);
        return new ExprRef(exprs.Count - 1);
    }

    public Expr Get(ExprRef expr) => exprs[expr.Index];
}
