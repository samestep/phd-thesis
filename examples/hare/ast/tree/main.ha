// The tree Sampson starts from: each node points to its children, so nothing
// needs a pool, but every node is its own allocation and must be freed.
use fmt;

type binop = enum { ADD, SUB, MUL, DIV };
type binary = struct { op: binop, lhs: *expr, rhs: *expr };
type literal = i64;
type expr = (binary | literal);

fn expr_free(e: *expr) void = {
	match (*e) {
	case let b: binary =>
		expr_free(b.lhs);
		expr_free(b.rhs);
	case literal => void;
	};
	free(e);
};

// Hare's integer arithmetic wraps, and its division truncates.
fn interp(e: *expr) i64 = {
	match (*e) {
	case let b: binary =>
		const lhs = interp(b.lhs), rhs = interp(b.rhs);
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

fn lit(n: i64) *expr = alloc(n: literal: expr)!;
fn bin(op: binop, lhs: *expr, rhs: *expr) *expr =
	alloc(binary { op = op, lhs = lhs, rhs = rhs }: expr)!;

export fn main() void = {
	const e = bin(binop::DIV,
		bin(binop::MUL, bin(binop::SUB, lit(7), lit(10)), lit(7)),
		lit(2));
	defer expr_free(e);
	fmt::println(interp(e))!;
	{
		const f = bin(binop::DIV,
			bin(binop::ADD, lit(4), lit(4)),
			bin(binop::SUB, lit(4), lit(4)));
		defer expr_free(f);
		fmt::println(interp(f))!;
	};
	fmt::println(interp(e))!;
};
