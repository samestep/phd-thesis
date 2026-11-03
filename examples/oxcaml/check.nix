{ pkgs, inputs, ... }:
{
  packages = [
    # Without the compiler's own test suite, which takes 11 to 23 minutes per
    # platform in CI and checks OxCaml rather than these examples.
    (inputs.oxcaml.packages.${pkgs.stdenv.hostPlatform.system}.oxcaml.overrideAttrs { doCheck = false; })
  ];
  run = "ocamlopt main.ml -o main && ./main";
}
