# S3 generics: the option holds any object with `ast_add` and `ast_get`
# methods, and its references can be anything at all.
ast_add <- function(ast, expr) UseMethod("ast_add")
ast_get <- function(ast, ref) UseMethod("ast_get")

pool_add <- function(expr) {
  force(expr)
  ast_add(getOption("ast"), expr)
}
pool_get <- function(ref) {
  force(ref) # lazy: building the node must come before reading the pool
  ast_get(getOption("ast"), ref)
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

ops <- c("add", "sub", "mul", "div") # 0 is a literal

encode <- function(expr) {
  if (expr$tag == "literal") c(0, expr$num, 0)
  else c(match(expr$op, ops), unclass(expr$lhs), unclass(expr$rhs))
}

decode <- function(ref, row) {
  if (row[1] == 0) list(tag = "literal", num = row[2])
  else list(tag = "binary", op = ops[row[1]], lhs = ref(row[2]), rhs = ref(row[3]))
}

# Representation 1: a node is an index into parallel vectors.
idx <- function(i) structure(i, class = "idx")

columns <- function() {
  p <- new.env()
  p$ops <- p$lhs <- p$rhs <- numeric()
  structure(p, class = "columns")
}

ast_add.columns <- function(ast, expr) {
  row <- encode(expr)
  i <- length(ast$ops) + 1
  ast$ops[i] <- row[1]
  ast$lhs[i] <- row[2]
  ast$rhs[i] <- row[3]
  idx(i)
}

ast_get.columns <- function(ast, ref) {
  i <- unclass(ref)
  decode(idx, c(ast$ops[i], ast$lhs[i], ast$rhs[i]))
}

# Representation 2: a node is an index into one vector of triples.
slot <- function(i) structure(i, class = "slot")

triples <- function() {
  p <- new.env()
  p$triples <- numeric()
  structure(p, class = "triples")
}

ast_add.triples <- function(ast, expr) {
  ast$triples <- c(ast$triples, encode(expr))
  slot(length(ast$triples) / 3)
}

ast_get.triples <- function(ast, ref) {
  i <- 3 * unclass(ref)
  decode(slot, ast$triples[(i - 2):i])
}

with_ast <- function(ast, code) {
  old <- options(ast = ast)
  on.exit(options(old))
  code
}

with_ast(columns(), {
  e <- bin("div", bin("mul", bin("sub", lit(7), lit(10)), lit(7)), lit(2))
  cat(interp(e), "\n", sep = "")
  with_ast(triples(), cat(interp(bin("div", bin("add", lit(4), lit(4)), bin("sub", lit(4), lit(4)))), "\n", sep = ""))
  cat(interp(e), "\n", sep = "")
})
