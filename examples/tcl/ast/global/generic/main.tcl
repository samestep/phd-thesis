# Duck typing: the global names any object with `add` and `get` methods, and
# its references can be any string at all.
set ast {}

proc interp {ref} {
  set e [$::ast get $ref]
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

proc lit {n} { $::ast add [dict create tag literal num $n] }
proc bin {op l r} { $::ast add [dict create tag binary op $op lhs $l rhs $r] }

set ops {{} add sub mul div} ;# 0 is a literal

# A reference is a tagged list, like {Idx 3} or {Slot 3}.
proc encode {e} {
  if {[dict get $e tag] eq "literal"} { return [list 0 [dict get $e num] 0] }
  list [lsearch $::ops [dict get $e op]] [lindex [dict get $e lhs] 1] [lindex [dict get $e rhs] 1]
}

proc decode {tag op l r} {
  if {$op == 0} { return [dict create tag literal num $l] }
  dict create tag binary op [lindex $::ops $op] lhs [list $tag $l] rhs [list $tag $r]
}

# Representation 1: a node is an index into parallel lists.
oo::class create Columns {
  variable ops lhs rhs
  constructor {} { set ops {}; set lhs {}; set rhs {} }
  method add {e} {
    lassign [encode $e] op l r
    lappend ops $op; lappend lhs $l; lappend rhs $r
    list Idx [expr {[llength $ops] - 1}]
  }
  method get {ref} {
    set i [lindex $ref 1]
    decode Idx [lindex $ops $i] [lindex $lhs $i] [lindex $rhs $i]
  }
}

# Representation 2: a node is an index into one list of triples.
oo::class create Triples {
  variable triples
  constructor {} { set triples {} }
  method add {e} {
    lappend triples {*}[encode $e]
    list Slot [expr {[llength $triples] / 3 - 1}]
  }
  method get {ref} {
    set i [expr {3 * [lindex $ref 1]}]
    decode Slot {*}[lrange $triples $i [expr {$i + 2}]]
  }
}

proc with_ast {a body} {
  global ast
  set old $ast
  set ast $a
  try { uplevel 1 $body } finally { set ast $old }
}

set ast [Columns new]
set e [bin div [bin mul [bin sub [lit 7] [lit 10]] [lit 7]] [lit 2]]
puts [interp $e]
with_ast [Triples new] { puts [interp [bin div [bin add [lit 4] [lit 4]] [bin sub [lit 4] [lit 4]]]] }
puts [interp $e]
