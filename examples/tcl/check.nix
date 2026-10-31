{ pkgs, ... }:
{
  packages = [ pkgs.tcl ];
  run = "tclsh main.tcl";
}
