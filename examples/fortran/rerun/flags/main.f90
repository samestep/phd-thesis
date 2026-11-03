! A compiler flag, per compilation unit: `stats.F90` is compiled twice,
! once as written and once with `-freal-8-real-16`, which makes every
! double precision variable, array and `d0` literal in it binary128, the
! allocatable `xs` and the accumulators included, with not a line of it
! changed. Both copies have to link into one program, so the preprocessor
! renames the second module (`-DSTATS=stats_wide`); that, the build, and
! the `real(xs, 16)` that lifts the f64 readings into the wide copy are all
! it takes. The limits: the choice is made per file, at build time, so
! every module the wide copy uses has to be compiled twice as well (one
! compiled only once is a type mismatch, REAL(16) passed to REAL(8), and
! through an implicit interface not even that, just garbage); and only the
! compiler's own kinds are on offer, binary128 here (113 bits, in
! software), never a double-double or an interval type from a library.
program main
  use stats, only: report, readings
  use stats_wide, only: wide_sd => sd, wide_show => show, wide_report => report
  implicit none
  double precision, allocatable :: xs(:)
  call report()
  call readings(xs)
  call wide_show(wide_sd(real(xs, 16)))
  call wide_report()
end program
