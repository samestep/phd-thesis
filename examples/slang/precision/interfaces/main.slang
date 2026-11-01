// Two interfaces, one per choice, and both are type parameters of every
// function in the chain: each signature repeats `<C : ICompute, S :
// IStorage<C>, let N : int>`. Inside the chain the compiler infers `S` and
// `N` from the arguments, but never `C`, which no argument mentions, so each
// call names it, and `main` names all three for `report`. `double` and
// `float` conform through extensions, and a generic extension makes every
// compute type its own storage. Generic code can't write a float literal, so
// every constant is a static of the compute interface. Slang has no heap, so
// the numbers are a local array whose length is a generic value parameter;
// an array argument is copied unless it's `inout`, so the chain takes it
// `inout`. Each instance is specialized at compile time, as fast as
// hand-written code.

interface ICompute
{
    static const This zero;
    static const This tenth;
    static const This thousand;
    This add(This other);
    This mul(This other);
    int64_t round();
}

extension double : ICompute
{
    // An unsuffixed literal is a `float`, as in HLSL.
    static const double zero = 0.0l;
    static const double tenth = 0.1l;
    static const double thousand = 1000.0l;
    double add(double other) { return this + other; }
    double mul(double other) { return this * other; }
    // `rint` rounds ties to even.
    int64_t round() { return int64_t(rint(this)); }
}

extension float : ICompute
{
    static const float zero = 0.0;
    static const float tenth = 0.1;
    static const float thousand = 1000.0;
    float add(float other) { return this + other; }
    float mul(float other) { return this * other; }
    int64_t round() { return int64_t(rint(this)); }
}

interface IStorage<C>
{
    static This narrow(C x);
    C widen();
}

extension<C : ICompute> C : IStorage<C>
{
    static C narrow(C x) { return x; }
    C widen() { return this; }
}

extension float : IStorage<double>
{
    static float narrow(double x) { return float(x); }
    double widen() { return this; }
}

void fill<C : ICompute, S : IStorage<C>, let N : int>(out S xs[N])
{
    for (int i = 0; i < N; i++)
        xs[i] = S.narrow(C.tenth);
}

C accumulate<C : ICompute, S : IStorage<C>, let N : int>(inout S xs[N], int from, int to)
{
    C sum = C.zero;
    for (int i = from; i < to; i++)
        sum = sum.add(xs[i].widen());
    return sum;
}

C total<C : ICompute, S : IStorage<C>, let N : int>(inout S xs[N])
{
    return accumulate<C>(xs, 0, N);
}

int64_t scaled<C : ICompute, S : IStorage<C>, let N : int>(inout S xs[N])
{
    return total<C>(xs).mul(C.thousand).round();
}

void report<C : ICompute, S : IStorage<C>, let N : int>()
{
    S xs[N];
    fill<C>(xs);
    printf("%lld\n", scaled<C>(xs));
}

export __extern_cpp int main()
{
    // Compute in double, store in double.
    report<double, double, 1000000>();
    // Compute in double, store in float: half the memory.
    report<double, float, 1000000>();
    // Compute in float, store in float.
    report<float, float, 1000000>();
    return 0;
}
