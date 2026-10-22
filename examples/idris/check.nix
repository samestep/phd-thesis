{ pkgs, ... }:
{
  packages = [ pkgs.idris2 ];
  run = "idris2 Expr.idr -o expr >/dev/null && build/exec/expr";
}
