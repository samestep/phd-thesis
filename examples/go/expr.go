// A context.Context carrying the pool, passed down explicitly.
package main

import (
	"context"
	"fmt"
)

type op int

const (
	lit op = iota
	add
	mul
)

type node struct {
	op   op
	a, b int
}

type poolKey struct{}

func pool(ctx context.Context) *[]node { return ctx.Value(poolKey{}).(*[]node) }

func withPool(ctx context.Context) context.Context {
	return context.WithValue(ctx, poolKey{}, &[]node{})
}

func push(ctx context.Context, o op, a, b int) int {
	p := pool(ctx)
	*p = append(*p, node{o, a, b})
	return len(*p) - 1
}

func Lit(ctx context.Context, n int) int    { return push(ctx, lit, n, 0) }
func Add(ctx context.Context, l, r int) int { return push(ctx, add, l, r) }
func Mul(ctx context.Context, l, r int) int { return push(ctx, mul, l, r) }

func eval(ctx context.Context, e int) int {
	n := (*pool(ctx))[e]
	switch n.op {
	case lit:
		return n.a
	case add:
		return eval(ctx, n.a) + eval(ctx, n.b)
	default:
		return eval(ctx, n.a) * eval(ctx, n.b)
	}
}

func main() {
	ctx := withPool(context.Background())
	e := Mul(ctx, Add(ctx, Lit(ctx, 1), Lit(ctx, 2)), Add(ctx, Lit(ctx, 3), Lit(ctx, 4)))
	fmt.Println(eval(ctx, e))
	{
		ctx := withPool(ctx)
		fmt.Println(eval(ctx, Add(ctx, Lit(ctx, 4), Lit(ctx, 4))))
	}
	fmt.Println(eval(ctx, e))
}
