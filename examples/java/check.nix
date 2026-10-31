{ pkgs, ... }:
{
  packages = [ pkgs.jdk25 ];
  run = "java Main.java";
}
