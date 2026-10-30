// Dynamic dispatch through a struct of function pointers: C has no generics,
// so `ExprRef` is fixed once for every representation, and every `add` and
// `get` is an indirect call.
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

// Starting at 1 leaves 0 to mean a literal.
typedef enum { ADD = 1, SUB, MUL, DIV } BinOp;
typedef uint32_t ExprRef;
typedef struct {
  enum { BINARY, LITERAL } kind;
  union {
    struct { BinOp op; ExprRef lhs, rhs; } binary;
    int64_t literal;
  };
} Expr;

typedef struct Ast Ast;
struct Ast {
  ExprRef (*add)(Ast *ast, Expr expr);
  Expr (*get)(const Ast *ast, ExprRef expr);
};

static Ast *pool;

static ExprRef add(Expr expr) { return pool->add(pool, expr); }
static Expr get(ExprRef expr) { return pool->get(pool, expr); }

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

typedef struct { int64_t *items; size_t len, cap; } Ints;

static void push(Ints *v, int64_t x) {
  if (v->len == v->cap) {
    v->cap = v->cap ? 2 * v->cap : 8;
    v->items = realloc(v->items, v->cap * sizeof(int64_t));
  }
  v->items[v->len++] = x;
}

static Expr node(int64_t op, int64_t lhs, int64_t rhs) {
  if (op == 0) return (Expr){.kind = LITERAL, .literal = lhs};
  return (Expr){.kind = BINARY, .binary = {op, lhs, rhs}};
}

// Representation 1: a node is an index into parallel lists.
typedef struct { Ast ast; Ints ops, lhs, rhs; } Columns;

static ExprRef columns_add(Ast *ast, Expr expr) {
  Columns *c = (Columns *)ast;
  if (expr.kind == LITERAL) {
    push(&c->ops, 0), push(&c->lhs, expr.literal), push(&c->rhs, 0);
  } else {
    push(&c->ops, expr.binary.op), push(&c->lhs, expr.binary.lhs), push(&c->rhs, expr.binary.rhs);
  }
  return c->ops.len - 1;
}

static Expr columns_get(const Ast *ast, ExprRef i) {
  const Columns *c = (const Columns *)ast;
  return node(c->ops.items[i], c->lhs.items[i], c->rhs.items[i]);
}

// Representation 2: a node is an index into one list of triples.
typedef struct { Ast ast; Ints triples; } Triples;

static ExprRef triples_add(Ast *ast, Expr expr) {
  Ints *t = &((Triples *)ast)->triples;
  if (expr.kind == LITERAL) {
    push(t, 0), push(t, expr.literal), push(t, 0);
  } else {
    push(t, expr.binary.op), push(t, expr.binary.lhs), push(t, expr.binary.rhs);
  }
  return t->len / 3 - 1;
}

static Expr triples_get(const Ast *ast, ExprRef i) {
  const int64_t *t = &((const Triples *)ast)->triples.items[3 * i];
  return node(t[0], t[1], t[2]);
}

int main(void) {
  Columns a = {.ast = {columns_add, columns_get}};
  pool = &a.ast;
  ExprRef e = bin(DIV, bin(MUL, bin(SUB, lit(7), lit(10)), lit(7)), lit(2));
  printf("%ld\n", (long)interp(e));
  {
    Ast *saved = pool;
    Triples b = {.ast = {triples_add, triples_get}};
    pool = &b.ast;
    printf("%ld\n", (long)interp(bin(DIV, bin(ADD, lit(4), lit(4)), bin(SUB, lit(4), lit(4)))));
    pool = saved;
  }
  printf("%ld\n", (long)interp(e));
}
