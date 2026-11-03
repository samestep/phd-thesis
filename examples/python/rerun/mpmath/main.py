# mpmath's working precision, set for a dynamic extent: `workprec(106)`
# reaches everything called inside it, with nothing passed down, and `mpf`
# arithmetic rounds to whatever precision is in force when it runs, so the
# same `sd` serves both runs and needs no lifting of its input (outside
# any `workprec`, the precision is mpmath's default, 53 bits). But only
# `mpf`s follow it, so the routine has to be written with `mpf` from the
# start: a Python float literal is rounded to a double before any `mpf`
# sees it (`mpf(10000000.2)` is 10000000.1999999992549...), so the
# literals are strings; an accumulator that only ever adds floats stays a
# float; and `math.sqrt` silently returns one. There is one representation
# for every precision, an arbitrary-precision float whose precision is
# read at run time, so 53 bits stands in for f64 (the same correctly
# rounded operations, but not its exponent range) and nothing is
# specialized.
from mpmath import mpf, nint, sqrt, workprec


# NIST StRD NumAcc4: 10000000.2, then 10000000.1 and 10000000.3 in turn.
def readings():
    xs = [mpf("10000000.2")]
    for i in range(1, 1001):
        xs.append(mpf("10000000.1") if i % 2 == 1 else mpf("10000000.3"))
    return xs


# The schoolbook one-pass formula, as PostgreSQL's `stddev` computed it
# until version 12, clamp included.
def sd(xs):
    n = mpf(0)
    total = mpf(0)
    total_sq = mpf(0)
    for x in xs:
        n += 1
        total += x
        total_sq += x * x
    numerator = n * total_sq - total * total
    if numerator <= 0:
        return mpf(0)
    return sqrt(numerator / (n * (n - 1)))


def show(sd):
    print(int(nint(sd * 1000000000)))


def report():
    show(sd(readings()))


report()
xs = readings()
with workprec(106):
    show(sd(xs))
with workprec(106):
    report()
