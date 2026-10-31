{ pkgs, ... }:
{
  packages = [ pkgs.sbcl ];
  run = "sbcl --script main.lisp";
}
