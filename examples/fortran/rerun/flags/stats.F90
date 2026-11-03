! Ordinary double-precision Fortran, with nothing in it about the second
! precision: `main.f90` says how it is compiled twice.
module STATS
  implicit none
contains
  ! NIST StRD NumAcc4: 10000000.2, then 10000000.1 and 10000000.3 in turn.
  subroutine readings(xs)
    double precision, allocatable, intent(out) :: xs(:)
    integer :: i
    allocate(xs(1001))
    xs(1) = 10000000.2d0
    do i = 2, 1001
      if (mod(i, 2) == 0) then
        xs(i) = 10000000.1d0
      else
        xs(i) = 10000000.3d0
      end if
    end do
  end subroutine

  ! The schoolbook one-pass formula, as PostgreSQL's `stddev` computed it
  ! until version 12, clamp included.
  double precision function sd(xs)
    double precision, intent(in) :: xs(:)
    double precision :: n, total, total_sq, numerator
    integer :: i
    n = 0.0d0
    total = 0.0d0
    total_sq = 0.0d0
    do i = 1, size(xs)
      n = n + 1.0d0
      total = total + xs(i)
      total_sq = total_sq + xs(i) * xs(i)
    end do
    numerator = n * total_sq - total * total
    if (numerator <= 0.0d0) then
      sd = 0.0d0
    else
      sd = sqrt(numerator / (n * (n - 1.0d0)))
    end if
  end function

  subroutine show(sd)
    double precision, intent(in) :: sd
    print '(I0)', nint(sd * 1.0d9, kind=8)
  end subroutine

  subroutine report()
    double precision, allocatable :: xs(:)
    call readings(xs)
    call show(sd(xs))
  end subroutine
end module
