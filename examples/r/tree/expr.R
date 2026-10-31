# The tree Sampson starts from: each node is a list whose children are nested
# lists, so nothing needs a pool; R copies values rather than sharing nodes.
interp <- function(expr) {
  if (expr$tag == "literal") return(expr$num)
  l <- interp(expr$lhs)
  r <- interp(expr$rhs)
  switch(expr$op,
    add = l + r,
    sub = l - r,
    mul = l * r,
    div = if (r == 0) 0 else trunc(l / r))
}

lit <- function(n) list(tag = "literal", num = n)
bin <- function(op, l, r) list(tag = "binary", op = op, lhs = l, rhs = r)

e <- bin("div", bin("mul", bin("sub", lit(7), lit(10)), lit(7)), lit(2))
cat(interp(e), "\n", sep = "")
local({
  f <- bin("div", bin("add", lit(4), lit(4)), bin("sub", lit(4), lit(4)))
  cat(interp(f), "\n", sep = "")
})
cat(interp(e), "\n", sep = "")
