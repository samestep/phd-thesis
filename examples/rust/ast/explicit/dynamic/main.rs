// Dynamic dispatch over the representation: a trait object can't leave the
// index type open, so `ExprRef` is fixed once for every representation.

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

trait Ast {
    fn add(&mut self, expr: Expr) -> ExprRef;
    fn get(&self, expr: ExprRef) -> Expr;
}

fn interp(ast: &dyn Ast, expr: ExprRef) -> i64 {
    match ast.get(expr) {
        Expr::Binary(op, lhs, rhs) => {
            let lhs = interp(ast, lhs);
            let rhs = interp(ast, rhs);
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

fn lit(ast: &mut dyn Ast, n: i64) -> ExprRef {
    ast.add(Expr::Literal(n))
}

fn bin(ast: &mut dyn Ast, op: BinOp, lhs: ExprRef, rhs: ExprRef) -> ExprRef {
    ast.add(Expr::Binary(op, lhs, rhs))
}

fn code(op: BinOp) -> i64 {
    op as i64 + 1
}

fn op_of(code: i64) -> BinOp {
    [BinOp::Add, BinOp::Sub, BinOp::Mul, BinOp::Div][code as usize - 1]
}

// Representation 1: a node is an index into parallel lists.
#[derive(Default)]
struct Columns {
    ops: Vec<i64>,
    lhs: Vec<i64>,
    rhs: Vec<i64>,
}

impl Ast for Columns {
    fn add(&mut self, expr: Expr) -> ExprRef {
        let (op, lhs, rhs) = match expr {
            Expr::Binary(op, lhs, rhs) => (code(op), lhs.0 as i64, rhs.0 as i64),
            Expr::Literal(num) => (0, num, 0),
        };
        self.ops.push(op);
        self.lhs.push(lhs);
        self.rhs.push(rhs);
        ExprRef(self.ops.len() as u32 - 1)
    }

    fn get(&self, ExprRef(i): ExprRef) -> Expr {
        let i = i as usize;
        match self.ops[i] {
            0 => Expr::Literal(self.lhs[i]),
            op => Expr::Binary(op_of(op), ExprRef(self.lhs[i] as u32), ExprRef(self.rhs[i] as u32)),
        }
    }
}

// Representation 2: a node is an index into one list of triples.
#[derive(Default)]
struct Triples(Vec<i64>);

impl Ast for Triples {
    fn add(&mut self, expr: Expr) -> ExprRef {
        match expr {
            Expr::Binary(op, lhs, rhs) => self.0.extend([code(op), lhs.0 as i64, rhs.0 as i64]),
            Expr::Literal(num) => self.0.extend([0, num, 0]),
        }
        ExprRef(self.0.len() as u32 / 3 - 1)
    }

    fn get(&self, ExprRef(i): ExprRef) -> Expr {
        let i = 3 * i as usize;
        match self.0[i] {
            0 => Expr::Literal(self.0[i + 1]),
            op => Expr::Binary(op_of(op), ExprRef(self.0[i + 1] as u32), ExprRef(self.0[i + 2] as u32)),
        }
    }
}

fn main() {
    use BinOp::*;
    let mut pool: Box<dyn Ast> = Box::new(Columns::default());
    let (seven, ten) = (lit(&mut *pool, 7), lit(&mut *pool, 10));
    let diff = bin(&mut *pool, Sub, seven, ten);
    let seven = lit(&mut *pool, 7);
    let prod = bin(&mut *pool, Mul, diff, seven);
    let two = lit(&mut *pool, 2);
    let e = bin(&mut *pool, Div, prod, two);
    println!("{}", interp(&*pool, e));
    {
        let mut pool: Box<dyn Ast> = Box::new(Triples::default());
        let (a, b) = (lit(&mut *pool, 4), lit(&mut *pool, 4));
        let (c, d) = (lit(&mut *pool, 4), lit(&mut *pool, 4));
        let sum = bin(&mut *pool, Add, a, b);
        let diff = bin(&mut *pool, Sub, c, d);
        let f = bin(&mut *pool, Div, sum, diff);
        println!("{}", interp(&*pool, f));
    }
    println!("{}", interp(&*pool, e));
}
