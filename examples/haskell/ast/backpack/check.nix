{ pkgs, ... }:
{
  packages = [ pkgs.ghc ];
  run = "ghc -v0 --backpack main.bkp && ./main/Main";
}
