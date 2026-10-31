{ pkgs, ... }:
{
  packages = [ (pkgs.haskellPackages.ghcWithPackages (p: [ p.reflection ])) ];
  run = "ghc -v0 -O main.hs -o main && ./main";
}
