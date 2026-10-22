// The pool is passed explicitly.
use fmt;

type op = enum { LIT, ADD, MUL };
type node = struct { op: op, a: size, b: size };

fn push(p: *[]node, o: op, a: size, b: size) size = {
	append(p, node { op = o, a = a, b = b })!;
	return len(p) - 1;
};

fn lit(p: *[]node, n: size) size = push(p, op::LIT, n, 0);
fn add(p: *[]node, l: size, r: size) size = push(p, op::ADD, l, r);
fn mul(p: *[]node, l: size, r: size) size = push(p, op::MUL, l, r);

fn eval(p: *[]node, e: size) size = {
	const n = p[e];
	switch (n.op) {
	case op::LIT => return n.a;
	case op::ADD => return eval(p, n.a) + eval(p, n.b);
	case op::MUL => return eval(p, n.a) * eval(p, n.b);
	};
};

export fn main() void = {
	let a: []node = [];
	const e = mul(&a, add(&a, lit(&a, 1), lit(&a, 2)), add(&a, lit(&a, 3), lit(&a, 4)));
	fmt::println(eval(&a, e))!;
	{
		let b: []node = [];
		fmt::println(eval(&b, add(&b, lit(&b, 4), lit(&b, 4))))!;
	};
	fmt::println(eval(&a, e))!;
};
