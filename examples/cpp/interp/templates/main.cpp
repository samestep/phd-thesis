// Function templates over three parameters, each constrained by a concept: the
// pool is passed by reference and its index type is a member type, while the
// arithmetic and the tracer are only types. A template parameter can't be
// deduced from `P::Ref` or from a return type, so every call to `interp`
// names all three; a `Traced` node calls `interp<P, V, Loud>`, a second
// instance in which tracing prints. C++ has no saturating arithmetic before
// C++26, so that one goes through `double`, clamped before converting back,
// since an out-of-range conversion is undefined. Each instance is compiled
// separately, as fast as hand-written code.
#include <algorithm>
#include <cmath>
#include <concepts>
#include <cstdint>
#include <iostream>
#include <limits>
#include <variant>
#include <vector>

enum class BinOp { Add = 1, Sub, Mul, Div }; // 0 means a literal, 5 traced.
template <class R> struct Binary { BinOp op; R lhs, rhs; };
struct Literal { std::int32_t num; };
// Evaluate the inner expression with tracing on.
template <class R> struct Traced { R inner; };
template <class R> using Expr = std::variant<Binary<R>, Literal, Traced<R>>;

// The pool: an index type, how to read a node through one, and how to make
// one.
template <class P>
concept Pool = requires(P pool, const P cpool, typename P::Ref ref, Expr<typename P::Ref> expr) {
  { cpool.node(ref) } -> std::same_as<Expr<typename P::Ref>>;
  { pool.add(expr) } -> std::same_as<typename P::Ref>;
};

// Three meanings for the interpreted language's arithmetic, ahead of the
// concept: a call to `print_value` on a `double` in a template has no
// argument-dependent lookup, so it only finds overloads declared before it.
void print_line(std::int32_t n) { std::cout << n << '\n'; }

struct Wrapping {
  std::int32_t n;
  explicit Wrapping(std::int32_t n) : n(n) {}
};
// Through unsigned integers, which wrap.
std::uint32_t bits(Wrapping v) { return v.n; }
Wrapping operator+(Wrapping l, Wrapping r) { return Wrapping(bits(l) + bits(r)); }
Wrapping operator-(Wrapping l, Wrapping r) { return Wrapping(bits(l) - bits(r)); }
Wrapping operator*(Wrapping l, Wrapping r) { return Wrapping(bits(l) * bits(r)); }
Wrapping operator/(Wrapping l, Wrapping r) { return Wrapping(l.n / r.n); }
void print_value(Wrapping v) { print_line(v.n); }

struct Saturating {
  std::int32_t n;
  explicit Saturating(std::int32_t n) : n(n) {}
};
// A double holds every int32 sum, difference and quotient exactly enough, and
// every product below 2^53, so convert, compute, truncate and clamp.
Saturating saturate(double x) {
  using limits = std::numeric_limits<std::int32_t>;
  double lo = limits::min(), hi = limits::max();
  return Saturating(std::int32_t(std::clamp(std::trunc(x), lo, hi)));
}
Saturating operator+(Saturating l, Saturating r) { return saturate(double(l.n) + double(r.n)); }
Saturating operator-(Saturating l, Saturating r) { return saturate(double(l.n) - double(r.n)); }
Saturating operator*(Saturating l, Saturating r) { return saturate(double(l.n) * double(r.n)); }
Saturating operator/(Saturating l, Saturating r) { return saturate(double(l.n) / double(r.n)); }
void print_value(Saturating v) { print_line(v.n); }

// `nearbyint` rounds ties to even (the default rounding mode).
void print_value(double v) { print_line(std::int32_t(std::nearbyint(v))); }

// The arithmetic of the interpreted language: what a value is, what a literal
// means (a constructor), and how to print one.
template <class V>
concept Arith = std::copyable<V> && requires(V v, std::int32_t n) {
  V(n);
  { v + v } -> std::same_as<V>;
  { v - v } -> std::same_as<V>;
  { v * v } -> std::same_as<V>;
  { v / v } -> std::same_as<V>;
  print_value(v);
};

// Called with every intermediate value.
template <class T, class V>
concept Trace = requires(V v) { T::trace(v); };

struct Quiet {
  template <Arith V> static void trace(V) {}
};

struct Loud {
  template <Arith V> static void trace(V v) {
    std::cout << "  ";
    print_value(v);
  }
};

// Written once, against the concepts alone.
template <Pool P, Arith V, Trace<V> T> V interp(const P &pool, typename P::Ref e) {
  V v = std::visit(
      [&](auto expr) -> V {
        using E = decltype(expr);
        if constexpr (std::same_as<E, Literal>) {
          return V(expr.num);
        } else if constexpr (std::same_as<E, Traced<typename P::Ref>>) {
          return interp<P, V, Loud>(pool, expr.inner);
        } else {
          V l = interp<P, V, T>(pool, expr.lhs), r = interp<P, V, T>(pool, expr.rhs);
          switch (expr.op) {
          case BinOp::Add: return l + r;
          case BinOp::Sub: return l - r;
          case BinOp::Mul: return l * r;
          default: return l / r;
          }
        }
      },
      pool.node(e));
  T::trace(v);
  return v;
}

template <Pool P, Arith V, Trace<V> T> void report(const P &pool, typename P::Ref e) {
  print_value(interp<P, V, T>(pool, e));
}

template <Pool P> typename P::Ref lit(P &pool, std::int32_t n) { return pool.add(Literal{n}); }
template <Pool P> typename P::Ref bin(P &pool, BinOp op, typename P::Ref lhs, typename P::Ref rhs) {
  return pool.add(Binary<typename P::Ref>{op, lhs, rhs});
}
template <Pool P> typename P::Ref traced(P &pool, typename P::Ref inner) {
  return pool.add(Traced<typename P::Ref>{inner});
}

// A pool: a node is an index into one list of triples.
enum class Slot : std::uint32_t {};

struct Triples {
  using Ref = Slot;
  std::vector<std::int32_t> triples;
  Expr<Slot> node(Slot expr) const {
    auto i = 3 * std::size_t(expr);
    std::int32_t code = triples[i], a = triples[i + 1], b = triples[i + 2];
    if (code == 0) return Literal{a};
    if (code == 5) return Traced<Slot>{Slot(a)};
    return Binary<Slot>{BinOp(code), Slot(a), Slot(b)};
  }
  Slot add(Expr<Slot> expr) {
    auto i = Slot(triples.size() / 3);
    if (auto *literal = std::get_if<Literal>(&expr)) {
      triples.insert(triples.end(), {0, literal->num, 0});
    } else if (auto *t = std::get_if<Traced<Slot>>(&expr)) {
      triples.insert(triples.end(), {5, std::int32_t(t->inner), 0});
    } else {
      auto [op, l, r] = std::get<Binary<Slot>>(expr);
      triples.insert(triples.end(), {std::int32_t(op), std::int32_t(l), std::int32_t(r)});
    }
    return i;
  }
};

int main() {
  using enum BinOp;
  Triples pool;
  // 50000 * 50000 / 100000 + traced((7 - 10) * 7 / 8)
  Slot big = bin(pool, Div, bin(pool, Mul, lit(pool, 50000), lit(pool, 50000)), lit(pool, 100000));
  Slot diff = bin(pool, Sub, lit(pool, 7), lit(pool, 10));
  Slot small = bin(pool, Div, bin(pool, Mul, diff, lit(pool, 7)), lit(pool, 8));
  Slot e = bin(pool, Add, big, traced(pool, small));
  report<Triples, Wrapping, Quiet>(pool, e);
  report<Triples, Saturating, Quiet>(pool, e);
  report<Triples, double, Quiet>(pool, e);
}
