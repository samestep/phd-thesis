# Duck typing: the dynamic variable holds anything that does the `Ast` role,
# which only stubs `add` and `get`, and its references can be anything at all.
enum BinOp (Add => 1, Sub => 2, Mul => 3, Div => 4); # 0 is a literal

class Binary {
    has BinOp $.op;
    has $.lhs;
    has $.rhs;
}

class Literal {
    has Int $.num;
}

role Ast {
    method add($expr) {...}
    method get($expr) {...}
}

sub interp($expr --> Int) {
    given $*ast.get($expr) {
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

sub lit(Int $num) { $*ast.add(Literal.new(:$num)) }
sub bin(BinOp $op, $lhs, $rhs) { $*ast.add(Binary.new(:$op, :$lhs, :$rhs)) }

# Representation 1: a node is an index into parallel lists.
class Idx {
    has Int $.i;
    method new(Int $i) { self.bless(:$i) }
}

class Columns does Ast {
    has (@!ops, @!lhs, @!rhs);

    method add($_ --> Idx) {
        my ($op, $l, $r) = $_ ~~ Literal ?? (0, .num, 0) !! (.op.value, .lhs.i, .rhs.i);
        @!ops.push($op);
        @!lhs.push($l);
        @!rhs.push($r);
        Idx.new(@!ops.end)
    }

    method get(Idx $ (:$i)) {
        return Literal.new(num => @!lhs[$i]) if @!ops[$i] == 0;
        Binary.new(op => BinOp(@!ops[$i]), lhs => Idx.new(@!lhs[$i]),
                   rhs => Idx.new(@!rhs[$i]))
    }
}

# Representation 2: a node is an index into one list of triples.
class Slot {
    has Int $.i;
    method new(Int $i) { self.bless(:$i) }
}

class Triples does Ast {
    has @!triples;

    method add($_ --> Slot) {
        @!triples.append: $_ ~~ Literal ?? (0, .num, 0) !! (.op.value, .lhs.i, .rhs.i);
        Slot.new(@!triples.elems div 3 - 1)
    }

    method get(Slot $ (:$i)) {
        my ($op, $l, $r) = @!triples[3 * $i ..^ 3 * $i + 3];
        return Literal.new(num => $l) if $op == 0;
        Binary.new(op => BinOp($op), lhs => Slot.new($l), rhs => Slot.new($r))
    }
}

my Ast $*ast = Columns.new;
my $e = bin(Div, bin(Mul, bin(Sub, lit(7), lit(10)), lit(7)), lit(2));
say interp($e);
{
    my Ast $*ast = Triples.new;
    say interp(bin(Div, bin(Add, lit(4), lit(4)), bin(Sub, lit(4), lit(4))));
}
say interp($e);
