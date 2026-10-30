{ pkgs, ... }:
{
  packages = [ pkgs.ruby ];
  run = "ruby expr.rb";
}
