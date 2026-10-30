{ pkgs, ... }:
{
  # On macOS the launcher Idris generates resolves its own path with zsh.
  packages = [
    pkgs.idris2
    pkgs.zsh
  ];
  run = "idris2 Expr.idr -o expr >/dev/null && build/exec/expr";
}
