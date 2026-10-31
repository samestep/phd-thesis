{ pkgs, ... }:
{
  packages = [ pkgs.rustc ];
  run = "rustc -O main.rs -o main && ./main";
}
