{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    moss = {
      url = "github:moss-lang/moss";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    effekt = {
      url = "https://github.com/effekt-lang/effekt/releases/download/v0.82.0/effekt.tgz";
      flake = false;
    };
    granule-linux-x86_64 = {
      url = "https://github.com/granule-project/granule/releases/download/v0.9.6.0/granule-v0.9.6.0-linux_x86_64.zip";
      flake = false;
    };
    granule-macos-arm64 = {
      url = "https://github.com/granule-project/granule/releases/download/v0.9.6.0/granule-v0.9.6.0-macos_arm64.zip";
      flake = false;
    };
    ocaml-modular-implicits = {
      url = "github:ocamllabs/ocaml-modular-implicits";
      flake = false;
    };
  };
  outputs =
    inputs@{
      self,
      nixpkgs,
      moss,
      ...
    }:
    let
      inherit (nixpkgs) lib;
      # The platforms this is built on. (Nixpkgs no longer supports
      # x86_64-darwin.)
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
      perSystem = lib.genAttrs systems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
          mossPkg = moss.packages.${system}.default;

          # Every directory under `examples` is one example: its source files
          # plus a `check.nix` saying which packages it needs and how to run
          # it. Whatever it prints must match `examples/expected.txt`. A
          # `check.nix` gets `pkgs`, this flake's `inputs` (for sources
          # nixpkgs doesn't have), and `moss`.
          exampleNames = lib.attrNames (
            lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./examples)
          );
          example =
            name:
            let
              spec = import ./examples/${name}/check.nix {
                inherit pkgs inputs;
                moss = mossPkg;
              };
            in
            if !(spec.supported or true) then
              null
            else
              pkgs.runCommandCC "example-${name}" { nativeBuildInputs = spec.packages or [ ]; } ''
                cp -r ${./examples/${name}} src
                chmod -R u+w src
                cd src
                export HOME=$(mktemp -d)
                {
                  ${spec.run}
                } > actual
                diff -u ${./examples/expected.txt} actual
                touch $out
              '';
        in
        {
          packages.default = pkgs.runCommand "samestep-thesis" { buildInputs = [ pkgs.typst ]; } ''
            mkdir -p $out
            typst compile --root ${./.} ${./.}/proposal.typ $out/proposal.pdf
          '';
          checks = {
            pdf = self.packages.${system}.default;
          }
          // lib.filterAttrs (_: drv: drv != null) (
            lib.listToAttrs (map (name: lib.nameValuePair "example-${name}" (example name)) exampleNames)
          );
          devShells.default = pkgs.mkShellNoCC {
            packages = [
              pkgs.typst
              mossPkg
            ];
          };
        }
      );
    in
    # `perSystem` is keyed by system first; flake outputs are keyed by
    # output first.
    lib.genAttrs [ "packages" "checks" "devShells" ] (
      output: lib.mapAttrs (_: outputs: outputs.${output}) perSystem
    );
}
