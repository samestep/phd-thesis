// PostgreSQL's float8 standard deviation as of version 11, the last before
// it changed formulas, and the same code rerun in double-double, which C
// can only do by writing it again. `float8_accum` and `float8_stddev_samp`
// are PostgreSQL's own lines (vendor/postgres/src/backend/utils/adt/float.c
// has them all; a check keeps these in it, in order), less the aggregate
// plumbing that passes the running sums as a SQL array, and the overflow
// checks; `PG_RETURN_FLOAT8` and `PG_RETURN_NULL` are defined to return.
// `dd_accum` and `dd_stddev_samp` are them rewritten by hand: every
// variable, literal and operator. Output, in billionths: the standard
// deviation of NIST's NumAcc4 data in float8 (0: the clamp hides a negative
// numerator); in double-double over the same float8 readings; and in
// double-double from the data's own decimal values, NIST's certified 0.1.
#include <math.h>
#include <stdio.h>

typedef double float8;

#define PG_RETURN_FLOAT8(x) return (x)
#define PG_RETURN_NULL() return NAN

// NIST StRD NumAcc4: 10000000.2, then 10000000.1 and 10000000.3 in turn.
#define READINGS 1001

static float8
reading(int i)
{
	return i == 0 ? 10000000.2 : i % 2 == 1 ? 10000000.1 : 10000000.3;
}

static void
float8_accum(float8 *transvalues, float8 newval)
{
	float8		N,
				sumX,
				sumX2;

	N = transvalues[0];
	sumX = transvalues[1];
	sumX2 = transvalues[2];

	N += 1.0;
	sumX += newval;
	sumX2 += newval * newval;

	transvalues[0] = N;
	transvalues[1] = sumX;
	transvalues[2] = sumX2;
}

static float8
float8_stddev_samp(float8 *transvalues)
{
	float8		N,
				sumX,
				sumX2,
				numerator;

	N = transvalues[0];
	sumX = transvalues[1];
	sumX2 = transvalues[2];

	/* Sample stddev is undefined when N is 0 or 1, so return NULL */
	if (N <= 1.0)
		PG_RETURN_NULL();

	numerator = N * sumX2 - sumX * sumX;

	/* Watch out for roundoff error producing a negative numerator */
	if (numerator <= 0.0)
		PG_RETURN_FLOAT8(0.0);

	PG_RETURN_FLOAT8(sqrt(numerator / (N * (N - 1.0))));
}

// `hi + lo`, with `|lo|` at most half an ulp of `hi`: 106 bits.
typedef struct
{
	double		hi,
				lo;
} dd;

static dd
dd_from(double x)
{
	return (dd) {x, 0.0};
}

static dd
quick_two_sum(double s, double e)
{
	double		hi = s + e;

	return (dd) {hi, e - (hi - s)};
}

static dd
two_sum(double a, double b)
{
	double		s = a + b;
	double		bb = s - a;

	return (dd) {s, (a - (s - bb)) + (b - bb)};
}

static dd
dd_add(dd a, dd b)
{
	dd			s = two_sum(a.hi, b.hi);
	dd			t = two_sum(a.lo, b.lo);

	s = quick_two_sum(s.hi, s.lo + t.hi);
	return quick_two_sum(s.hi, s.lo + t.lo);
}

static dd
dd_neg(dd a)
{
	return (dd) {-a.hi, -a.lo};
}

static dd
dd_sub(dd a, dd b)
{
	return dd_add(a, dd_neg(b));
}

static dd
dd_mul(dd a, dd b)
{
	double		p = a.hi * b.hi;
	double		e = fma(a.hi, b.hi, -p);

	return quick_two_sum(p, e + (a.hi * b.lo + a.lo * b.hi));
}

static dd
dd_div(dd a, dd b)
{
	double		q1 = a.hi / b.hi;
	dd			r = dd_sub(a, dd_mul(dd_from(q1), b));
	double		q2 = r.hi / b.hi;

	r = dd_sub(r, dd_mul(dd_from(q2), b));
	return dd_add(quick_two_sum(q1, q2), dd_from(r.hi / b.hi));
}

static dd
dd_sqrt(dd a)
{
	double		s = sqrt(a.hi);
	dd			r = dd_sub(a, dd_mul(dd_from(s), dd_from(s)));

	return quick_two_sum(s, r.hi / (2.0 * s));
}

static int
dd_le(dd a, dd b)
{
	return a.hi < b.hi || (a.hi == b.hi && a.lo <= b.lo);
}

static dd
dd_reading(int i)
{
	double		tenths = i == 0 ? 100000002 : i % 2 == 1 ? 100000001 : 100000003;

	return dd_div(dd_from(tenths), dd_from(10));
}

static void
dd_accum(dd *transvalues, dd newval)
{
	dd			N,
				sumX,
				sumX2;

	N = transvalues[0];
	sumX = transvalues[1];
	sumX2 = transvalues[2];

	N = dd_add(N, dd_from(1.0));
	sumX = dd_add(sumX, newval);
	sumX2 = dd_add(sumX2, dd_mul(newval, newval));

	transvalues[0] = N;
	transvalues[1] = sumX;
	transvalues[2] = sumX2;
}

static dd
dd_stddev_samp(dd *transvalues)
{
	dd			N,
				sumX,
				sumX2,
				numerator;

	N = transvalues[0];
	sumX = transvalues[1];
	sumX2 = transvalues[2];

	if (dd_le(N, dd_from(1.0)))
		return dd_from(NAN);

	numerator = dd_sub(dd_mul(N, sumX2), dd_mul(sumX, sumX));

	if (dd_le(numerator, dd_from(0.0)))
		return dd_from(0.0);

	return dd_sqrt(dd_div(numerator, dd_mul(N, dd_sub(N, dd_from(1.0)))));
}

int
main(void)
{
	float8		transvalues[3] = {0.0, 0.0, 0.0};
	dd			widened[3] = {dd_from(0.0), dd_from(0.0), dd_from(0.0)};
	dd			exact[3] = {dd_from(0.0), dd_from(0.0), dd_from(0.0)};

	for (int i = 0; i < READINGS; i++)
	{
		float8_accum(transvalues, reading(i));
		dd_accum(widened, dd_from(reading(i)));
		dd_accum(exact, dd_reading(i));
	}
	printf("%lld\n", llround(float8_stddev_samp(transvalues) * 1000000000.0));
	printf("%lld\n", llround(dd_mul(dd_stddev_samp(widened), dd_from(1000000000.0)).hi));
	printf("%lld\n", llround(dd_mul(dd_stddev_samp(exact), dd_from(1000000000.0)).hi));
	return 0;
}
