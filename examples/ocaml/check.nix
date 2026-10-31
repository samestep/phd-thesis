{ pkgs, ... }:
{
  packages = [ pkgs.ocaml ];
  run = "ocamlopt main.ml -o main && ./main";
}
