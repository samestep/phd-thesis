{ pkgs, ... }:
{
  packages = [ pkgs.gfortran ];
  # The one Fortran example builds its own way: see its `main.f90`. No
  # fused multiply-adds the source doesn't ask for, as in the C++ `rerun`.
  run = ''
    flags="-O2 -ffp-contract=off -cpp"
    gfortran $flags -DSTATS=stats -c stats.F90 -o stats.o
    gfortran $flags -DSTATS=stats_wide -freal-8-real-16 -c stats.F90 -o stats_wide.o
    gfortran $flags "$main" stats.o stats_wide.o -o main
    ./main
  '';
}
