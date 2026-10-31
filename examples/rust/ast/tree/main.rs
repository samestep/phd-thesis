// The tree Sampson starts from: each node owns its children through a `Box`,
// so nothing needs a pool, but every node is its own heap allocation.

enum BinOp {
    Add,
    Sub,
    Mul,
    Div,
}

enum Expr {
    Binary(BinOp, Box<Expr>, Box<Expr>),
    Literal(i64),
}

fn interp(expr: &Expr) -> i64 {
    match expr {
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
        Expr::Literal(num) => *num,
    }
}

fn lit(n: i64) -> Box<Expr> {
    Box::new(Expr::Literal(n))
}

fn bin(op: BinOp, lhs: Box<Expr>, rhs: Box<Expr>) -> Box<Expr> {
    Box::new(Expr::Binary(op, lhs, rhs))
}

fn main() {
    use BinOp::*;
    let e = bin(Div, bin(Mul, bin(Sub, lit(7), lit(10)), lit(7)), lit(2));
    println!("{}", interp(&e));
    {
        let f = bin(Div, bin(Add, lit(4), lit(4)), bin(Sub, lit(4), lit(4)));
        println!("{}", interp(&f));
    }
    println!("{}", interp(&e));
}
