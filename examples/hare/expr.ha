// The pool is passed explicitly.
use fmt;

type binop = enum { ADD, SUB, MUL, DIV };
type exprref = size;
type binary = struct { op: binop, lhs: exprref, rhs: exprref };
type literal = i64;
type expr = (binary | literal);
type exprpool = []expr;

fn add(p: *exprpool, e: expr) exprref = {
	append(p, e)!;
	return len(p) - 1;
};

fn get(p: *exprpool, e: exprref) expr = p[e];

// Hare's integer arithmetic wraps, and its division truncates.
fn interp(p: *exprpool, e: exprref) i64 = {
	match (get(p, e)) {
	case let b: binary =>
		const lhs = interp(p, b.lhs), rhs = interp(p, b.rhs);
		switch (b.op) {
		case binop::ADD => return lhs + rhs;
		case binop::SUB => return lhs - rhs;
		case binop::MUL => return lhs * rhs;
		case binop::DIV => return if (rhs == 0) 0 else lhs / rhs;
		};
	case let num: literal =>
		return num;
	};
};

fn lit(p: *exprpool, n: i64) exprref = add(p, n: literal);
fn bin(p: *exprpool, op: binop, lhs: exprref, rhs: exprref) exprref =
	add(p, binary { op = op, lhs = lhs, rhs = rhs });

export fn main() void = {
	let a: exprpool = [];
	const e = bin(&a, binop::DIV,
		bin(&a, binop::MUL, bin(&a, binop::SUB, lit(&a, 7), lit(&a, 10)), lit(&a, 7)),
		lit(&a, 2));
	fmt::println(interp(&a, e))!;
	{
		let b: exprpool = [];
		fmt::println(interp(&b, bin(&b, binop::DIV,
			bin(&b, binop::ADD, lit(&b, 4), lit(&b, 4)),
			bin(&b, binop::SUB, lit(&b, 4), lit(&b, 4)))))!;
	};
	fmt::println(interp(&a, e))!;
};
