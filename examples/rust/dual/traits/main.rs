// A trait for the arithmetic, implemented by `f64` and by `Dual<F>` for any
// `F` that implements it, so duals nest, and every function in the program is
// generic over it: each signature names `<F: Field>` or `<R: Real>` (a field
// that can also round), and the compiler infers it at each call. Generic code
// can't write a float literal, so `f` writes `F::constant(2.0)`.
// `Dual<Dual<R>>` and `Dual<R>` are different types, so `nested` has to lift
// the outer variable into the inner differentiation (`still(x)`): adding it
// as it is (`x + variable(y0)`) is a compile-time error, since there is no
// `Dual<R> + Dual<Dual<R>>`. Monomorphization makes each instance as fast as
// hand-written code.
use std::ops::{Add, Div, Mul, Sub};

trait Field:
    Copy + Add<Output = Self> + Sub<Output = Self> + Mul<Output = Self> + Div<Output = Self>
{
    fn constant(n: f64) -> Self;
}

trait Real: Field {
    fn round(self) -> i64;
}

impl Field for f64 {
    fn constant(n: f64) -> f64 {
        n
    }
}

impl Real for f64 {
    fn round(self) -> i64 {
        self.round_ties_even() as i64
    }
}

fn f<F: Field>(x: F) -> F {
    x * x * x - F::constant(2.0) * x - F::constant(5.0)
}

#[derive(Clone, Copy)]
struct Dual<F> {
    v: F,
    d: F,
}

fn variable<F: Field>(x: F) -> Dual<F> {
    Dual { v: x, d: F::constant(1.0) }
}

fn still<F: Field>(x: F) -> Dual<F> {
    Dual { v: x, d: F::constant(0.0) }
}

impl<F: Field> Field for Dual<F> {
    fn constant(n: f64) -> Dual<F> {
        still(F::constant(n))
    }
}

impl<F: Field> Add for Dual<F> {
    type Output = Dual<F>;
    fn add(self, rhs: Dual<F>) -> Dual<F> {
        Dual { v: self.v + rhs.v, d: self.d + rhs.d }
    }
}

impl<F: Field> Sub for Dual<F> {
    type Output = Dual<F>;
    fn sub(self, rhs: Dual<F>) -> Dual<F> {
        Dual { v: self.v - rhs.v, d: self.d - rhs.d }
    }
}

impl<F: Field> Mul for Dual<F> {
    type Output = Dual<F>;
    fn mul(self, rhs: Dual<F>) -> Dual<F> {
        Dual { v: self.v * rhs.v, d: self.d * rhs.v + self.v * rhs.d }
    }
}

impl<F: Field> Div for Dual<F> {
    type Output = Dual<F>;
    fn div(self, rhs: Dual<F>) -> Dual<F> {
        Dual {
            v: self.v / rhs.v,
            d: (self.d * rhs.v - self.v * rhs.d) / (rhs.v * rhs.v),
        }
    }
}

fn show<R: Real>(x: R) {
    println!("{}", (x * R::constant(1000000.0)).round());
}

fn derivatives<R: Real>(x: R) {
    show(f(x));
    show(f(variable(x)).d);
    show(f(variable(variable(x))).d.d);
}

fn newton<R: Real>(x0: R, steps: usize) {
    let mut x = x0;
    for _ in 0..steps {
        let y = f(variable(x));
        x = x - y.v / y.d;
        show(x);
    }
}

// d/dx (x * d/dy (x + y)) at x = 1, y = 1.
fn nested<R: Real>(at: R) -> R {
    let x = variable(at);
    let y0 = Dual::constant(1.0);
    let inner = (still(x) + variable(y0)).d;
    (x * inner).d
}

fn main() {
    derivatives(2.0);
    newton(2.0, 4);
    show(nested(1.0));
}
