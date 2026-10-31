// Three traits, one per choice, each a type parameter: the pool is passed by
// reference and its index type is an associated type, while the arithmetic
// and the tracer are types with no value at all. Every function that builds
// or reads an `Expr` takes the pool, and `interp` and `report` take all
// three; nothing in their arguments mentions the tracer, so every call names
// it, and with it the others. A `Traced` node calls `interp::<P, V, Loud>`,
// a second instance in which tracing prints; monomorphization makes each
// instance as fast as hand-written code. The standard library's `Wrapping`
// and `Saturating` already implement the operators.
use std::num::{Saturating, Wrapping};
use std::ops::{Add, Div, Mul, Sub};

#[derive(Clone, Copy)]
enum BinOp {
    Add,
    Sub,
    Mul,
    Div,
}

#[derive(Clone, Copy)]
enum Expr<R> {
    Binary(BinOp, R, R),
    Literal(i32),
    // Evaluate the inner expression with tracing on.
    Traced(R),
}

// The pool: an index type, how to read a node through one, and how to make
// one.
trait Pool {
    type Ref: Copy;
    fn node(&self, expr: Self::Ref) -> Expr<Self::Ref>;
    fn add(&mut self, expr: Expr<Self::Ref>) -> Self::Ref;
}

// The arithmetic of the interpreted language: what a value is, what a
// literal means, and how to print one.
trait Arith:
    Copy + Add<Output = Self> + Sub<Output = Self> + Mul<Output = Self> + Div<Output = Self>
{
    fn value(n: i32) -> Self;
    fn print_value(self);
}

// Called with every intermediate value.
trait Trace {
    fn trace<V: Arith>(v: V);
}

struct Quiet;

impl Trace for Quiet {
    fn trace<V: Arith>(_: V) {}
}

struct Loud;

impl Trace for Loud {
    fn trace<V: Arith>(v: V) {
        print!("  ");
        v.print_value();
    }
}

// Written once, against the traits alone.
fn interp<P: Pool, V: Arith, T: Trace>(pool: &P, e: P::Ref) -> V {
    let v = match pool.node(e) {
        Expr::Binary(op, lhs, rhs) => {
            let l = interp::<P, V, T>(pool, lhs);
            let r = interp::<P, V, T>(pool, rhs);
            match op {
                BinOp::Add => l + r,
                BinOp::Sub => l - r,
                BinOp::Mul => l * r,
                BinOp::Div => l / r,
            }
        }
        Expr::Literal(n) => V::value(n),
        Expr::Traced(inner) => interp::<P, V, Loud>(pool, inner),
    };
    T::trace(v);
    v
}

fn report<P: Pool, V: Arith, T: Trace>(pool: &P, e: P::Ref) {
    interp::<P, V, T>(pool, e).print_value();
}

fn lit<P: Pool>(pool: &mut P, n: i32) -> P::Ref {
    pool.add(Expr::Literal(n))
}

fn bin<P: Pool>(pool: &mut P, op: BinOp, lhs: P::Ref, rhs: P::Ref) -> P::Ref {
    pool.add(Expr::Binary(op, lhs, rhs))
}

fn traced<P: Pool>(pool: &mut P, inner: P::Ref) -> P::Ref {
    pool.add(Expr::Traced(inner))
}

// A pool: a node is an index into one list of triples.
#[derive(Clone, Copy)]
struct Slot(u32);

#[derive(Default)]
struct Triples(Vec<i32>);

impl Pool for Triples {
    type Ref = Slot;

    fn node(&self, Slot(i): Slot) -> Expr<Slot> {
        let i = 3 * i as usize;
        let (code, a, b) = (self.0[i], self.0[i + 1], self.0[i + 2]);
        match code {
            0 => Expr::Literal(a),
            5 => Expr::Traced(Slot(a as u32)),
            _ => {
                let op = [BinOp::Add, BinOp::Sub, BinOp::Mul, BinOp::Div][code as usize - 1];
                Expr::Binary(op, Slot(a as u32), Slot(b as u32))
            }
        }
    }

    fn add(&mut self, expr: Expr<Slot>) -> Slot {
        let i = self.0.len() as u32 / 3;
        match expr {
            Expr::Binary(op, lhs, rhs) => {
                self.0.extend([op as i32 + 1, lhs.0 as i32, rhs.0 as i32])
            }
            Expr::Literal(n) => self.0.extend([0, n, 0]),
            Expr::Traced(inner) => self.0.extend([5, inner.0 as i32, 0]),
        }
        Slot(i)
    }
}

// Three meanings for the interpreted language's arithmetic.
impl Arith for Wrapping<i32> {
    fn value(n: i32) -> Self {
        Wrapping(n)
    }
    fn print_value(self) {
        println!("{self}");
    }
}

impl Arith for Saturating<i32> {
    fn value(n: i32) -> Self {
        Saturating(n)
    }
    fn print_value(self) {
        println!("{self}");
    }
}

impl Arith for f64 {
    fn value(n: i32) -> Self {
        n as f64
    }
    fn print_value(self) {
        println!("{}", self.round_ties_even() as i32);
    }
}

fn main() {
    use BinOp::*;
    let mut pool = Triples::default();
    // 50000 * 50000 / 100000 + traced((7 - 10) * 7 / 8)
    let (a, b) = (lit(&mut pool, 50000), lit(&mut pool, 50000));
    let prod = bin(&mut pool, Mul, a, b);
    let c = lit(&mut pool, 100000);
    let big = bin(&mut pool, Div, prod, c);
    let (d, e) = (lit(&mut pool, 7), lit(&mut pool, 10));
    let diff = bin(&mut pool, Sub, d, e);
    let f = lit(&mut pool, 7);
    let prod = bin(&mut pool, Mul, diff, f);
    let g = lit(&mut pool, 8);
    let quot = bin(&mut pool, Div, prod, g);
    let small = traced(&mut pool, quot);
    let e = bin(&mut pool, Add, big, small);
    report::<_, Wrapping<i32>, Quiet>(&pool, e);
    report::<_, Saturating<i32>, Quiet>(&pool, e);
    report::<_, f64, Quiet>(&pool, e);
}
