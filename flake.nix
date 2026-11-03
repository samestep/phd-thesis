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
    # Sampson's flatcalc, which the `ast` example starts from: its `main`
    # branch is the tree, its `flat` branch the pool. vendor/flatcalc keeps
    # both files, and a check keeps them, and the Rust examples' copies of
    # their items, the same as these.
    flatcalc = {
      url = "github:sampsyo/flatcalc/5a5d1a72edb073e7be15568bf6ac2b200743a376";
      flake = false;
    };
    flatcalc-flat = {
      url = "github:sampsyo/flatcalc/4cbc6aff14289144daae0395747a258e442b2984";
      flake = false;
    };
    # Virgil isn't in nixpkgs, and has no releases: its repository carries
    # stable compiler binaries to bootstrap the compiler from source with.
    virgil = {
      url = "github:titzer/virgil/d83efd1b0076e292efca1ccf4830e2f6faf6ade5";
      flake = false;
    };
    # Wyvern isn't in nixpkgs, and has no releases: it's built from source
    # with Ant, from the jars its repository carries.
    wyvern = {
      url = "github:wyvernlang/wyvern/95c92ec72737c4a4b698ba5f66a728eb14434921";
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

          # Every example is a directory of source files under
          # `examples/<language>/<program>/`: `<mechanism>/<variant>` for a
          # program written with one mechanism for passing its context in
          # several variants (for `ast`: `concrete`, a fixed index type;
          # `generic`, an abstract one; or `dynamic`, dispatch at run time),
          # just `<mechanism>` for one with no variants, and `ast/tree` for the
          # pointer-based tree that flattening starts from. A directory is an
          # example if it holds any file but a `check.nix`. The nearest
          # `check.nix` above an example says which packages it needs and how
          # to run its `main` file: usually the language's, and a mechanism's
          # own where its toolchain differs. Whatever an example prints must
          # match `examples/<program>.txt`. A `check.nix` gets `pkgs`, this
          # flake's `inputs` (for sources nixpkgs doesn't have), and `moss`.
          # A `run` names the file it runs as `$main`: the example's `main.*`,
          # or else its one file, for an example the proposal shows, whose
          # name is its label there (see `snippet.typ`).
          # It may also list `shared` files, paths under `examples/<language>`
          # that its examples import: they are copied in beside the example
          # where they sit in the repository, so a relative import reaches
          # them in the build as it does in a checkout.
          # Each example as the list of its path segments under `examples`.
          examples =
            let
              walk =
                segments:
                let
                  entries = builtins.readDir (./examples + "/${lib.concatStringsSep "/" segments}");
                  files = lib.attrNames (
                    lib.filterAttrs (name: type: type != "directory" && name != "check.nix") entries
                  );
                  dirs = lib.attrNames (lib.filterAttrs (_: type: type == "directory") entries);
                in
                if files != [ ] then [ segments ] else lib.concatMap (dir: walk (segments ++ [ dir ])) dirs;
            in
            lib.concatMap (
              language:
              lib.concatMap
                (
                  program:
                  walk [
                    language
                    program
                  ]
                )
                (
                  lib.attrNames (
                    lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./examples/${language})
                  )
                )
            ) (lib.attrNames (lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./examples)));
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
              files = lib.attrNames (lib.filterAttrs (_: type: type != "directory") (builtins.readDir dir));
              mains = lib.filter (lib.hasPrefix "main.") files;
              main =
                if mains != [ ] then
                  lib.head mains
                else if lib.length files == 1 then
                  lib.head files
                else
                  throw "${name}: no main.* file, and more than one file";
              shared = spec.shared or [ ];
              # The example's place under its language's directory.
              rel = lib.concatStringsSep "/" (lib.drop 1 segments);
              setup =
                if shared == [ ] then
                  "cp -r ${dir} src\nchmod -R u+w src\ncd src"
                else
                  ''
                    mkdir -p tree/${rel}
                    cp -r ${dir}/. tree/${rel}
                    ${lib.concatMapStrings (
                      file: "cp ${under [ (lib.head segments) ] + "/${file}"} tree/${file}\n"
                    ) shared}
                    chmod -R u+w tree
                    cd tree/${rel}
                  '';
            in
            lib.nameValuePair name (
              if !(spec.supported or true) then
                null
              else
                pkgs.runCommandCC name { nativeBuildInputs = spec.packages or [ ]; } ''
                  ${setup}
                  export HOME=$(mktemp -d)
                  main=${lib.escapeShellArg main}
                  {
                    ${spec.run}
                  } > actual
                  diff -u ${./examples + "/${builtins.elemAt segments 1}.txt"} actual
                  touch $out
                ''
            );
          # The Moss grammar Typst highlights with, converted from the one
          # Moss's VS Code extension uses. It's checked in, because the PDF
          # also builds without flakes, so a check keeps it generated.
          mossSyntax =
            pkgs.runCommand "moss.sublime-syntax"
              { nativeBuildInputs = [ (pkgs.python3.withPackages (ps: [ ps.pyyaml ])) ]; }
              ''
                python3 ${./syntaxes/tmlanguage-to-sublime.py} ${moss}/vscode/syntaxes/moss.tmLanguage.json > $out
              '';
        in
        {
          packages = {
            default = import ./default.nix { inherit pkgs; };
            moss-syntax = mossSyntax;
          };
          checks = {
            pdf = self.packages.${system}.default;
            moss-syntax = pkgs.runCommand "check-moss-syntax" { } ''
              if ! diff -u ${./syntaxes/moss.sublime-syntax} ${mossSyntax}; then
                echo 'syntaxes/moss.sublime-syntax is out of date; regenerate it with:'
                echo '  nix build .#moss-syntax && cat result > syntaxes/moss.sublime-syntax'
                exit 1
              fi
              touch $out
            '';
            # Sampson's code, as vendor/flatcalc keeps it and as the Rust
            # `ast` examples quote it.
            flatcalc = pkgs.runCommand "check-flatcalc" { nativeBuildInputs = [ pkgs.python3 ]; } ''
              diff -u ${inputs.flatcalc}/src/main.rs ${./vendor/flatcalc/main/src/main.rs}
              diff -u ${inputs.flatcalc-flat}/src/main.rs ${./vendor/flatcalc/flat/src/main.rs}
              diff -u ${inputs.flatcalc}/LICENSE ${./vendor/flatcalc/LICENSE}
              python3 ${./vendor/flatcalc/verbatim.py} ${./vendor/flatcalc/main/src/main.rs} \
                ${./examples/rust/ast/tree/tree.rs} 'enum BinOp' 'enum Expr' 'impl Expr'
              python3 ${./vendor/flatcalc/verbatim.py} ${./vendor/flatcalc/flat/src/main.rs} \
                ${./examples/rust/ast/explicit/concrete/flat.rs} 'enum BinOp' 'enum Expr' \
                'struct ExprRef' 'struct ExprPool' 'fn get(' 'fn add(' 'fn interp('
              touch $out
            '';
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
