# A global, swapped and restored around the inner scope.
set pool {}

proc add {expr} { global pool; lappend pool $expr; expr {[llength $pool] - 1} }
proc get {ref} { global pool; lindex $pool $ref }

proc interp {ref} {
  set e [get $ref]
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

proc lit {n} { add [dict create tag literal num $n] }
proc bin {op l r} { add [dict create tag binary op $op lhs $l rhs $r] }

proc with_pool {body} {
  global pool
  set old $pool
  set pool {}
  try { uplevel 1 $body } finally { set pool $old }
}

set e [bin div [bin mul [bin sub [lit 7] [lit 10]] [lit 7]] [lit 2]]
puts [interp $e]
with_pool { puts [interp [bin div [bin add [lit 4] [lit 4]] [bin sub [lit 4] [lit 4]]]] }
puts [interp $e]
