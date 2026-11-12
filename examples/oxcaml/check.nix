{ pkgs, inputs, ... }:
let
  inherit (pkgs) lib;

  # OxCaml's Menhir install hook assumes menhirLib is in the main output.
  # Nixpkgs now installs OCaml libraries in the dev output.
  fixMenhir =
    package:
    if (package.pname or null) == "menhir" then
      package.overrideAttrs (
        old:
        let
          menhirLib = lib.findFirst (
            input: (input.pname or null) == "menhirLib"
          ) (throw "OxCaml's Menhir is missing menhirLib") old.buildInputs;
        in
        {
          postInstall = ''
            mkdir -p "$out/lib"
            ln -s ${lib.getDev menhirLib}/lib/ocaml/*/site-lib/menhirLib "$out/lib/"
          '';
        }
      )
    else
      package;
in
{
  packages = [
    # Without the compiler's own test suite, which takes 11 to 23 minutes per
    # platform in CI and checks OxCaml rather than these examples.
    (inputs.oxcaml.packages.${pkgs.stdenv.hostPlatform.system}.oxcaml.overrideAttrs (old: {
      doCheck = false;
      nativeBuildInputs = map fixMenhir old.nativeBuildInputs;
    }))
  ];
  run = "ocamlopt main.ml -o main && ./main";
}
