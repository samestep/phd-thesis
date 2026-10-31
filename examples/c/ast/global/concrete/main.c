// A global pool, saved and restored around a scope.
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

typedef enum { ADD, SUB, MUL, DIV } BinOp;
typedef uint32_t ExprRef;
typedef struct {
  enum { BINARY, LITERAL } kind;
  union {
    struct { BinOp op; ExprRef lhs, rhs; } binary;
    int64_t literal;
  };
} Expr;
typedef struct { Expr *exprs; size_t len, cap; } ExprPool;

static ExprPool *pool;

static ExprRef add(Expr expr) {
  if (pool->len == pool->cap) {
    pool->cap = pool->cap ? 2 * pool->cap : 8;
    pool->exprs = realloc(pool->exprs, pool->cap * sizeof(Expr));
  }
  pool->exprs[pool->len] = expr;
  return pool->len++;
}

static Expr get(ExprRef expr) { return pool->exprs[expr]; }

static int64_t interp(ExprRef expr) {
  Expr e = get(expr);
  if (e.kind == LITERAL) return e.literal;
  // Wrapping arithmetic, through unsigned integers.
  uint64_t lhs = interp(e.binary.lhs), rhs = interp(e.binary.rhs);
  switch (e.binary.op) {
  case ADD: return lhs + rhs;
  case SUB: return lhs - rhs;
  case MUL: return lhs * rhs;
  default: return rhs ? (int64_t)lhs / (int64_t)rhs : 0;
  }
}

static ExprRef lit(int64_t n) { return add((Expr){.kind = LITERAL, .literal = n}); }
static ExprRef bin(BinOp op, ExprRef lhs, ExprRef rhs) {
  return add((Expr){.kind = BINARY, .binary = {op, lhs, rhs}});
}

int main(void) {
  ExprPool a = {0};
  pool = &a;
  ExprRef e = bin(DIV, bin(MUL, bin(SUB, lit(7), lit(10)), lit(7)), lit(2));
  printf("%ld\n", (long)interp(e));
  {
    ExprPool *saved = pool;
    ExprPool b = {0};
    pool = &b;
    printf("%ld\n", (long)interp(bin(DIV, bin(ADD, lit(4), lit(4)), bin(SUB, lit(4), lit(4)))));
    pool = saved;
  }
  printf("%ld\n", (long)interp(e));
}
