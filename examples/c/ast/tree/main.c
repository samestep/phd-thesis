// The tree Sampson starts from: each node points to its children, so nothing
// needs a pool, but every node is its own `malloc` and must be freed in turn.
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

typedef enum { ADD, SUB, MUL, DIV } BinOp;
typedef struct Expr {
  enum { BINARY, LITERAL } kind;
  union {
    struct { BinOp op; struct Expr *lhs, *rhs; } binary;
    int64_t literal;
  };
} Expr;

static Expr *new_expr(Expr expr) {
  Expr *e = malloc(sizeof(Expr));
  *e = expr;
  return e;
}

static void free_expr(Expr *e) {
  if (e->kind == BINARY) {
    free_expr(e->binary.lhs);
    free_expr(e->binary.rhs);
  }
  free(e);
}

static int64_t interp(const Expr *e) {
  if (e->kind == LITERAL) return e->literal;
  // Wrapping arithmetic, through unsigned integers.
  uint64_t lhs = interp(e->binary.lhs), rhs = interp(e->binary.rhs);
  switch (e->binary.op) {
  case ADD: return lhs + rhs;
  case SUB: return lhs - rhs;
  case MUL: return lhs * rhs;
  default: return rhs ? (int64_t)lhs / (int64_t)rhs : 0;
  }
}

static Expr *lit(int64_t n) { return new_expr((Expr){.kind = LITERAL, .literal = n}); }
static Expr *bin(BinOp op, Expr *lhs, Expr *rhs) {
  return new_expr((Expr){.kind = BINARY, .binary = {op, lhs, rhs}});
}

int main(void) {
  Expr *e = bin(DIV, bin(MUL, bin(SUB, lit(7), lit(10)), lit(7)), lit(2));
  printf("%ld\n", (long)interp(e));
  {
    Expr *f = bin(DIV, bin(ADD, lit(4), lit(4)), bin(SUB, lit(4), lit(4)));
    printf("%ld\n", (long)interp(f));
    free_expr(f);
  }
  printf("%ld\n", (long)interp(e));
  free_expr(e);
}
