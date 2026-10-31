// The tree Sampson starts from: each record holds references to its children,
// so nothing needs a pool, and the GC reclaims nodes nobody points to.
long Interp(Expr expr) => expr switch
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

Expr Num(long n) => new Expr.Literal(n);
Expr Bin(BinOp op, Expr l, Expr r) => new Expr.Binary(op, l, r);

var e = Bin(BinOp.Div, Bin(BinOp.Mul, Bin(BinOp.Sub, Num(7), Num(10)), Num(7)), Num(2));
Console.WriteLine(Interp(e));
{
    var f = Bin(BinOp.Div, Bin(BinOp.Add, Num(4), Num(4)), Bin(BinOp.Sub, Num(4), Num(4)));
    Console.WriteLine(Interp(f));
}
Console.WriteLine(Interp(e));

enum BinOp { Add, Sub, Mul, Div }

abstract record Expr
{
    public record Binary(BinOp Op, Expr Lhs, Expr Rhs) : Expr;
    public record Literal(long Num) : Expr;
}
