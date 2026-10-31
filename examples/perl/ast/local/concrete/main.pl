# A package variable, dynamically rebound with `local`.
use strict;
use warnings;

our @pool;

sub add { push @pool, $_[0]; $#pool }
sub get { $pool[ $_[0] ] }

sub interp {
  my $expr = get(shift);
  return $expr->{num} if $expr->{tag} eq 'literal';
  my ($l, $r) = (interp($expr->{lhs}), interp($expr->{rhs}));
  my $op = $expr->{op};
  return $l + $r if $op eq 'add';
  return $l - $r if $op eq 'sub';
  return $l * $r if $op eq 'mul';
  return $r == 0 ? 0 : do { use integer; $l / $r };
}

sub lit { add({ tag => 'literal', num => $_[0] }) }
sub bin { add({ tag => 'binary', op => $_[0], lhs => $_[1], rhs => $_[2] }) }

my $e = bin('div', bin('mul', bin('sub', lit(7), lit(10)), lit(7)), lit(2));
print interp($e), "\n";
{
  local @pool;
  print interp(bin('div', bin('add', lit(4), lit(4)), bin('sub', lit(4), lit(4)))), "\n";
}
print interp($e), "\n";
