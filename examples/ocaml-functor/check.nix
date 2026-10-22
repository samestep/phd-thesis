{ pkgs, ... }:
{
  packages = [ pkgs.ocaml ];
  run = "ocamlopt expr.ml -o expr && ./expr";
}
