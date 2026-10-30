{ pkgs, ... }:
{
  packages = [ (pkgs.haskellPackages.ghcWithPackages (p: [ p.reflection ])) ];
  run = "ghc -v0 -O expr.hs -o expr && ./expr";
}
