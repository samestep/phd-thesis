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
    # Granule's own flake, for platforms without a release binary: its
    # 0.9.6.0 release plus the fix that last made the flake build (#280).
    # The next commit (#291) broke it again.
    granule = {
      url = "github:granule-project/granule/645e5e0bd89c0d5ace9445219f7e801e8fe56479";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    # Roc's old (Rust) compiler, which has module params; the new Zig one
    # doesn't. Nixpkgs packages this release only for x86_64 Linux.
    roc-linux-x86_64 = {
      url = "https://github.com/roc-lang/roc/releases/download/alpha4-rolling/roc-linux_x86_64-alpha4-rolling.tar.gz";
      flake = false;
    };
    roc-linux-arm64 = {
      url = "https://github.com/roc-lang/roc/releases/download/alpha4-rolling/roc-linux_arm64-alpha4-rolling.tar.gz";
      flake = false;
    };
    roc-macos-arm64 = {
      url = "https://github.com/roc-lang/roc/releases/download/alpha4-rolling/roc-macos_apple_silicon-alpha4-rolling.tar.gz";
      flake = false;
    };
    # The basic-cli platform release that goes with it, with prebuilt hosts
    # for every target. It's a Brotli tarball, which Nix can't unpack.
    roc-basic-cli = {
      url = "file+https://github.com/roc-lang/basic-cli/releases/download/0.20.0/X73hGh05nNTkDHU06FHC0YfFaQB1pimX7gncRcao5mU.tar.br";
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

          # Every example is a directory of source files,
          # `examples/<language>/<mechanism>/<variant>`, where the variant is
          # `concrete` (a fixed index type), `generic` (an abstract one) or
          # `dynamic` (dispatch at run time); or `examples/<language>/tree`, the
          # pointer-based tree that flattening starts from, which has no pool to
          # pass. The nearest `check.nix` above it says which packages it needs
          # and how to run it: usually the language's, and a mechanism's own
          # where its toolchain differs. Whatever an example prints must match
          # `examples/expected.txt`. A `check.nix` gets `pkgs`, this flake's
          # `inputs` (for sources nixpkgs doesn't have), and `moss`.
          subdirs =
            dir: lib.attrNames (lib.filterAttrs (_: type: type == "directory") (builtins.readDir dir));
          # Each example as the list of its path segments under `examples`.
          examples = lib.concatMap (
            language:
            lib.concatMap (
              mechanism:
              if mechanism == "tree" then
                [
                  [
                    language
                    "tree"
                  ]
                ]
              else
                map (variant: [
                  language
                  mechanism
                  variant
                ]) (subdirs ./examples/${language}/${mechanism})
            ) (subdirs ./examples/${language})
          ) (subdirs ./examples);
          example =
            segments:
            let
              under = segments: ./examples + "/${lib.concatStringsSep "/" segments}";
              # The directories above the example, nearest first.
              parents = map (n: lib.take n segments) (lib.reverseList (lib.range 1 (lib.length segments - 1)));
              check = lib.findFirst builtins.pathExists null (map (dir: under dir + "/check.nix") parents);
              spec = import check {
                inherit pkgs inputs;
                moss = mossPkg;
              };
              name = "example-${lib.concatStringsSep "-" segments}";
              dir = under segments;
            in
            lib.nameValuePair name (
              if !(spec.supported or true) then
                null
              else
                pkgs.runCommandCC name { nativeBuildInputs = spec.packages or [ ]; } ''
                  cp -r ${dir} src
                  chmod -R u+w src
                  cd src
                  export HOME=$(mktemp -d)
                  {
                    ${spec.run}
                  } > actual
                  diff -u ${./examples/expected.txt} actual
                  touch $out
                ''
            );
        in
        {
          packages.default = pkgs.runCommand "samestep-thesis" { buildInputs = [ pkgs.typst ]; } ''
            mkdir -p $out
            typst compile --root ${./.} ${./.}/proposal.typ $out/proposal.pdf
          '';
          checks = {
            pdf = self.packages.${system}.default;
          }
          // lib.filterAttrs (_: drv: drv != null) (lib.listToAttrs (map example examples));
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
