// A function template over both types, named at every call, since neither
// can be deduced from the arguments. Arithmetic and conversions between float
// types are built in, so the kernel needs no traits, but a literal like `0.1`
// is always a double and has to be converted to `C`. Each instance is
// compiled separately, as fast as hand-written code.
#include <cmath>
#include <iostream>
#include <vector>

template <class C, class S> void report(int n) {
  std::vector<S> list;
  for (int i = 0; i < n; ++i)
    list.push_back(static_cast<S>(static_cast<C>(0.1)));
  C sum = 0.0;
  for (S x : list)
    sum = sum + static_cast<C>(x);
  // `nearbyint` rounds ties to even (the default rounding mode).
  std::cout << static_cast<long long>(std::nearbyint(sum * static_cast<C>(1000.0)))
            << '\n';
}

int main() {
  // Compute in f64, store in f64.
  report<double, double>(1000000);
  // Compute in f64, store in f32: half the memory.
  report<double, float>(1000000);
  // Compute in f32, store in f32.
  report<float, float>(1000000);
}
