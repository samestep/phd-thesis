// The tree Sampson starts from: each node owns its children through a
// `std::unique_ptr`, so nothing needs a pool, but every node is its own `new`.
#include <cstdint>
#include <iostream>
#include <memory>
#include <variant>

enum class BinOp { Add, Sub, Mul, Div };
struct Binary;
struct Literal { std::int64_t num; };
using Expr = std::variant<Binary, Literal>;
struct Binary { BinOp op; std::unique_ptr<Expr> lhs, rhs; };

std::int64_t interp(const Expr &e) {
  if (auto *literal = std::get_if<Literal>(&e)) return literal->num;
  auto &[op, l, r] = std::get<Binary>(e);
  // Wrapping arithmetic, through unsigned integers.
  std::uint64_t lhs = interp(*l), rhs = interp(*r);
  switch (op) {
  case BinOp::Add: return lhs + rhs;
  case BinOp::Sub: return lhs - rhs;
  case BinOp::Mul: return lhs * rhs;
  default: return rhs ? std::int64_t(lhs) / std::int64_t(rhs) : 0;
  }
}

std::unique_ptr<Expr> lit(std::int64_t n) { return std::make_unique<Expr>(Literal{n}); }
std::unique_ptr<Expr> bin(BinOp op, std::unique_ptr<Expr> lhs, std::unique_ptr<Expr> rhs) {
  return std::make_unique<Expr>(Binary{op, std::move(lhs), std::move(rhs)});
}

int main() {
  using enum BinOp;
  auto e = bin(Div, bin(Mul, bin(Sub, lit(7), lit(10)), lit(7)), lit(2));
  std::cout << interp(*e) << "\n";
  {
    auto f = bin(Div, bin(Add, lit(4), lit(4)), bin(Sub, lit(4), lit(4)));
    std::cout << interp(*f) << "\n";
  }
  std::cout << interp(*e) << "\n";
}
