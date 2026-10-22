# An option, rebound for a scope and restored with `on.exit`.
node <- function(...) {
  n <- list(...)
  p <- getOption("pool")
  p$nodes[[length(p$nodes) + 1]] <- n
  length(p$nodes)
}
lit <- function(n) node("lit", n)
add <- function(l, r) node("add", l, r)
mul <- function(l, r) node("mul", l, r)

ev <- function(e) {
  force(e)
  n <- getOption("pool")$nodes[[e]]
  switch(n[[1]],
    lit = n[[2]],
    add = ev(n[[2]]) + ev(n[[3]]),
    mul = ev(n[[2]]) * ev(n[[3]]))
}

pool <- function() { p <- new.env(); p$nodes <- list(); p }

with_pool <- function(code) {
  old <- options(pool = pool())
  on.exit(options(old))
  code
}

with_pool({
  e <- mul(add(lit(1), lit(2)), add(lit(3), lit(4)))
  cat(ev(e), "\n", sep = "")
  with_pool(cat(ev(add(lit(4), lit(4))), "\n", sep = ""))
  cat(ev(e), "\n", sep = "")
})
