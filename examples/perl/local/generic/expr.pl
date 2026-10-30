# Duck typing: a package variable, dynamically rebound with `local`, holds
# any object with `add` and `get` methods, and its references can be
# anything at all.
use strict;
use warnings;

our $ast;

sub interp {
  my $expr = $ast->get(shift);
  return $expr->{num} if $expr->{tag} eq 'literal';
  my ($l, $r) = (interp($expr->{lhs}), interp($expr->{rhs}));
  my $op = $expr->{op};
  return $l + $r if $op eq 'add';
  return $l - $r if $op eq 'sub';
  return $l * $r if $op eq 'mul';
  return $r == 0 ? 0 : do { use integer; $l / $r };
}

sub lit { $ast->add({ tag => 'literal', num => $_[0] }) }
sub bin { $ast->add({ tag => 'binary', op => $_[0], lhs => $_[1], rhs => $_[2] }) }

my @ops = (undef, qw(add sub mul div));    # 0 is a literal
my %code = map { $ops[$_] => $_ } 1 .. $#ops;

# Representation 1: a node is an index into parallel lists.
package Idx { sub new { my ($class, $i) = @_; bless \$i, $class } }

package Columns {
  sub new { bless { ops => [], lhs => [], rhs => [] }, shift }

  sub add {
    my ($self, $expr) = @_;
    my @row = $expr->{tag} eq 'literal'
      ? (0, $expr->{num}, 0)
      : ($code{ $expr->{op} }, ${ $expr->{lhs} }, ${ $expr->{rhs} });
    push @{ $self->{$_} }, shift @row for qw(ops lhs rhs);
    Idx->new($#{ $self->{ops} });
  }

  sub get {
    my ($self, $ref) = @_;
    my ($op, $l, $r) = map { $self->{$_}[$$ref] } qw(ops lhs rhs);
    return { tag => 'literal', num => $l } if $op == 0;
    { tag => 'binary', op => $ops[$op], lhs => Idx->new($l), rhs => Idx->new($r) };
  }
}

# Representation 2: a node is an index into one list of triples.
package Slot { sub new { my ($class, $i) = @_; bless \$i, $class } }

package Triples {
  sub new { bless [], shift }

  sub add {
    my ($self, $expr) = @_;
    push @$self, $expr->{tag} eq 'literal'
      ? (0, $expr->{num}, 0)
      : ($code{ $expr->{op} }, ${ $expr->{lhs} }, ${ $expr->{rhs} });
    Slot->new(@$self / 3 - 1);
  }

  sub get {
    my ($self, $ref) = @_;
    my ($op, $l, $r) = @$self[ 3 * $$ref .. 3 * $$ref + 2 ];
    return { tag => 'literal', num => $l } if $op == 0;
    { tag => 'binary', op => $ops[$op], lhs => Slot->new($l), rhs => Slot->new($r) };
  }
}

$ast = Columns->new;
my $e = bin('div', bin('mul', bin('sub', lit(7), lit(10)), lit(7)), lit(2));
print interp($e), "\n";
{
  local $ast = Triples->new;
  print interp(bin('div', bin('add', lit(4), lit(4)), bin('sub', lit(4), lit(4)))), "\n";
}
print interp($e), "\n";
