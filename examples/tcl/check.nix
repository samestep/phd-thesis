{ pkgs, ... }:
{
  packages = [ pkgs.tcl ];
  run = "tclsh expr.tcl";
}
