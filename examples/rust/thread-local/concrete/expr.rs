// A thread_local! pool, set for the duration of a closure and then restored.
use std::cell::RefCell;

#[derive(Clone, Copy)]
enum BinOp {
    Add,
    Sub,
    Mul,
    Div,
}

#[derive(Clone, Copy)]
struct ExprRef(u32);

#[derive(Clone, Copy)]
enum Expr {
    Binary(BinOp, ExprRef, ExprRef),
    Literal(i64),
}

thread_local! {
    static POOL: RefCell<Vec<Expr>> = RefCell::new(Vec::new());
}

fn with_pool<T>(f: impl FnOnce() -> T) -> T {
    let saved = POOL.take();
    let result = f();
    POOL.set(saved);
    result
}

fn add(expr: Expr) -> ExprRef {
    POOL.with_borrow_mut(|pool| {
        pool.push(expr);
        ExprRef(pool.len() as u32 - 1)
    })
}

fn get(expr: ExprRef) -> Expr {
    POOL.with_borrow(|pool| pool[expr.0 as usize])
}

fn interp(expr: ExprRef) -> i64 {
    match get(expr) {
        Expr::Binary(op, lhs, rhs) => {
            let lhs = interp(lhs);
            let rhs = interp(rhs);
            match op {
                BinOp::Add => lhs.wrapping_add(rhs),
                BinOp::Sub => lhs.wrapping_sub(rhs),
                BinOp::Mul => lhs.wrapping_mul(rhs),
                BinOp::Div => lhs.checked_div(rhs).unwrap_or(0),
            }
        }
        Expr::Literal(num) => num,
    }
}

fn lit(n: i64) -> ExprRef {
    add(Expr::Literal(n))
}

fn bin(op: BinOp, lhs: ExprRef, rhs: ExprRef) -> ExprRef {
    add(Expr::Binary(op, lhs, rhs))
}

fn main() {
    use BinOp::*;
    let e = bin(Div, bin(Mul, bin(Sub, lit(7), lit(10)), lit(7)), lit(2));
    println!("{}", interp(e));
    with_pool(|| println!("{}", interp(bin(Div, bin(Add, lit(4), lit(4)), bin(Sub, lit(4), lit(4))))));
    println!("{}", interp(e));
}
