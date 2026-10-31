{ pkgs, ... }:
let
  # nixpkgs builds Eff against OCaml 5.2, the last release that compiles it
  # as is: 5.3 made `effect` a keyword, and Eff uses it as an identifier.
  # But OCaml 5.2's own test suite fails on aarch64-darwin (a backtrace
  # truncated through no-alloc C calls, ocaml/ocaml#13595, fixed in 5.4).
  # So build Eff with the default OCaml, telling every compiler tool to
  # use 5.2's keywords.
  eff =
    (pkgs.eff.override {
      ocaml-ng = pkgs.ocaml-ng // {
        ocamlPackages_5_2 = pkgs.ocamlPackages;
      };
    }).overrideAttrs
      { env.OCAMLPARAM = "_,keywords=5.2"; };
in
{
  packages = [ eff ];
  # The toplevel echoes every definition's type; keep only what the program prints.
  run = "eff main.eff 2>/dev/null | grep -Ev '^(val |- : )'";
}
