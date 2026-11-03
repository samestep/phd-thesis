// Function templates over the number type, instantiated at `double` and at
// Boost.Multiprecision's `cpp_double_double`, each compiled separately, as
// fast as hand-written code. To make the routine rerunnable it had to be
// written for this from the start: every function a template; `T` named at
// every call that has no argument of that type (`readings<T>()`,
// `report<T>()`); every literal built in `T`, since `10000000.2` is a
// double and `T(10000000.2)` rounds it to one first (the third line would
// then print 100000001), so `T(100000002) / 10`; and every buffer and
// accumulator declared at `T`, since a helper's `std::vector<double>` or
// `double sum = 0` compiles just as well at `cpp_double_double` and
// silently computes in double. A `T` passed in is lifted by the vector's
// converting constructor; nothing chooses `T` but the call that names it.
#include <boost/multiprecision/cpp_double_fp.hpp>
#include <cmath>
#include <iostream>
#include <vector>

using boost::multiprecision::cpp_double_double;

// NIST StRD NumAcc4: 10000000.2, then 10000000.1 and 10000000.3 in turn.
template <class T> std::vector<T> readings() {
  std::vector<T> xs;
  xs.push_back(T(100000002) / 10);
  for (int i = 1; i < 1001; ++i)
    xs.push_back(i % 2 == 1 ? T(100000001) / 10 : T(100000003) / 10);
  return xs;
}

// The schoolbook one-pass formula, as PostgreSQL's `stddev` computed it
// until version 12, clamp included.
template <class T> T sd(const std::vector<T> &xs) {
  T n = 0, sum = 0, sum_sq = 0;
  for (const T &x : xs) {
    n += 1;
    sum += x;
    sum_sq += x * x;
  }
  T numerator = n * sum_sq - sum * sum;
  if (numerator <= 0)
    return 0;
  using std::sqrt;
  return sqrt(numerator / (n * (n - 1)));
}

template <class T> void show(T sd) {
  using std::round;
  std::cout << static_cast<long long>(round(sd * 1000000000)) << '\n';
}

template <class T> void report() { show(sd(readings<T>())); }

int main() {
  report<double>();
  std::vector<double> xs = readings<double>();
  show(sd(std::vector<cpp_double_double>(xs.begin(), xs.end())));
  report<cpp_double_double>();
}
