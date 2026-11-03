{ pkgs, ... }:
{
  # Boost.Multiprecision's `cpp_double_double`, header-only.
  packages = [ pkgs.boost ];
  # No fused multiply-adds the source doesn't ask for: where the hardware
  # has them, GCC contracts `sum_sq + x * x` into one by default, and the
  # f64 numerator comes out -1992816 rather than IEEE's -2015232 (on
  # aarch64-linux; negative either way, so the output is the same).
  run = "c++ -std=c++20 -O2 -ffp-contract=off -o main main.cpp && ./main";
}
