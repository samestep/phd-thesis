# A package variable, dynamically rebound with `local`.
use strict;
use warnings;

our @pool;

sub node { push @pool, [@_]; $#pool }
sub lit { node('lit', @_) }
sub add { node('add', @_) }
sub mul { node('mul', @_) }

sub ev {
  my ($op, $a, $b) = @{ $pool[shift] };
  return $a if $op eq 'lit';
  return ev($a) + ev($b) if $op eq 'add';
  return ev($a) * ev($b);
}

my $e = mul(add(lit(1), lit(2)), add(lit(3), lit(4)));
print ev($e), "\n";
{
  local @pool;
  print ev(add(lit(4), lit(4))), "\n";
}
print ev($e), "\n";
