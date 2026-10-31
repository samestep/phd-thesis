{ pkgs, ... }:
let
  inherit (pkgs) lib;
  # An ASDF system and everything it depends on.
  closure = ps: lib.unique (lib.concatMap (p: [ p ] ++ closure p.lispLibs) ps);
in
{
  packages = [ pkgs.sbcl ];
  # What `sbcl.withPackages` would set, but its wrapper no longer builds: Nixpkgs
  # compiles each system's fasls next to its source in the store.
  run = ''
    export CL_SOURCE_REGISTRY=${
      lib.concatMapStringsSep ":" (p: "${p}//") (closure [ pkgs.sbclPackages.contextl ])
    }
    export ASDF_OUTPUT_TRANSLATIONS=/nix/store:/nix/store
    sbcl --script main.lisp
  '';
}
