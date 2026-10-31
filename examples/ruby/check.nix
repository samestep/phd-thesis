{ pkgs, ... }:
{
  packages = [ pkgs.ruby ];
  run = "ruby main.rb";
}
