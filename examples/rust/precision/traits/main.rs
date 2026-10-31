// Two traits, one per choice, and both are type parameters of every function
// in the chain: each signature repeats `<C: Compute, S: Storage<C>>`. Inside
// the chain the compiler infers them from the bounds in scope, but `report`
// has no argument that mentions either, so it names them for `scaled`, and
// `main` names them for `report`. Generic code can't write a float literal, so
// every constant is an associated const of the compute trait;
// monomorphization makes each instance as fast as hand-written code.
use std::ops::{Add, Mul};

trait Compute: Copy + Add<Output = Self> + Mul<Output = Self> {
    const ZERO: Self;
    const TENTH: Self;
    const THOUSAND: Self;
    fn round(self) -> i64;
}

impl Compute for f64 {
    const ZERO: f64 = 0.0;
    const TENTH: f64 = 0.1;
    const THOUSAND: f64 = 1000.0;
    fn round(self) -> i64 {
        self.round_ties_even() as i64
    }
}

impl Compute for f32 {
    const ZERO: f32 = 0.0;
    const TENTH: f32 = 0.1;
    const THOUSAND: f32 = 1000.0;
    fn round(self) -> i64 {
        self.round_ties_even() as i64
    }
}

trait Storage<C>: Copy {
    fn narrow(x: C) -> Self;
    fn widen(self) -> C;
}

impl<C: Compute> Storage<C> for C {
    fn narrow(x: C) -> C {
        x
    }
    fn widen(self) -> C {
        self
    }
}

impl Storage<f64> for f32 {
    fn narrow(x: f64) -> f32 {
        x as f32
    }
    fn widen(self) -> f64 {
        self as f64
    }
}

fn fill<C: Compute, S: Storage<C>>(n: usize) -> Vec<S> {
    let mut xs = Vec::new();
    for _ in 0..n {
        xs.push(S::narrow(C::TENTH));
    }
    xs
}

fn accumulate<C: Compute, S: Storage<C>>(xs: &[S], from: usize, to: usize) -> C {
    let mut sum = C::ZERO;
    for &x in &xs[from..to] {
        sum = sum + x.widen();
    }
    sum
}

fn total<C: Compute, S: Storage<C>>(xs: &[S], n: usize) -> C {
    accumulate(xs, 0, n)
}

fn scaled<C: Compute, S: Storage<C>>(xs: &[S], n: usize) -> i64 {
    (total(xs, n) * C::THOUSAND).round()
}

fn report<C: Compute, S: Storage<C>>(n: usize) {
    println!("{}", scaled::<C, S>(&fill(n), n));
}

fn main() {
    // Compute in f64, store in f64.
    report::<f64, f64>(1000000);
    // Compute in f64, store in f32: half the memory.
    report::<f64, f32>(1000000);
    // Compute in f32, store in f32.
    report::<f32, f32>(1000000);
}
