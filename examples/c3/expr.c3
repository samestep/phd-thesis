// A global pool, swapped for a scope and restored by `defer`.
module expr;
import std::io;
import std::collections::list;

enum Op { LIT, ADD, MUL }
struct Node { Op op; long a; long b; }
alias Pool = List{Node};

Pool* pool;

fn long push(Op op, long a, long b)
{
	pool.push({ op, a, b });
	return pool.len() - 1;
}

fn long lit(long n) => push(LIT, n, 0);
fn long add(long l, long r) => push(ADD, l, r);
fn long mul(long l, long r) => push(MUL, l, r);

fn long eval(long e)
{
	Node n = (*pool)[e];
	switch (n.op)
	{
		case LIT: return n.a;
		case ADD: return eval(n.a) + eval(n.b);
		case MUL: return eval(n.a) * eval(n.b);
	}
}

fn void main()
{
	Pool a;
	pool = &a;
	long e = mul(add(lit(1), lit(2)), add(lit(3), lit(4)));
	io::printn(eval(e));
	{
		Pool* saved = pool;
		defer pool = saved;
		Pool b;
		pool = &b;
		io::printn(eval(add(lit(4), lit(4))));
	}
	io::printn(eval(e));
}
