// An interface: its methods can't take type parameters, so `ExprRef` is fixed
// once for every representation, and the context holds the interface value.
package main

import (
	"context"
	"fmt"
)

type BinOp int

const (
	Add BinOp = iota + 1 // 0 means a literal.
	Sub
	Mul
	Div
)

type ExprRef uint32

type Expr interface{ isExpr() }
type Binary struct {
	Op       BinOp
	Lhs, Rhs ExprRef
}
type Literal int64

func (Binary) isExpr()  {}
func (Literal) isExpr() {}

type Ast interface {
	Add(expr Expr) ExprRef
	Get(expr ExprRef) Expr
}

type poolKey struct{}

func pool(ctx context.Context) Ast { return ctx.Value(poolKey{}).(Ast) }

func withPool(ctx context.Context, ast Ast) context.Context {
	return context.WithValue(ctx, poolKey{}, ast)
}

// Go's integer arithmetic wraps, and its division truncates.
func interp(ctx context.Context, expr ExprRef) int64 {
	switch e := pool(ctx).Get(expr).(type) {
	case Binary:
		lhs, rhs := interp(ctx, e.Lhs), interp(ctx, e.Rhs)
		switch e.Op {
		case Add:
			return lhs + rhs
		case Sub:
			return lhs - rhs
		case Mul:
			return lhs * rhs
		default:
			if rhs == 0 {
				return 0
			}
			return lhs / rhs
		}
	default:
		return int64(e.(Literal))
	}
}

func lit(ctx context.Context, n int64) ExprRef { return pool(ctx).Add(Literal(n)) }
func bin(ctx context.Context, op BinOp, lhs, rhs ExprRef) ExprRef {
	return pool(ctx).Add(Binary{op, lhs, rhs})
}

func node(op, lhs, rhs int64) Expr {
	if op == 0 {
		return Literal(lhs)
	}
	return Binary{BinOp(op), ExprRef(lhs), ExprRef(rhs)}
}

// Representation 1: a node is an index into parallel lists.
type Columns struct{ ops, lhs, rhs []int64 }

func (c *Columns) Add(expr Expr) ExprRef {
	switch e := expr.(type) {
	case Binary:
		c.ops, c.lhs, c.rhs = append(c.ops, int64(e.Op)), append(c.lhs, int64(e.Lhs)), append(c.rhs, int64(e.Rhs))
	case Literal:
		c.ops, c.lhs, c.rhs = append(c.ops, 0), append(c.lhs, int64(e)), append(c.rhs, 0)
	}
	return ExprRef(len(c.ops) - 1)
}

func (c *Columns) Get(i ExprRef) Expr { return node(c.ops[i], c.lhs[i], c.rhs[i]) }

// Representation 2: a node is an index into one list of triples.
type Triples []int64

func (t *Triples) Add(expr Expr) ExprRef {
	switch e := expr.(type) {
	case Binary:
		*t = append(*t, int64(e.Op), int64(e.Lhs), int64(e.Rhs))
	case Literal:
		*t = append(*t, 0, int64(e), 0)
	}
	return ExprRef(len(*t)/3 - 1)
}

func (t *Triples) Get(i ExprRef) Expr { return node((*t)[3*i], (*t)[3*i+1], (*t)[3*i+2]) }

func main() {
	ctx := withPool(context.Background(), &Columns{})
	e := bin(ctx, Div, bin(ctx, Mul, bin(ctx, Sub, lit(ctx, 7), lit(ctx, 10)), lit(ctx, 7)), lit(ctx, 2))
	fmt.Println(interp(ctx, e))
	{
		ctx := withPool(ctx, &Triples{})
		fmt.Println(interp(ctx, bin(ctx, Div, bin(ctx, Add, lit(ctx, 4), lit(ctx, 4)), bin(ctx, Sub, lit(ctx, 4), lit(ctx, 4)))))
	}
	fmt.Println(interp(ctx, e))
}
