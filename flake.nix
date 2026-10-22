{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    moss.url = "github:moss-lang/moss";
  };
  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      moss,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        inherit (pkgs) lib;
        mossPkg = moss.packages.${system}.default;

        # Every directory under `examples` is one example: its source files
        # plus a `check.nix` saying which packages it needs and how to run
        # it. Whatever it prints must match `examples/expected.txt`.
        exampleNames = lib.attrNames (
          lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./examples)
        );
        example =
          name:
          let
            spec = import ./examples/${name}/check.nix {
              inherit pkgs;
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
          # Moss resolves imports relative to the importing file, and its
          # compiler runs under WASI, so the standard library has to be a
          # real directory beside the example rather than a symlink.
          shellHook = ''
            rm -rf examples/moss/lib
            cp -r ${mossPkg}/share/moss/lib examples/moss/lib
            chmod -R u+w examples/moss/lib
          '';
        };
      }
    );
}
