{ pkgs, ... }:
{
  packages = [ pkgs.fstar ];
  run = "fstar.exe Main.fst | sed -n 's/^TAC>> \\(-\\?[0-9]*\\) .*/\\1/p'";
}
