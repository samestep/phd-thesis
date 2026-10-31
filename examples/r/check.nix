{ pkgs, ... }:
{
  packages = [ pkgs.R ];
  run = "Rscript --vanilla main.R";
}
