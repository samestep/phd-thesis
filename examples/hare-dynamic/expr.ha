// A vtable pointer, as in Hare's own io::stream: Hare has no generics, so
// `exprref` is fixed once for every representation, and every `add` and `get`
// is an indirect call.
use fmt;

type binop = enum { ADD = 1, SUB, MUL, DIV }; // 0 means a literal.
type exprref = size;
type binary = struct { op: binop, lhs: exprref, rhs: exprref };
type literal = i64;
type expr = (binary | literal);

type adder = fn(p: *ast, e: expr) exprref;
type getter = fn(p: *ast, e: exprref) expr;
type vtable = struct { adder: *adder, getter: *getter };
type ast = *vtable;

fn add(p: *ast, e: expr) exprref = p.adder(p, e);

fn get(p: *ast, e: exprref) expr = p.getter(p, e);

// Hare's integer arithmetic wraps, and its division truncates.
fn interp(p: *ast, e: exprref) i64 = {
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

fn lit(p: *ast, n: i64) exprref = add(p, n: literal);
fn bin(p: *ast, op: binop, lhs: exprref, rhs: exprref) exprref =
	add(p, binary { op = op, lhs = lhs, rhs = rhs });

fn row(e: expr) [3]i64 = {
	match (e) {
	case let b: binary =>
		return [b.op: i64, b.lhs: i64, b.rhs: i64];
	case let num: literal =>
		return [0, num, 0];
	};
};

fn node(op: i64, lhs: i64, rhs: i64) expr = {
	if (op == 0) return lhs: literal;
	return binary { op = op: binop, lhs = lhs: exprref, rhs = rhs: exprref };
};

// Representation 1: a node is an index into parallel lists.
type columns = struct { ast: ast, ops: []i64, lhs: []i64, rhs: []i64 };

const columns_vt: vtable = vtable { adder = &columns_add, getter = &columns_get };

fn columns_add(p: *ast, e: expr) exprref = {
	let c = p: *columns, r = row(e);
	append(c.ops, r[0])!;
	append(c.lhs, r[1])!;
	append(c.rhs, r[2])!;
	return len(c.ops) - 1;
};

fn columns_get(p: *ast, i: exprref) expr = {
	const c = p: *columns;
	return node(c.ops[i], c.lhs[i], c.rhs[i]);
};

// Representation 2: a node is an index into one list of triples.
type triples = struct { ast: ast, triples: []i64 };

const triples_vt: vtable = vtable { adder = &triples_add, getter = &triples_get };

fn triples_add(p: *ast, e: expr) exprref = {
	const t = p: *triples;
	append(t.triples, row(e)...)!;
	return len(t.triples) / 3 - 1;
};

fn triples_get(p: *ast, i: exprref) expr = {
	const t = (p: *triples).triples;
	return node(t[3 * i], t[3 * i + 1], t[3 * i + 2]);
};

export fn main() void = {
	let a = columns { ast = &columns_vt, ... };
	const e = bin(&a, binop::DIV,
		bin(&a, binop::MUL, bin(&a, binop::SUB, lit(&a, 7), lit(&a, 10)), lit(&a, 7)),
		lit(&a, 2));
	fmt::println(interp(&a, e))!;
	{
		let b = triples { ast = &triples_vt, ... };
		fmt::println(interp(&b, bin(&b, binop::DIV,
			bin(&b, binop::ADD, lit(&b, 4), lit(&b, 4)),
			bin(&b, binop::SUB, lit(&b, 4), lit(&b, 4)))))!;
	};
	fmt::println(interp(&a, e))!;
};
