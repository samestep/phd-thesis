// The pool has to be passed to everything that touches an `Expr`.

#[derive(Clone, Copy)]
struct Expr(u32);

enum Node {
    Lit(i64),
    Add(Expr, Expr),
    Mul(Expr, Expr),
}

#[derive(Default)]
struct Pool(Vec<Node>);

impl Pool {
    fn push(&mut self, node: Node) -> Expr {
        self.0.push(node);
        Expr(self.0.len() as u32 - 1)
    }

    fn lit(&mut self, n: i64) -> Expr {
        self.push(Node::Lit(n))
    }

    fn add(&mut self, l: Expr, r: Expr) -> Expr {
        self.push(Node::Add(l, r))
    }

    fn mul(&mut self, l: Expr, r: Expr) -> Expr {
        self.push(Node::Mul(l, r))
    }

    fn eval(&self, e: Expr) -> i64 {
        match self.0[e.0 as usize] {
            Node::Lit(n) => n,
            Node::Add(l, r) => self.eval(l) + self.eval(r),
            Node::Mul(l, r) => self.eval(l) * self.eval(r),
        }
    }
}

fn main() {
    let mut pool = Pool::default();
    let (a, b) = (pool.lit(1), pool.lit(2));
    let (c, d) = (pool.lit(3), pool.lit(4));
    let (ab, cd) = (pool.add(a, b), pool.add(c, d));
    let e = pool.mul(ab, cd);
    println!("{}", pool.eval(e));
    {
        let mut pool = Pool::default();
        let (x, y) = (pool.lit(4), pool.lit(4));
        let f = pool.add(x, y);
        println!("{}", pool.eval(f));
    }
    println!("{}", pool.eval(e));
}
