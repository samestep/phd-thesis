// For each start value, the Collatz trajectory down to 1 is built as a
// temporary list in an arena, and only two numbers are kept from it: how
// many steps it took, and the largest value on the way. The arena is reset
// between start values.
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct {
  char *base;
  size_t used, cap;
} Arena;

static void *arena_alloc(Arena *a, size_t size) {
  size = (size + 15) & ~(size_t)15;
  if (a->used + size > a->cap) abort();
  void *p = a->base + a->used;
  a->used += size;
  return p;
}

static void arena_reset(Arena *a) { a->used = 0; }

// A growable list whose buffers come from an arena: growing copies into a
// new buffer and leaves the old one to be dropped with the rest.
typedef struct {
  uint64_t *items;
  size_t len, cap;
} List;

static void push(Arena *a, List *list, uint64_t x) {
  if (list->len == list->cap) {
    size_t cap = list->cap ? 2 * list->cap : 8;
    uint64_t *items = arena_alloc(a, cap * sizeof *items);
    if (list->len) memcpy(items, list->items, list->len * sizeof *items);
    list->items = items;
    list->cap = cap;
  }
  list->items[list->len++] = x;
}

typedef struct {
  size_t steps;
  uint64_t peak;
} Summary;

static Summary summarize(Arena *a, uint64_t start) {
  List path = {0};
  uint64_t n = start;
  push(a, &path, n);
  while (n != 1) {
    n = n % 2 == 0 ? n / 2 : 3 * n + 1;
    push(a, &path, n);
  }
  uint64_t peak = path.items[0];
  for (size_t i = 1; i < path.len; i++)
    if (path.items[i] > peak) peak = path.items[i];
  return (Summary){path.len - 1, peak};
}

int main(void) {
  Arena arena = {malloc(1 << 16), 0, 1 << 16};
  uint64_t starts[] = {6, 7, 27, 97};
  for (size_t i = 0; i < sizeof starts / sizeof *starts; i++) {
    Summary s = summarize(&arena, starts[i]);
    printf("%llu %zu %llu\n", (unsigned long long)starts[i], s.steps,
           (unsigned long long)s.peak);
    arena_reset(&arena);
  }
  free(arena.base);
}
