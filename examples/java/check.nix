{ pkgs, ... }:
{
  packages = [ pkgs.jdk25 ];
  run = "java Expr.java";
}
