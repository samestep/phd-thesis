// Generic modules: `interp`, `lit` and `bin` live in a module parameterized by
// the pool type and its index type, so the global pool is one variable per
// instantiation, and every use names both types.
module expr;
import std::io;
import std::collections::list;
import expr::node, expr::ast;

enum BinOp { ADD, SUB, MUL, DIV }
enum ExprKind { BINARY, LITERAL }

// Representation 1: a node is an index into parallel lists.
typedef Idx = uint;
struct Columns { List{long} ops, lhs, rhs; }

fn Idx Columns.add(&self, Expr{Idx} expr)
{
	long[3] row = node::encode{Idx}(expr);
	self.ops.push(row[0]);
	self.lhs.push(row[1]);
	self.rhs.push(row[2]);
	return (Idx)(self.ops.len() - 1);
}

fn Expr{Idx} Columns.get(&self, Idx i)
{
	sz j = (sz)i;
	return node::decode{Idx}(self.ops[j], self.lhs[j], self.rhs[j]);
}

// Representation 2: a node is an index into one list of triples.
typedef Slot = uint;
struct Triples { List{long} triples; }

fn Slot Triples.add(&self, Expr{Slot} expr)
{
	self.triples.push_all(&&node::encode{Slot}(expr));
	return (Slot)(self.triples.len() / 3 - 1);
}

fn Expr{Slot} Triples.get(&self, Slot i)
{
	sz j = 3 * (sz)i;
	return node::decode{Slot}(self.triples[j], self.triples[j + 1], self.triples[j + 2]);
}

alias interp_a = ast::interp{Columns, Idx};
alias lit_a = ast::lit{Columns, Idx};
alias bin_a = ast::bin{Columns, Idx};
alias interp_b = ast::interp{Triples, Slot};
alias lit_b = ast::lit{Triples, Slot};
alias bin_b = ast::bin{Triples, Slot};

fn void main()
{
	Columns a;
	ast::pool{Columns, Idx} = &a;
	Idx e = bin_a(DIV, bin_a(MUL, bin_a(SUB, lit_a(7), lit_a(10)), lit_a(7)), lit_a(2));
	io::printn(interp_a(e));
	{
		Triples* saved = ast::pool{Triples, Slot};
		defer ast::pool{Triples, Slot} = saved;
		Triples b;
		ast::pool{Triples, Slot} = &b;
		io::printn(interp_b(bin_b(DIV, bin_b(ADD, lit_b(4), lit_b(4)), bin_b(SUB, lit_b(4), lit_b(4)))));
	}
	io::printn(interp_a(e));
}

module expr::node <Ref>;
import expr;

struct Expr
{
	ExprKind kind;
	union
	{
		struct binary { BinOp op; Ref lhs; Ref rhs; }
		long literal;
	}
}

// 0 means a literal.
fn long[3] encode(Expr expr)
{
	if (expr.kind == LITERAL) return { 0, expr.literal, 0 };
	return { (long)expr.binary.op.ordinal + 1, (long)expr.binary.lhs, (long)expr.binary.rhs };
}

fn Expr decode(long op, long lhs, long rhs)
{
	if (op == 0) return { .kind = LITERAL, .literal = lhs };
	return { .kind = BINARY, .binary = { (BinOp)(op - 1), (Ref)lhs, (Ref)rhs } };
}

module expr::ast <Pool, Ref>;
import expr, expr::node;

Pool* pool;

// C3's integer arithmetic wraps, and its division truncates.
fn long interp(Ref expr)
{
	Expr{Ref} e = pool.get(expr);
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

fn Ref lit(long n) => pool.add({ .kind = LITERAL, .literal = n });
fn Ref bin(BinOp op, Ref lhs, Ref rhs) => pool.add({ .kind = BINARY, .binary = { op, lhs, rhs } });
