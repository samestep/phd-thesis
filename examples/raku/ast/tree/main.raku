# The tree Sampson starts from: each node is an object holding references to
# its children, so nothing needs a pool, but every node is its own allocation.
enum BinOp <Add Sub Mul Div>;

class Expr {}

class Binary is Expr {
    has BinOp $.op;
    has Expr $.lhs;
    has Expr $.rhs;
}

class Literal is Expr {
    has Int $.num;
}

sub interp(Expr $expr --> Int) {
    given $expr {
        when Literal { .num }
        when Binary {
            my ($l, $r) = interp(.lhs), interp(.rhs);
            given .op {
                when Add { $l + $r }
                when Sub { $l - $r }
                when Mul { $l * $r }
                when Div { $r == 0 ?? 0 !! FatRat.new($l, $r).truncate }
            }
        }
    }
}

sub lit(Int $num --> Expr) { Literal.new(:$num) }
sub bin(BinOp $op, Expr $lhs, Expr $rhs --> Expr) { Binary.new(:$op, :$lhs, :$rhs) }

my $e = bin(Div, bin(Mul, bin(Sub, lit(7), lit(10)), lit(7)), lit(2));
say interp($e);
{
    my $f = bin(Div, bin(Add, lit(4), lit(4)), bin(Sub, lit(4), lit(4)));
    say interp($f);
}
say interp($e);
