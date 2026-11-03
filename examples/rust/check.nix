{ pkgs, ... }:
{
  packages = [ pkgs.rustc ];
  run = "rustc -O --edition 2024 \"$main\" -o main && ./main";
}
