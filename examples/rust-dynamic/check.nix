{ pkgs, ... }:
{
  packages = [ pkgs.rustc ];
  run = "rustc -O expr.rs -o expr && ./expr";
}
