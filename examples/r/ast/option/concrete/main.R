# An option, rebound for a scope and restored with `on.exit`.
pool_add <- function(expr) {
  force(expr)
  p <- getOption("pool")
  p$nodes[[length(p$nodes) + 1]] <- expr
  length(p$nodes)
}
pool_get <- function(ref) {
  force(ref) # lazy: building the node must come before reading the pool
  getOption("pool")$nodes[[ref]]
}

interp <- function(ref) {
  expr <- pool_get(ref)
  if (expr$tag == "literal") return(expr$num)
  l <- interp(expr$lhs)
  r <- interp(expr$rhs)
  switch(expr$op,
    add = l + r,
    sub = l - r,
    mul = l * r,
    div = if (r == 0) 0 else trunc(l / r))
}

lit <- function(n) pool_add(list(tag = "literal", num = n))
bin <- function(op, l, r) pool_add(list(tag = "binary", op = op, lhs = l, rhs = r))

new_pool <- function() { p <- new.env(); p$nodes <- list(); p }

with_pool <- function(code) {
  old <- options(pool = new_pool())
  on.exit(options(old))
  code
}

with_pool({
  e <- bin("div", bin("mul", bin("sub", lit(7), lit(10)), lit(7)), lit(2))
  cat(interp(e), "\n", sep = "")
  with_pool(cat(interp(bin("div", bin("add", lit(4), lit(4)), bin("sub", lit(4), lit(4)))), "\n", sep = ""))
  cat(interp(e), "\n", sep = "")
})
