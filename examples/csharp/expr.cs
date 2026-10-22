// AsyncLocal<T>: a value set inside an async method does not flow back out to its caller.
var pool = new AsyncLocal<List<Node>>();

int Push(Node node)
{
    pool.Value!.Add(node);
    return pool.Value.Count - 1;
}

int Lit(long n) => Push(new Node.Lit(n));
int Add(int l, int r) => Push(new Node.Add(l, r));
int Mul(int l, int r) => Push(new Node.Mul(l, r));

long Eval(int e) => pool.Value![e] switch
{
    Node.Lit(var n) => n,
    Node.Add(var l, var r) => Eval(l) + Eval(r),
    Node.Mul(var l, var r) => Eval(l) * Eval(r),
    _ => throw new InvalidOperationException(),
};

async Task Elsewhere()
{
    pool.Value = [];
    Console.WriteLine(Eval(Add(Lit(4), Lit(4))));
    await Task.CompletedTask;
}

pool.Value = [];
var e = Mul(Add(Lit(1), Lit(2)), Add(Lit(3), Lit(4)));
Console.WriteLine(Eval(e));
await Elsewhere();
Console.WriteLine(Eval(e));

abstract record Node
{
    public record Lit(long N) : Node;
    public record Add(int L, int R) : Node;
    public record Mul(int L, int R) : Node;
}
