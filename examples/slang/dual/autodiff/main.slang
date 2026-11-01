// Slang's own automatic differentiation: `f` is written once on plain
// `double`s and marked `[Differentiable]`, and `fwd_diff(f)` is the function
// the compiler derives from it, which takes and returns a
// `DifferentialPair<double>` (a primal `p` and a derivative `d`, made by
// `diffPair`). There's no dual-number type and no arithmetic interface: the
// derivative is generated code, specialized at compile time. Nesting
// `fwd_diff` gives the second derivative, on pairs of pairs. In `nested`,
// `inner` differentiates with respect to `y` inside a function that is
// itself differentiated with respect to `x`: the two derivatives are
// separate transformations, so `x` needs no lifting into the inner one
// (`diffPair(x, 0.0)` only says that `inner` holds it fixed). An unsuffixed
// float literal is a `float`, as in HLSL, so a pair made from literals alone
// needs them suffixed (`1.0l`) to be a pair of `double`s.

[Differentiable]
double f(double x)
{
    return x * x * x - 2.0 * x - 5.0;
}

void show(double x)
{
    // `rint` rounds ties to even.
    printf("%lld\n", int64_t(rint(x * 1000000.0)));
}

void derivatives(double x)
{
    show(f(x));
    show(fwd_diff(f)(diffPair(x, 1.0)).d);
    show(fwd_diff(fwd_diff(f))(diffPair(diffPair(x, 1.0), diffPair(1.0l, 0.0l))).d.d);
}

void newton(double x0, int steps)
{
    var x = x0;
    for (int i = 0; i < steps; i++)
    {
        let y = fwd_diff(f)(diffPair(x, 1.0));
        x = x - y.p / y.d;
        show(x);
    }
}

[Differentiable]
double sum(double x, double y)
{
    return x + y;
}

// d/dy (x + y) at y = 1.
[Differentiable]
double inner(double x)
{
    return fwd_diff(sum)(diffPair(x, 0.0), diffPair(1.0l, 1.0l)).d;
}

[Differentiable]
double outer(double x)
{
    return x * inner(x);
}

// d/dx (x * d/dy (x + y)) at x = 1, y = 1.
double nested(double at)
{
    return fwd_diff(outer)(diffPair(at, 1.0)).d;
}

export __extern_cpp int main()
{
    derivatives(2.0);
    newton(2.0, 4);
    show(nested(1.0));
    return 0;
}
