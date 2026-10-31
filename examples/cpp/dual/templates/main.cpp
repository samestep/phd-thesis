// Function templates over the float type, and a class template `Dual<T>`
// whose operators are templates too, so duals nest, and every function in
// the program is a template over `T`, which each call deduces from its
// argument. A literal like `2.0` is always a double, so `f` converts it with
// `T(2.0)`, which for a dual is the constant constructor. `Dual<Dual<T>>`
// and `Dual<T>` are different types, so `nested` has to lift the outer
// variable into the inner differentiation (`still(x)`): adding it as it is
// (`x + variable(y0)`) is a compile-time error, since `operator+` can't
// deduce one `T` from both. Each instance is compiled separately, as fast as
// hand-written code.
#include <cmath>
#include <iostream>

template <class T> T f(T x) { return x * x * x - T(2.0) * x - T(5.0); }

template <class T> struct Dual {
  T v, d;
  Dual(T v, T d) : v(v), d(d) {}
  // A constant.
  explicit Dual(double n) : v(n), d(0.0) {}
};

template <class T> Dual<T> variable(T x) { return {x, T(1.0)}; }
template <class T> Dual<T> still(T x) { return {x, T(0.0)}; }

template <class T> Dual<T> operator+(Dual<T> a, Dual<T> b) {
  return {a.v + b.v, a.d + b.d};
}

template <class T> Dual<T> operator-(Dual<T> a, Dual<T> b) {
  return {a.v - b.v, a.d - b.d};
}

template <class T> Dual<T> operator*(Dual<T> a, Dual<T> b) {
  return {a.v * b.v, a.d * b.v + a.v * b.d};
}

template <class T> Dual<T> operator/(Dual<T> a, Dual<T> b) {
  return {a.v / b.v, (a.d * b.v - a.v * b.d) / (b.v * b.v)};
}

template <class T> void show(T x) {
  // `nearbyint` rounds ties to even (the default rounding mode).
  std::cout << static_cast<long long>(std::nearbyint(x * T(1000000.0)))
            << '\n';
}

template <class T> void derivatives(T x) {
  show(f(x));
  show(f(variable(x)).d);
  show(f(variable(variable(x))).d.d);
}

template <class T> void newton(T x0, int steps) {
  T x = x0;
  for (int i = 0; i < steps; ++i) {
    auto y = f(variable(x));
    x = x - y.v / y.d;
    show(x);
  }
}

// d/dx (x * d/dy (x + y)) at x = 1, y = 1.
template <class T> T nested(T at) {
  auto x = variable(at);
  auto y0 = Dual<T>(1.0);
  auto inner = (still(x) + variable(y0)).d;
  return (x * inner).d;
}

int main() {
  derivatives(2.0);
  newton(2.0, 4);
  show(nested(1.0));
}
