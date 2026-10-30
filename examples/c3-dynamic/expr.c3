// An interface: its methods can't be generic, so `ExprRef` is fixed once for
// every representation, and the global pool is an interface value whose calls
// are dispatched at run time.
module expr;
import std::io;
import std::collections::list;

enum BinOp { ADD, SUB, MUL, DIV }
typedef ExprRef = uint;
enum ExprKind { BINARY, LITERAL }
struct Expr
{
	ExprKind kind;
	union
	{
		struct binary { BinOp op; ExprRef lhs; ExprRef rhs; }
		long literal;
	}
}

interface Ast
{
	fn ExprRef add(Expr expr);
	fn Expr get(ExprRef expr);
}

Ast pool;

// C3's integer arithmetic wraps, and its division truncates.
fn long interp(ExprRef expr)
{
	Expr e = pool.get(expr);
	if (e.kind == LITERAL) return e.literal;
	long lhs = interp(e.binary.lhs);
	long rhs = interp(e.binary.rhs);
	switch (e.binary.op)
	{
		case ADD: return lhs + rhs;
		case SUB: return lhs - rhs;
		case MUL: return lhs * rhs;
		case DIV: return rhs == 0 ? 0 : lhs / rhs;
	}
}

fn ExprRef lit(long n) => pool.add({ .kind = LITERAL, .literal = n });
fn ExprRef bin(BinOp op, ExprRef lhs, ExprRef rhs) => pool.add({ .kind = BINARY, .binary = { op, lhs, rhs } });

// 0 means a literal.
fn long[3] encode(Expr expr)
{
	if (expr.kind == LITERAL) return { 0, expr.literal, 0 };
	return { (long)expr.binary.op.ordinal + 1, (long)expr.binary.lhs, (long)expr.binary.rhs };
}

fn Expr decode(long op, long lhs, long rhs)
{
	if (op == 0) return { .kind = LITERAL, .literal = lhs };
	return { .kind = BINARY, .binary = { (BinOp)(op - 1), (ExprRef)lhs, (ExprRef)rhs } };
}

// Representation 1: a node is an index into parallel lists.
struct Columns (Ast) { List{long} ops, lhs, rhs; }

fn ExprRef Columns.add(&self, Expr expr) @dynamic
{
	long[3] row = encode(expr);
	self.ops.push(row[0]);
	self.lhs.push(row[1]);
	self.rhs.push(row[2]);
	return (ExprRef)(self.ops.len() - 1);
}

fn Expr Columns.get(&self, ExprRef i) @dynamic
{
	sz j = (sz)i;
	return decode(self.ops[j], self.lhs[j], self.rhs[j]);
}

// Representation 2: a node is an index into one list of triples.
struct Triples (Ast) { List{long} triples; }

fn ExprRef Triples.add(&self, Expr expr) @dynamic
{
	self.triples.push_all(&&encode(expr));
	return (ExprRef)(self.triples.len() / 3 - 1);
}

fn Expr Triples.get(&self, ExprRef i) @dynamic
{
	sz j = 3 * (sz)i;
	return decode(self.triples[j], self.triples[j + 1], self.triples[j + 2]);
}

fn void main()
{
	Columns a;
	pool = &a;
	ExprRef e = bin(DIV, bin(MUL, bin(SUB, lit(7), lit(10)), lit(7)), lit(2));
	io::printn(interp(e));
	{
		Ast saved = pool;
		defer pool = saved;
		Triples b;
		pool = &b;
		io::printn(interp(bin(DIV, bin(ADD, lit(4), lit(4)), bin(SUB, lit(4), lit(4)))));
	}
	io::printn(interp(e));
}
