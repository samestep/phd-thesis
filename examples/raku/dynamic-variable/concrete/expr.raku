# A dynamic variable, looked up through the call stack and redeclared with
# `my $*pool` in an inner scope.
enum BinOp <Add Sub Mul Div>;

subset ExprRef of Int;

class Binary {
    has BinOp $.op;
    has ExprRef $.lhs;
    has ExprRef $.rhs;
}

class Literal {
    has Int $.num;
}

class ExprPool {
    has @!exprs;
    method add($expr --> ExprRef) { @!exprs.push($expr); @!exprs.end }
    method get(ExprRef $expr) { @!exprs[$expr] }
}

sub interp(ExprRef $expr --> Int) {
    given $*pool.get($expr) {
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

sub lit(Int $num --> ExprRef) { $*pool.add(Literal.new(:$num)) }
sub bin(BinOp $op, ExprRef $lhs, ExprRef $rhs --> ExprRef) {
    $*pool.add(Binary.new(:$op, :$lhs, :$rhs))
}

my $*pool = ExprPool.new;
my $e = bin(Div, bin(Mul, bin(Sub, lit(7), lit(10)), lit(7)), lit(2));
say interp($e);
{
    my $*pool = ExprPool.new;
    say interp(bin(Div, bin(Add, lit(4), lit(4)), bin(Sub, lit(4), lit(4))));
}
say interp($e);
