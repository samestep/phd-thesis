// A global pool, saved and restored around a scope.
#include <stdio.h>
#include <stdlib.h>

typedef enum { LIT, ADD, MUL } Op;
typedef struct { Op op; long a, b; } Node;
typedef struct { Node *nodes; size_t len, cap; } Pool;

static Pool *pool;

static long push(Op op, long a, long b) {
  if (pool->len == pool->cap) {
    pool->cap = pool->cap ? 2 * pool->cap : 8;
    pool->nodes = realloc(pool->nodes, pool->cap * sizeof(Node));
  }
  pool->nodes[pool->len] = (Node){op, a, b};
  return pool->len++;
}

static long lit(long n) { return push(LIT, n, 0); }
static long add(long l, long r) { return push(ADD, l, r); }
static long mul(long l, long r) { return push(MUL, l, r); }

static long eval(long e) {
  Node n = pool->nodes[e];
  switch (n.op) {
  case LIT: return n.a;
  case ADD: return eval(n.a) + eval(n.b);
  default: return eval(n.a) * eval(n.b);
  }
}

int main(void) {
  Pool a = {0};
  pool = &a;
  long e = mul(add(lit(1), lit(2)), add(lit(3), lit(4)));
  printf("%ld\n", eval(e));
  {
    Pool *saved = pool;
    Pool b = {0};
    pool = &b;
    printf("%ld\n", eval(add(lit(4), lit(4))));
    pool = saved;
  }
  printf("%ld\n", eval(e));
}
