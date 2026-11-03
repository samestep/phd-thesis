// The pool has to be passed to everything that touches an `Expr`. The types
// and the pool's methods but `default` are Sampson's, verbatim (flatcalc's
// `flat` branch); his `default` reserves room for 100 million nodes, for his
// benchmark, and the rest builds two expressions in place of his parser.

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
    Binary(BinOp, ExprRef, ExprRef),
    Literal(i64),
}

/// The thing we use instead of pointers to refer to expressions.
///
/// In this "flattened" implementation, references are just indices into a vector where the `Expr`s
/// are stored. We use the "newtype" pattern instead of a plain `u32` here to clarify where the
/// reference is supposed to be used.
#[derive(Debug, Clone, Copy)]
struct ExprRef(u32);

/// An "arena" for storing expressions that can refer to each other.
///
/// This is just a plain, dense array where a family of `Expr`s live.
struct ExprPool(Vec<Expr>);

impl ExprPool {
    /// Create an empty pool.
    fn default() -> Self {
        Self(Vec::new())
    }

    /// Dereference an AST node reference, obtaining the underlying `Expr`.
    fn get(&self, expr: ExprRef) -> &Expr {
        &self.0[expr.0 as usize]
    }

    /// Add an expression to the pool and get a reference to it.
    fn add(&mut self, expr: Expr) -> ExprRef {
        let idx = self.0.len();
        self.0.push(expr);
        ExprRef(idx.try_into().expect("too many exprs in the pool"))
    }

    fn interp(&self, expr: ExprRef) -> i64 {
        match self.get(expr) {
            Expr::Binary(op, lhs, rhs) => {
                let lhs = self.interp(*lhs);
                let rhs = self.interp(*rhs);
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
