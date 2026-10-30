{ pkgs, ... }:
{
  packages = [ pkgs.ghc ];
  run = "ghc -v0 --backpack expr.bkp && ./main/Main";
}
