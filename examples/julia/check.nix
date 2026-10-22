{ pkgs, ... }:
{
  packages = [ pkgs.julia ];
  run = "julia --startup-file=no expr.jl";
}
