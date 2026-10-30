{ pkgs, ... }:
{
  packages = [ pkgs.ghc ];
  run = "ghc -v0 -O expr.hs -o expr && ./expr";
}
