# The tree Sampson starts from: each node is a hash holding references to its
# children, so nothing needs a pool, but every node is its own allocation.
use strict;
use warnings;

sub interp {
  my $expr = shift;
  return $expr->{num} if $expr->{tag} eq 'literal';
  my ($l, $r) = (interp($expr->{lhs}), interp($expr->{rhs}));
  my $op = $expr->{op};
  return $l + $r if $op eq 'add';
  return $l - $r if $op eq 'sub';
  return $l * $r if $op eq 'mul';
  return $r == 0 ? 0 : do { use integer; $l / $r };
}

sub lit { +{ tag => 'literal', num => $_[0] } }
sub bin { +{ tag => 'binary', op => $_[0], lhs => $_[1], rhs => $_[2] } }

my $e = bin('div', bin('mul', bin('sub', lit(7), lit(10)), lit(7)), lit(2));
print interp($e), "\n";
{
  my $f = bin('div', bin('add', lit(4), lit(4)), bin('sub', lit(4), lit(4)));
  print interp($f), "\n";
}
print interp($e), "\n";
