{ pkgs, ... }:
{
  packages = [ pkgs.sbcl ];
  run = "sbcl --script expr.lisp";
}
