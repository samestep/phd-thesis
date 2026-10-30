// Virtual functions: a virtual can't be a template, so `ExprRef` is fixed once
// for every representation, and the thread_local pool points to the base class.
#include <cstdint>
#include <iostream>
#include <variant>
#include <vector>

enum class BinOp { Add = 1, Sub, Mul, Div }; // 0 means a literal.
using ExprRef = std::uint32_t;
struct Binary { BinOp op; ExprRef lhs, rhs; };
struct Literal { std::int64_t num; };
using Expr = std::variant<Binary, Literal>;

struct Ast {
  virtual ~Ast() = default;
  virtual ExprRef add(Expr expr) = 0;
  virtual Expr get(ExprRef expr) const = 0;
};

thread_local Ast *pool;

struct Using {
  Ast *saved = pool;
  explicit Using(Ast &p) { pool = &p; }
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

Expr node(std::int64_t op, std::int64_t lhs, std::int64_t rhs) {
  if (op == 0) return Literal{lhs};
  return Binary{BinOp(op), ExprRef(lhs), ExprRef(rhs)};
}

// Representation 1: a node is an index into parallel lists.
struct Columns : Ast {
  std::vector<std::int64_t> ops, lhs, rhs;
  ExprRef add(Expr expr) override {
    if (auto *literal = std::get_if<Literal>(&expr)) {
      ops.push_back(0), lhs.push_back(literal->num), rhs.push_back(0);
    } else {
      auto [op, l, r] = std::get<Binary>(expr);
      ops.push_back(std::int64_t(op)), lhs.push_back(l), rhs.push_back(r);
    }
    return ops.size() - 1;
  }
  Expr get(ExprRef i) const override { return node(ops[i], lhs[i], rhs[i]); }
};

// Representation 2: a node is an index into one list of triples.
struct Triples : Ast {
  std::vector<std::int64_t> triples;
  ExprRef add(Expr expr) override {
    if (auto *literal = std::get_if<Literal>(&expr)) {
      triples.insert(triples.end(), {0, literal->num, 0});
    } else {
      auto [op, l, r] = std::get<Binary>(expr);
      triples.insert(triples.end(), {std::int64_t(op), l, r});
    }
    return triples.size() / 3 - 1;
  }
  Expr get(ExprRef expr) const override {
    auto i = 3 * std::size_t(expr);
    return node(triples[i], triples[i + 1], triples[i + 2]);
  }
};

int main() {
  using enum BinOp;
  Columns a;
  Using in_a(a);
  ExprRef e = bin(Div, bin(Mul, bin(Sub, lit(7), lit(10)), lit(7)), lit(2));
  std::cout << interp(e) << "\n";
  {
    Triples b;
    Using in_b(b);
    std::cout << interp(bin(Div, bin(Add, lit(4), lit(4)), bin(Sub, lit(4), lit(4)))) << "\n";
  }
  std::cout << interp(e) << "\n";
}
