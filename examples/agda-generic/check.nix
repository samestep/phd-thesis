{ pkgs, ... }:
{
  packages = [ (pkgs.agda.withPackages (p: [ p.standard-library ])) ];
  run = ''
    export LANG=C.UTF-8
    agda --compile --ghc-flag=-v0 Expr.agda >/dev/null && ./Expr
  '';
}
