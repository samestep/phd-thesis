{ pkgs, inputs, ... }:
{
  packages = [ inputs.oxcaml.packages.${pkgs.stdenv.hostPlatform.system}.oxcaml ];
  run = "ocamlopt main.ml -o main && ./main";
}
