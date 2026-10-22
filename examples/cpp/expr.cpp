// A thread_local pool pointer, swapped by an RAII scope guard.
#include <iostream>
#include <vector>

enum class Op { Lit, Add, Mul };
struct Node { Op op; long a, b; };
using Pool = std::vector<Node>;

thread_local Pool *pool;

struct Using {
  Pool *saved = pool;
  explicit Using(Pool &p) { pool = &p; }
  ~Using() { pool = saved; }
};

long push(Op op, long a, long b) {
  pool->push_back({op, a, b});
  return pool->size() - 1;
}

long lit(long n) { return push(Op::Lit, n, 0); }
long add(long l, long r) { return push(Op::Add, l, r); }
long mul(long l, long r) { return push(Op::Mul, l, r); }

long eval(long e) {
  auto [op, a, b] = (*pool)[e];
  switch (op) {
  case Op::Lit: return a;
  case Op::Add: return eval(a) + eval(b);
  default: return eval(a) * eval(b);
  }
}

int main() {
  Pool a;
  Using in_a(a);
  long e = mul(add(lit(1), lit(2)), add(lit(3), lit(4)));
  std::cout << eval(e) << "\n";
  {
    Pool b;
    Using in_b(b);
    std::cout << eval(add(lit(4), lit(4))) << "\n";
  }
  std::cout << eval(e) << "\n";
}
