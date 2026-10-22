{ pkgs, ... }:
{
  packages = [ pkgs.ante ];
  run = "ante expr.an";
}
