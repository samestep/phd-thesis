{ ... }:
{
  # `-lm` for `fma` and `llround`; no fused multiply-adds the source
  # doesn't ask for (GCC contracts `sumX2 += newval * newval` into one
  # where the hardware has them, as the C++ example notes).
  run = "cc -O2 -ffp-contract=off -o main main.c -lm && ./main";
}
