// The pool has to be passed to everything that touches an `Expr`.

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

#[derive(Default)]
struct ExprPool(Vec<Expr>);

impl ExprPool {
    fn add(&mut self, expr: Expr) -> ExprRef {
        self.0.push(expr);
        ExprRef(self.0.len() as u32 - 1)
    }

    fn get(&self, expr: ExprRef) -> Expr {
        self.0[expr.0 as usize]
    }

    fn interp(&self, expr: ExprRef) -> i64 {
        match self.get(expr) {
            Expr::Binary(op, lhs, rhs) => {
                let lhs = self.interp(lhs);
                let rhs = self.interp(rhs);
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

    fn lit(&mut self, n: i64) -> ExprRef {
        self.add(Expr::Literal(n))
    }

    fn bin(&mut self, op: BinOp, lhs: ExprRef, rhs: ExprRef) -> ExprRef {
        self.add(Expr::Binary(op, lhs, rhs))
    }
}

fn main() {
    use BinOp::*;
    let mut pool = ExprPool::default();
    let (seven, ten) = (pool.lit(7), pool.lit(10));
    let diff = pool.bin(Sub, seven, ten);
    let seven = pool.lit(7);
    let prod = pool.bin(Mul, diff, seven);
    let two = pool.lit(2);
    let e = pool.bin(Div, prod, two);
    println!("{}", pool.interp(e));
    {
        let mut pool = ExprPool::default();
        let (a, b, c, d) = (pool.lit(4), pool.lit(4), pool.lit(4), pool.lit(4));
        let sum = pool.bin(Add, a, b);
        let diff = pool.bin(Sub, c, d);
        let f = pool.bin(Div, sum, diff);
        println!("{}", pool.interp(f));
    }
    println!("{}", pool.interp(e));
}
