// Templates constrained by a concept: the index type is a member type, and
// there's one thread_local pool pointer per representation. A template
// parameter can't be deduced from `A::Ref`, so every call names the pool type.
#include <concepts>
#include <cstdint>
#include <iostream>
#include <variant>
#include <vector>

enum class BinOp { Add = 1, Sub, Mul, Div }; // 0 means a literal.
template <class R> struct Binary { BinOp op; R lhs, rhs; };
struct Literal { std::int64_t num; };
template <class R> using Expr = std::variant<Binary<R>, Literal>;

template <class A>
concept Ast = requires(A ast, const A cast, typename A::Ref ref, Expr<typename A::Ref> expr) {
  { ast.add(expr) } -> std::same_as<typename A::Ref>;
  { cast.get(ref) } -> std::same_as<Expr<typename A::Ref>>;
};

template <Ast A> thread_local A *pool;

template <Ast A> struct Using {
  A *saved = pool<A>;
  explicit Using(A &p) { pool<A> = &p; }
  ~Using() { pool<A> = saved; }
};

template <Ast A> std::int64_t interp(typename A::Ref expr) {
  Expr<typename A::Ref> e = pool<A>->get(expr);
  if (auto *literal = std::get_if<Literal>(&e)) return literal->num;
  auto [op, l, r] = std::get<Binary<typename A::Ref>>(e);
  // Wrapping arithmetic, through unsigned integers.
  std::uint64_t lhs = interp<A>(l), rhs = interp<A>(r);
  switch (op) {
  case BinOp::Add: return lhs + rhs;
  case BinOp::Sub: return lhs - rhs;
  case BinOp::Mul: return lhs * rhs;
  default: return rhs ? std::int64_t(lhs) / std::int64_t(rhs) : 0;
  }
}

template <Ast A> typename A::Ref lit(std::int64_t n) { return pool<A>->add(Literal{n}); }
template <Ast A> typename A::Ref bin(BinOp op, typename A::Ref lhs, typename A::Ref rhs) {
  return pool<A>->add(Binary<typename A::Ref>{op, lhs, rhs});
}

template <class R> Expr<R> node(std::int64_t op, std::int64_t lhs, std::int64_t rhs) {
  if (op == 0) return Literal{lhs};
  return Binary<R>{BinOp(op), R(lhs), R(rhs)};
}

// Representation 1: a node is an index into parallel lists.
enum class Idx : std::uint32_t {};

struct Columns {
  using Ref = Idx;
  std::vector<std::int64_t> ops, lhs, rhs;
  Idx add(Expr<Idx> expr) {
    if (auto *literal = std::get_if<Literal>(&expr)) {
      ops.push_back(0), lhs.push_back(literal->num), rhs.push_back(0);
    } else {
      auto [op, l, r] = std::get<Binary<Idx>>(expr);
      ops.push_back(std::int64_t(op)), lhs.push_back(std::int64_t(l)), rhs.push_back(std::int64_t(r));
    }
    return Idx(ops.size() - 1);
  }
  Expr<Idx> get(Idx expr) const {
    auto i = std::size_t(expr);
    return node<Idx>(ops[i], lhs[i], rhs[i]);
  }
};

// Representation 2: a node is an index into one list of triples.
enum class Slot : std::uint32_t {};

struct Triples {
  using Ref = Slot;
  std::vector<std::int64_t> triples;
  Slot add(Expr<Slot> expr) {
    if (auto *literal = std::get_if<Literal>(&expr)) {
      triples.insert(triples.end(), {0, literal->num, 0});
    } else {
      auto [op, l, r] = std::get<Binary<Slot>>(expr);
      triples.insert(triples.end(), {std::int64_t(op), std::int64_t(l), std::int64_t(r)});
    }
    return Slot(triples.size() / 3 - 1);
  }
  Expr<Slot> get(Slot expr) const {
    auto i = 3 * std::size_t(expr);
    return node<Slot>(triples[i], triples[i + 1], triples[i + 2]);
  }
};

int main() {
  using enum BinOp;
  using A = Columns;
  A a;
  Using in_a(a);
  Idx e = bin<A>(Div, bin<A>(Mul, bin<A>(Sub, lit<A>(7), lit<A>(10)), lit<A>(7)), lit<A>(2));
  std::cout << interp<A>(e) << "\n";
  {
    using B = Triples;
    B b;
    Using in_b(b);
    Slot f = bin<B>(Div, bin<B>(Add, lit<B>(4), lit<B>(4)), bin<B>(Sub, lit<B>(4), lit<B>(4)));
    std::cout << interp<B>(f) << "\n";
  }
  std::cout << interp<A>(e) << "\n";
}
