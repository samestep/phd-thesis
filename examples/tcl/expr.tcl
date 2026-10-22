# A global, swapped and restored around the inner scope.
set pool {}

proc node {args} { global pool; lappend pool $args; expr {[llength $pool] - 1} }
proc lit {n} { node lit $n }
proc add {l r} { node add $l $r }
proc mul {l r} { node mul $l $r }

proc ev {e} {
  global pool
  lassign [lindex $pool $e] op a b
  switch $op {
    lit { return $a }
    add { expr {[ev $a] + [ev $b]} }
    mul { expr {[ev $a] * [ev $b]} }
  }
}

proc with_pool {body} {
  global pool
  set old $pool
  set pool {}
  try { uplevel 1 $body } finally { set pool $old }
}

set e [mul [add [lit 1] [lit 2]] [add [lit 3] [lit 4]]]
puts [ev $e]
with_pool { puts [ev [add [lit 4] [lit 4]]] }
puts [ev $e]
