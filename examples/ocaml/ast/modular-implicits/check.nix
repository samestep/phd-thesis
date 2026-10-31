{ pkgs, inputs, ... }:
let
  # The modular implicits prototype: a 2014 fork of OCaml 4.02, bytecode only.
  ocamlmi = pkgs.stdenv.mkDerivation {
    pname = "ocaml-modular-implicits";
    version = "4.02.1-mi";
    src = inputs.ocaml-modular-implicits;
    env.NIX_CFLAGS_COMPILE = "-fcommon -std=gnu89 -Wno-error -Wno-implicit-function-declaration -Wno-int-conversion -Wno-incompatible-pointer-types";
    dontStrip = true;
    configurePhase = ''
      ./configure -prefix $out -no-curses -no-graph
    '';
    buildPhase = "make coldstart && make ocamlc ocaml && (cd stdlib && make all)";
    installPhase = ''
      mkdir -p $out/bin $out/lib/ocaml
      cp byterun/ocamlrun $out/bin/
      cp ocamlc $out/lib/ocaml/ocamlc.byte
      cp stdlib/*.cmi stdlib/*.cma stdlib/std_exit.cmo $out/lib/ocaml/
    '';
  };
in
{
  packages = [ ocamlmi ];
  run = "${ocamlmi}/lib/ocaml/ocamlc.byte -nostdlib -I ${ocamlmi}/lib/ocaml main.ml -o main >&2 && ocamlrun ./main";
}
