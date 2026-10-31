# The tree Sampson starts from: each node is a dict whose children are nested
# dicts, so nothing needs a pool; Tcl values are immutable and shared.
proc interp {e} {
  if {[dict get $e tag] eq "literal"} { return [dict get $e num] }
  set l [interp [dict get $e lhs]]
  set r [interp [dict get $e rhs]]
  switch [dict get $e op] {
    add { expr {$l + $r} }
    sub { expr {$l - $r} }
    mul { expr {$l * $r} }
    div { expr {$r == 0 ? 0 : ($l < 0) == ($r < 0) ? abs($l) / abs($r) : -(abs($l) / abs($r))} }
  }
}

proc lit {n} { dict create tag literal num $n }
proc bin {op l r} { dict create tag binary op $op lhs $l rhs $r }

set e [bin div [bin mul [bin sub [lit 7] [lit 10]] [lit 7]] [lit 2]]
puts [interp $e]
set f [bin div [bin add [lit 4] [lit 4]] [bin sub [lit 4] [lit 4]]]
puts [interp $f]
puts [interp $e]
