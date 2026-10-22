{ pkgs, ... }:
{
  packages = [ pkgs.lean4 ];
  run = "lean --run expr.lean";
}
