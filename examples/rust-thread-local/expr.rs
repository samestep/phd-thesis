// A thread_local! pool, set for the duration of a closure and then restored.
use std::cell::RefCell;

#[derive(Clone, Copy)]
enum Node {
    Lit(i64),
    Add(usize, usize),
    Mul(usize, usize),
}

thread_local! {
    static POOL: RefCell<Vec<Node>> = RefCell::new(Vec::new());
}

fn with_pool<T>(f: impl FnOnce() -> T) -> T {
    let saved = POOL.take();
    let result = f();
    POOL.set(saved);
    result
}

fn push(node: Node) -> usize {
    POOL.with_borrow_mut(|pool| {
        pool.push(node);
        pool.len() - 1
    })
}

fn lit(n: i64) -> usize {
    push(Node::Lit(n))
}

fn add(l: usize, r: usize) -> usize {
    push(Node::Add(l, r))
}

fn mul(l: usize, r: usize) -> usize {
    push(Node::Mul(l, r))
}

fn eval(e: usize) -> i64 {
    match POOL.with_borrow(|pool| pool[e]) {
        Node::Lit(n) => n,
        Node::Add(l, r) => eval(l) + eval(r),
        Node::Mul(l, r) => eval(l) * eval(r),
    }
}

fn main() {
    let e = mul(add(lit(1), lit(2)), add(lit(3), lit(4)));
    println!("{}", eval(e));
    with_pool(|| println!("{}", eval(add(lit(4), lit(4)))));
    println!("{}", eval(e));
}
