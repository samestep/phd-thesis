// Function templates over both types. Every signature in the chain names both
// as template parameters; `S` is deduced wherever a vector is passed, but `C`
// never appears in an argument type, so every call names it explicitly, and
// `fill` and `report` need both. Arithmetic and conversions between float
// types are built in, so no traits are needed, but a literal like `0.1` is
// always a double and has to be converted to `C`. Each instance is compiled
// separately, as fast as hand-written code.
#include <cmath>
#include <iostream>
#include <vector>

template <class C, class S> std::vector<S> fill(int n) {
  std::vector<S> xs;
  for (int i = 0; i < n; ++i)
    xs.push_back(static_cast<S>(static_cast<C>(0.1)));
  return xs;
}

template <class C, class S>
C accumulate(const std::vector<S> &xs, int from, int to) {
  C sum = 0.0;
  for (int i = from; i < to; ++i)
    sum = sum + static_cast<C>(xs[i]);
  return sum;
}

template <class C, class S> C total(const std::vector<S> &xs, int n) {
  return accumulate<C>(xs, 0, n);
}

template <class C, class S> long long scaled(const std::vector<S> &xs, int n) {
  // `nearbyint` rounds ties to even (the default rounding mode).
  return static_cast<long long>(
      std::nearbyint(total<C>(xs, n) * static_cast<C>(1000.0)));
}

template <class C, class S> void report(int n) {
  std::cout << scaled<C>(fill<C, S>(n), n) << '\n';
}

int main() {
  // Compute in f64, store in f64.
  report<double, double>(1000000);
  // Compute in f64, store in f32: half the memory.
  report<double, float>(1000000);
  // Compute in f32, store in f32.
  report<float, float>(1000000);
}
