// Generics over a trait for real numbers, implemented for `f64` and for a
// double-double type written here (the `twofloat` crate has one too). Each
// instance is compiled separately, as fast as hand-written code. To make
// the routine rerunnable it had to be written for this from the start:
// every function generic in `T: Real`; `T` named at every call that has no
// argument of that type (`readings::<T>()`, `report::<T>()`); every literal
// built in `T`, `T::from(100000002) / T::from(10)`, since `10000000.2` is an
// `f64` and Rust won't mix it with a `T`; and every buffer and accumulator
// declared at `T`. Unlike C++, the compiler catches a `Vec<f64>` or an
// `f64` accumulator left in the generic code, as a type error. Lifting the
// f64 readings is `DoubleDouble::from`, exact.
use std::ops::{Add, Div, Mul, Sub};

trait Real:
    Copy
    + PartialOrd
    + From<i32>
    + Add<Output = Self>
    + Sub<Output = Self>
    + Mul<Output = Self>
    + Div<Output = Self>
{
    fn sqrt(self) -> Self;
    fn round(self) -> i64;
}

impl Real for f64 {
    fn sqrt(self) -> f64 {
        f64::sqrt(self)
    }
    fn round(self) -> i64 {
        self.round_ties_even() as i64
    }
}

// `hi + lo`, with `|lo|` at most half an ulp of `hi`: 106 bits. Compared
// as the pair `(hi, lo)`, which is exactly right for such a sum.
#[derive(Clone, Copy, PartialEq, PartialOrd)]
struct DoubleDouble {
    hi: f64,
    lo: f64,
}

fn quick_two_sum(s: f64, e: f64) -> DoubleDouble {
    let hi = s + e;
    DoubleDouble {
        hi,
        lo: e - (hi - s),
    }
}

fn two_sum(a: f64, b: f64) -> DoubleDouble {
    let s = a + b;
    let bb = s - a;
    DoubleDouble {
        hi: s,
        lo: (a - (s - bb)) + (b - bb),
    }
}

fn two_prod(a: f64, b: f64) -> DoubleDouble {
    let p = a * b;
    DoubleDouble {
        hi: p,
        lo: a.mul_add(b, -p),
    }
}

impl From<f64> for DoubleDouble {
    fn from(x: f64) -> Self {
        DoubleDouble { hi: x, lo: 0.0 }
    }
}

impl From<i32> for DoubleDouble {
    fn from(n: i32) -> Self {
        DoubleDouble::from(f64::from(n))
    }
}

impl Add for DoubleDouble {
    type Output = Self;
    fn add(self, b: Self) -> Self {
        let s = two_sum(self.hi, b.hi);
        let t = two_sum(self.lo, b.lo);
        let u = quick_two_sum(s.hi, s.lo + t.hi);
        quick_two_sum(u.hi, u.lo + t.lo)
    }
}

impl Sub for DoubleDouble {
    type Output = Self;
    fn sub(self, b: Self) -> Self {
        self + DoubleDouble {
            hi: -b.hi,
            lo: -b.lo,
        }
    }
}

impl Mul for DoubleDouble {
    type Output = Self;
    fn mul(self, b: Self) -> Self {
        let p = two_prod(self.hi, b.hi);
        quick_two_sum(p.hi, p.lo + (self.hi * b.lo + self.lo * b.hi))
    }
}

impl Div for DoubleDouble {
    type Output = Self;
    fn div(self, b: Self) -> Self {
        let q1 = self.hi / b.hi;
        let r1 = self - b * DoubleDouble::from(q1);
        let q2 = r1.hi / b.hi;
        let r2 = r1 - b * DoubleDouble::from(q2);
        let q3 = r2.hi / b.hi;
        quick_two_sum(q1, q2) + DoubleDouble::from(q3)
    }
}

impl Real for DoubleDouble {
    fn sqrt(self) -> Self {
        if self.hi <= 0.0 {
            return DoubleDouble::from(self.hi.sqrt());
        }
        let x = self.hi.sqrt();
        let r = self - two_prod(x, x);
        quick_two_sum(x, r.hi / (x + x))
    }
    fn round(self) -> i64 {
        let n = self.hi.round_ties_even();
        let d = self.hi - n;
        let up = (d == 0.5 && self.lo > 0.0) as i64;
        let down = (d == -0.5 && self.lo < 0.0) as i64;
        n as i64 + up - down
    }
}

// NIST StRD NumAcc4: 10000000.2, then 10000000.1 and 10000000.3 in turn.
fn readings<T: Real>() -> Vec<T> {
    let ten = T::from(10);
    let mut xs = vec![T::from(100000002) / ten];
    for i in 1..1001 {
        xs.push(if i % 2 == 1 {
            T::from(100000001) / ten
        } else {
            T::from(100000003) / ten
        });
    }
    xs
}

// The schoolbook one-pass formula, as PostgreSQL's `stddev` computed it
// until version 12, clamp included.
fn sd<T: Real>(xs: &[T]) -> T {
    let zero = T::from(0);
    let one = T::from(1);
    let (mut n, mut sum, mut sum_sq) = (zero, zero, zero);
    for &x in xs {
        n = n + one;
        sum = sum + x;
        sum_sq = sum_sq + x * x;
    }
    let numerator = n * sum_sq - sum * sum;
    if numerator <= zero {
        zero
    } else {
        (numerator / (n * (n - one))).sqrt()
    }
}

fn show<T: Real>(sd: T) {
    println!("{}", (sd * T::from(1000000000)).round());
}

fn report<T: Real>() {
    show(sd(&readings::<T>()));
}

fn main() {
    report::<f64>();
    let xs = readings::<f64>();
    let lifted: Vec<DoubleDouble> = xs.iter().map(|&x| DoubleDouble::from(x)).collect();
    show(sd(&lifted));
    report::<DoubleDouble>();
}
