// The tree Sampson starts from: each node owns its children through a `Box`,
// so nothing needs a pool, but every node is its own heap allocation. The
// types and the interpreter are his, verbatim (flatcalc's `main` branch);
// the rest builds two expressions in place of his parser.

/// The arithmetic operators our language supports.
#[derive(Debug)]
enum BinOp {
    Add,
    Sub,
    Mul,
    Div,
}

/// Our little programming language.
#[derive(Debug)]
enum Expr {
    Binary(BinOp, Box<Expr>, Box<Expr>),
    Literal(i64),
}

impl Expr {
    /// Evaluate the expression.
    fn interp(&self) -> i64 {
        match self {
            Expr::Binary(op, lhs, rhs) => {
                let lhs = lhs.interp();
                let rhs = rhs.interp();
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
    println!("{}", e.interp());
    {
        let f = bin(Div, bin(Add, lit(4), lit(4)), bin(Sub, lit(4), lit(4)));
        println!("{}", f.interp());
    }
    println!("{}", e.interp());
}
