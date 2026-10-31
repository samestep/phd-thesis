# `local` is dynamically scoped: callees see the caller's pool.
pool=()

# Results come back in `r`, since a subshell couldn't add to the pool.
add() { pool+=("$*"); r=$((${#pool[@]} - 1)); }
get() { r=${pool[$1]}; }

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

inner() {
  local pool=()
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
