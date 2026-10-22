# `local` is dynamically scoped: callees see the caller's pool.
pool=()

node() { pool+=("$*"); r=$((${#pool[@]} - 1)); }
lit() { node lit "$1"; }
add() { node add "$1" "$2"; }
mul() { node mul "$1" "$2"; }

ev() {
  local op a b x
  read -r op a b <<< "${pool[$1]}"
  case $op in
    lit) r=$a ;;
    add) ev "$a"; x=$r; ev "$b"; r=$((x + r)) ;;
    mul) ev "$a"; x=$r; ev "$b"; r=$((x * r)) ;;
  esac
}

inner() {
  local pool=()
  lit 4; local x=$r; lit 4; add "$x" "$r"; ev "$r"; echo "$r"
}

lit 1; a=$r; lit 2; add "$a" "$r"; ab=$r
lit 3; c=$r; lit 4; add "$c" "$r"; mul "$ab" "$r"; e=$r
ev "$e"; echo "$r"
inner
ev "$e"; echo "$r"
