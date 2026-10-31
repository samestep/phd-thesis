// Generic over the representation: the index type is an associated type,
// and every function that touches an `Expr` takes a type parameter and the
// pool.

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
    Literal(i64),
}

trait Ast {
    type Ref: Copy;
    fn add(&mut self, expr: Expr<Self::Ref>) -> Self::Ref;
    fn get(&self, expr: Self::Ref) -> Expr<Self::Ref>;
}

fn interp<A: Ast>(ast: &A, expr: A::Ref) -> i64 {
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

fn lit<A: Ast>(ast: &mut A, n: i64) -> A::Ref {
    ast.add(Expr::Literal(n))
}

fn bin<A: Ast>(ast: &mut A, op: BinOp, lhs: A::Ref, rhs: A::Ref) -> A::Ref {
    ast.add(Expr::Binary(op, lhs, rhs))
}

fn code(op: BinOp) -> i64 {
    op as i64 + 1
}

fn op_of(code: i64) -> BinOp {
    [BinOp::Add, BinOp::Sub, BinOp::Mul, BinOp::Div][code as usize - 1]
}

// Representation 1: a node is an index into parallel lists.
#[derive(Clone, Copy)]
struct Idx(u32);

#[derive(Default)]
struct Columns {
    ops: Vec<i64>,
    lhs: Vec<i64>,
    rhs: Vec<i64>,
}

impl Ast for Columns {
    type Ref = Idx;

    fn add(&mut self, expr: Expr<Idx>) -> Idx {
        let (op, lhs, rhs) = match expr {
            Expr::Binary(op, lhs, rhs) => (code(op), lhs.0 as i64, rhs.0 as i64),
            Expr::Literal(num) => (0, num, 0),
        };
        self.ops.push(op);
        self.lhs.push(lhs);
        self.rhs.push(rhs);
        Idx(self.ops.len() as u32 - 1)
    }

    fn get(&self, Idx(i): Idx) -> Expr<Idx> {
        let i = i as usize;
        match self.ops[i] {
            0 => Expr::Literal(self.lhs[i]),
            op => Expr::Binary(op_of(op), Idx(self.lhs[i] as u32), Idx(self.rhs[i] as u32)),
        }
    }
}

// Representation 2: a node is an index into one list of triples.
#[derive(Clone, Copy)]
struct Slot(u32);

#[derive(Default)]
struct Triples(Vec<i64>);

impl Ast for Triples {
    type Ref = Slot;

    fn add(&mut self, expr: Expr<Slot>) -> Slot {
        match expr {
            Expr::Binary(op, lhs, rhs) => self.0.extend([code(op), lhs.0 as i64, rhs.0 as i64]),
            Expr::Literal(num) => self.0.extend([0, num, 0]),
        }
        Slot(self.0.len() as u32 / 3 - 1)
    }

    fn get(&self, Slot(i): Slot) -> Expr<Slot> {
        let i = 3 * i as usize;
        match self.0[i] {
            0 => Expr::Literal(self.0[i + 1]),
            op => Expr::Binary(op_of(op), Slot(self.0[i + 1] as u32), Slot(self.0[i + 2] as u32)),
        }
    }
}

fn main() {
    use BinOp::*;
    let mut pool = Columns::default();
    let (seven, ten) = (lit(&mut pool, 7), lit(&mut pool, 10));
    let diff = bin(&mut pool, Sub, seven, ten);
    let seven = lit(&mut pool, 7);
    let prod = bin(&mut pool, Mul, diff, seven);
    let two = lit(&mut pool, 2);
    let e = bin(&mut pool, Div, prod, two);
    println!("{}", interp(&pool, e));
    {
        let mut pool = Triples::default();
        let (a, b) = (lit(&mut pool, 4), lit(&mut pool, 4));
        let (c, d) = (lit(&mut pool, 4), lit(&mut pool, 4));
        let sum = bin(&mut pool, Add, a, b);
        let diff = bin(&mut pool, Sub, c, d);
        let f = bin(&mut pool, Div, sum, diff);
        println!("{}", interp(&pool, f));
    }
    println!("{}", interp(&pool, e));
}
