{ pkgs, ... }:
{
  packages = [ pkgs.R ];
  run = "Rscript --vanilla expr.R";
}
