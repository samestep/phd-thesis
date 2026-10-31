# `local` is dynamically scoped: callees see the caller's `ast`, which names
# the functions to call. A reference is whatever word they hand back.
ast=columns

# Results come back in `r`, since a subshell couldn't add to the pool.
add() { "${ast}_add" "$@"; }
get() { "${ast}_get" "$1"; }

interp() {
  local tag op lhs rhs l
  get "$1"
  read -r tag op lhs rhs <<< "$r"
  if [[ $tag == literal ]]; then r=$op; return; fi
  interp "$lhs"; l=$r
  interp "$rhs"
  case $op in
    add) r=$((l + r)) ;;
    sub) r=$((l - r)) ;;
    mul) r=$((l * r)) ;;
    div) if ((r == 0)); then r=0; else r=$((l / r)); fi ;;
  esac
}

lit() { add literal "$1"; }
bin() { add binary "$1" "$2" "$3"; }

ops=('' add sub mul div) # 0 is a literal
declare -A code=([add]=1 [sub]=2 [mul]=3 [div]=4)

# Representation 1: a node is an index into parallel arrays.
col_ops=() col_lhs=() col_rhs=()

columns_add() {
  if [[ $1 == literal ]]; then col_ops+=(0) col_lhs+=("$2") col_rhs+=(0)
  else col_ops+=("${code[$2]}") col_lhs+=("$3") col_rhs+=("$4"); fi
  r=$((${#col_ops[@]} - 1))
}

columns_get() {
  local op=${col_ops[$1]}
  if ((op == 0)); then r="literal ${col_lhs[$1]}"
  else r="binary ${ops[op]} ${col_lhs[$1]} ${col_rhs[$1]}"; fi
}

# Representation 2: a node is an index into one array of triples.
triples=()

triples_add() {
  if [[ $1 == literal ]]; then triples+=(0 "$2" 0)
  else triples+=("${code[$2]}" "$3" "$4"); fi
  r=$((${#triples[@]} / 3 - 1))
}

triples_get() {
  local i=$((3 * $1))
  if ((triples[i] == 0)); then r="literal ${triples[i + 1]}"
  else r="binary ${ops[triples[i]]} ${triples[i + 1]} ${triples[i + 2]}"; fi
}

inner() {
  local ast=triples triples=()
  lit 4; local a=$r; lit 4; bin add "$a" "$r"; local s=$r
  lit 4; a=$r; lit 4; bin sub "$a" "$r"
  bin div "$s" "$r"; interp "$r"; echo "$r"
}

lit 7; a=$r; lit 10; bin sub "$a" "$r"; s=$r
lit 7; bin mul "$s" "$r"; m=$r
lit 2; bin div "$m" "$r"; e=$r
interp "$e"; echo "$r"
inner
interp "$e"; echo "$r"
