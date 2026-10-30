// A global pool, swapped for a scope and restored by `defer`.
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
alias ExprPool = List{Expr};

ExprPool* pool;

fn ExprRef add(Expr expr)
{
	pool.push(expr);
	return (ExprRef)(pool.len() - 1);
}

fn Expr get(ExprRef expr) => (*pool)[(usz)expr];

// C3's integer arithmetic wraps, and its division truncates.
fn long interp(ExprRef expr)
{
	Expr e = get(expr);
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

fn ExprRef lit(long n) => add({ .kind = LITERAL, .literal = n });
fn ExprRef bin(BinOp op, ExprRef lhs, ExprRef rhs) => add({ .kind = BINARY, .binary = { op, lhs, rhs } });

fn void main()
{
	ExprPool a;
	pool = &a;
	ExprRef e = bin(DIV, bin(MUL, bin(SUB, lit(7), lit(10)), lit(7)), lit(2));
	io::printn(interp(e));
	{
		ExprPool* saved = pool;
		defer pool = saved;
		ExprPool b;
		pool = &b;
		io::printn(interp(bin(DIV, bin(ADD, lit(4), lit(4)), bin(SUB, lit(4), lit(4)))));
	}
	io::printn(interp(e));
}
