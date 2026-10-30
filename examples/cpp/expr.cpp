// A thread_local pool pointer, swapped by an RAII scope guard.
#include <cstdint>
#include <iostream>
#include <variant>
#include <vector>

enum class BinOp { Add, Sub, Mul, Div };
using ExprRef = std::uint32_t;
struct Binary { BinOp op; ExprRef lhs, rhs; };
struct Literal { std::int64_t num; };
using Expr = std::variant<Binary, Literal>;

struct ExprPool {
  std::vector<Expr> exprs;
  ExprRef add(Expr expr) {
    exprs.push_back(expr);
    return exprs.size() - 1;
  }
  Expr get(ExprRef expr) const { return exprs[expr]; }
};

thread_local ExprPool *pool;

struct Using {
  ExprPool *saved = pool;
  explicit Using(ExprPool &p) { pool = &p; }
  ~Using() { pool = saved; }
};

std::int64_t interp(ExprRef expr) {
  Expr e = pool->get(expr);
  if (auto *literal = std::get_if<Literal>(&e)) return literal->num;
  auto [op, l, r] = std::get<Binary>(e);
  // Wrapping arithmetic, through unsigned integers.
  std::uint64_t lhs = interp(l), rhs = interp(r);
  switch (op) {
  case BinOp::Add: return lhs + rhs;
  case BinOp::Sub: return lhs - rhs;
  case BinOp::Mul: return lhs * rhs;
  default: return rhs ? std::int64_t(lhs) / std::int64_t(rhs) : 0;
  }
}

ExprRef lit(std::int64_t n) { return pool->add(Literal{n}); }
ExprRef bin(BinOp op, ExprRef lhs, ExprRef rhs) { return pool->add(Binary{op, lhs, rhs}); }

int main() {
  using enum BinOp;
  ExprPool a;
  Using in_a(a);
  ExprRef e = bin(Div, bin(Mul, bin(Sub, lit(7), lit(10)), lit(7)), lit(2));
  std::cout << interp(e) << "\n";
  {
    ExprPool b;
    Using in_b(b);
    std::cout << interp(bin(Div, bin(Add, lit(4), lit(4)), bin(Sub, lit(4), lit(4)))) << "\n";
  }
  std::cout << interp(e) << "\n";
}
