// An interface for the arithmetic, which `double` conforms to through an
// extension and `Dual<F>` does for any `F` that does, so duals nest, and
// every function in the program is generic over it: each signature names
// `<F : IField>` or `<R : IReal>` (a field that can also round), and the
// compiler infers it at each call. An interface can't require an operator,
// so it requires static methods, and one generic operator overload per
// operation calls them. Generic code can't write a float literal, so `f`
// writes `F.constant(2.0)`. `Dual<Dual<R>>` and `Dual<R>` are different
// types, so `nested` has to lift the outer variable into the inner
// differentiation (`still(x)`): adding it as it is (`x + variable(y0)`) is a
// compile-time error, since there is no `Dual<R> + Dual<Dual<R>>`. Each
// instance is specialized at compile time, as fast as hand-written code.
// (For Slang's own automatic differentiation, see `../autodiff`.)

interface IField
{
    static This constant(double n);
    static This add(This l, This r);
    static This sub(This l, This r);
    static This mul(This l, This r);
    static This div(This l, This r);
}

interface IReal : IField
{
    int64_t round();
}

F operator+<F : IField>(F l, F r) { return F.add(l, r); }
F operator-<F : IField>(F l, F r) { return F.sub(l, r); }
F operator*<F : IField>(F l, F r) { return F.mul(l, r); }
F operator/<F : IField>(F l, F r) { return F.div(l, r); }

extension double : IReal
{
    static double constant(double n) { return n; }
    static double add(double l, double r) { return l + r; }
    static double sub(double l, double r) { return l - r; }
    static double mul(double l, double r) { return l * r; }
    static double div(double l, double r) { return l / r; }
    // `rint` rounds ties to even.
    int64_t round() { return int64_t(rint(this)); }
}

F f<F : IField>(F x)
{
    return x * x * x - F.constant(2.0) * x - F.constant(5.0);
}

struct Dual<F : IField> : IField
{
    F v, d;

    static Dual<F> constant(double n) { return still(F.constant(n)); }
    static Dual<F> add(Dual<F> l, Dual<F> r) { return { l.v + r.v, l.d + r.d }; }
    static Dual<F> sub(Dual<F> l, Dual<F> r) { return { l.v - r.v, l.d - r.d }; }
    static Dual<F> mul(Dual<F> l, Dual<F> r) { return { l.v * r.v, l.d * r.v + l.v * r.d }; }
    static Dual<F> div(Dual<F> l, Dual<F> r)
    {
        return { l.v / r.v, (l.d * r.v - l.v * r.d) / (r.v * r.v) };
    }
}

Dual<F> variable<F : IField>(F x)
{
    return { x, F.constant(1.0) };
}

Dual<F> still<F : IField>(F x)
{
    return { x, F.constant(0.0) };
}

void show<R : IReal>(R x)
{
    printf("%lld\n", (x * R.constant(1000000.0)).round());
}

void derivatives<R : IReal>(R x)
{
    show(f(x));
    show(f(variable(x)).d);
    show(f(variable(variable(x))).d.d);
}

void newton<R : IReal>(R x0, int steps)
{
    var x = x0;
    for (int i = 0; i < steps; i++)
    {
        let y = f(variable(x));
        x = x - y.v / y.d;
        show(x);
    }
}

// d/dx (x * d/dy (x + y)) at x = 1, y = 1.
R nested<R : IReal>(R at)
{
    let x = variable(at);
    let y0 = Dual<R>.constant(1.0);
    let inner = (still(x) + variable(y0)).d;
    return (x * inner).d;
}

export __extern_cpp int main()
{
    derivatives(2.0l);
    newton(2.0l, 4);
    show(nested(1.0l));
    return 0;
}
