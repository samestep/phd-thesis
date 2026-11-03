{ pkgs, ... }:
{
  # With `compensated`, Kmett's double-double (`Compensated Double`).
  packages = [ (pkgs.haskellPackages.ghcWithPackages (p: [ p.compensated ])) ];
  run = "ghc -v0 -O main.hs -o main && ./main";
}
