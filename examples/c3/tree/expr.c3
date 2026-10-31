// The tree Sampson starts from: each node points to its children, so nothing
// needs a pool, but every node is its own heap allocation and must be freed.
module expr;
import std::io;

enum BinOp { ADD, SUB, MUL, DIV }
enum ExprKind { BINARY, LITERAL }
struct Expr
{
	ExprKind kind;
	union
	{
		struct binary { BinOp op; Expr* lhs; Expr* rhs; }
		long literal;
	}
}

fn void Expr.free(&self)
{
	if (self.kind == BINARY)
	{
		self.binary.lhs.free();
		self.binary.rhs.free();
	}
	mem::free(self);
}

// C3's integer arithmetic wraps, and its division truncates.
fn long interp(Expr* e)
{
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

fn Expr* lit(long n) => mem::new(Expr, { .kind = LITERAL, .literal = n });
fn Expr* bin(BinOp op, Expr* lhs, Expr* rhs) => mem::new(Expr, { .kind = BINARY, .binary = { op, lhs, rhs } });

fn void main()
{
	Expr* e = bin(DIV, bin(MUL, bin(SUB, lit(7), lit(10)), lit(7)), lit(2));
	defer e.free();
	io::printn(interp(e));
	{
		Expr* f = bin(DIV, bin(ADD, lit(4), lit(4)), bin(SUB, lit(4), lit(4)));
		defer f.free();
		io::printn(interp(f));
	}
	io::printn(interp(e));
}
