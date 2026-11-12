{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    moss = {
      url = "github:moss-lang/moss";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    effekt = {
      url = "https://github.com/effekt-lang/effekt/releases/download/v0.84.0/effekt.tgz";
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
    # basic-cli 0.20.0 is the last release for the Rust compiler. Fetch its
    # Brotli archive as a file and unpack it in the Roc checks.
    roc-basic-cli = {
      url = "file+https://github.com/roc-lang/basic-cli/releases/download/0.20.0/X73hGh05nNTkDHU06FHC0YfFaQB1pimX7gncRcao5mU.tar.br";
      flake = false;
    };
    # Jane Street's OCaml fork, from its own flake.
    oxcaml = {
      url = "github:oxcaml/oxcaml";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Bumpalo, for the Rust arena example: a `.crate` is a gzipped tarball.
    bumpalo = {
      url = "tarball+https://static.crates.io/crates/bumpalo/bumpalo-3.20.3.crate";
      flake = false;
    };
    # Node's own type declarations, and the `undici-types` they import, for
    # the TypeScript examples: Nixpkgs has neither.
    types-node = {
      url = "tarball+https://registry.npmjs.org/@types/node/-/node-26.6.6.tgz";
      flake = false;
    };
    undici-types = {
      url = "tarball+https://registry.npmjs.org/undici-types/-/undici-types-8.12.4.tgz";
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
      url = "github:sampsyo/flatcalc";
      flake = false;
    };
    flatcalc-flat = {
      url = "github:sampsyo/flatcalc/flat";
      flake = false;
    };
    # PostgreSQL's float8 aggregates as of version 11, the last release
    # with the schoolbook variance formula, which the `rerun` example
    # starts from. vendor/postgres keeps the file and its license, and a
    # check keeps them, and the C example's copies of its functions, the
    # same as these. Just the two files: the repository is far bigger.
    postgres-float = {
      url = "file+https://raw.githubusercontent.com/postgres/postgres/REL_11_22/src/backend/utils/adt/float.c";
      flake = false;
    };
    postgres-copyright = {
      url = "file+https://raw.githubusercontent.com/postgres/postgres/REL_11_22/COPYRIGHT";
      flake = false;
    };
    # PostgreSQL 11.22's source, to run postgres/NumAcc4.sql against: nixpkgs
    # has dropped version 11.
    postgresql = {
      url = "https://ftp.postgresql.org/pub/source/v11.22/postgresql-11.22.tar.bz2";
      flake = false;
    };
    # Virgil isn't in nixpkgs, and has no releases: its repository carries
    # stable compiler binaries to bootstrap the compiler from source with.
    virgil = {
      url = "github:titzer/virgil";
      flake = false;
    };
    # Wyvern isn't in nixpkgs, and has no releases: it's built from source
    # with Ant, from the jars its repository carries.
    wyvern = {
      url = "github:wyvernlang/wyvern";
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
          # name is its label there (see `snippet` in `lib.typ`).
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
            # Typst has no formatter of its own; this is typstyle's default
            # style. (Tinymist formats with typstyle, but at 120 columns
            # unless `tinymist.formatterPrintWidth` is set to 80.)
            typstyle = pkgs.runCommand "check-typstyle" { nativeBuildInputs = [ pkgs.typstyle ]; } ''
              cd ${./.}
              typstyle --check *.typ
              touch $out
            '';
            nixfmt = pkgs.runCommand "check-nixfmt" { nativeBuildInputs = [ pkgs.nixfmt ]; } ''
              cd ${./.}
              find . -name '*.nix' -exec nixfmt --check {} +
              touch $out
            '';
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
            # The `shadow` example runs the `rerun` example's routines
            # under Kahan's harness, unchanged: its copies of them must
            # stay the same code.
            shadow-routines =
              pkgs.runCommand "check-shadow-routines" { nativeBuildInputs = [ pkgs.python3 ]; }
                ''
                  python3 ${./vendor/flatcalc/verbatim.py} ${./examples/moss/rerun/context/main.moss} \
                    ${./examples/moss/shadow/context/stddev.moss} 'fn readings(' 'fn stddev(' 'fn show(' 'fn report('
                  touch $out
                '';
            # PostgreSQL 11.22 computes the standard deviation of NIST's
            # NumAcc4 data, certified 0.1, as exactly zero.
            numacc4 =
              let
                postgresql = import ./postgres/postgresql.nix {
                  inherit pkgs;
                  src = inputs.postgresql;
                };
              in
              pkgs.runCommand "check-numacc4" { nativeBuildInputs = [ postgresql ]; } ''
                initdb --pgdata=data --username=postgres --auth=trust --locale=C --no-sync > /dev/null
                pg_ctl --pgdata=data --log=log --wait --silent \
                  --options="-c listen_addresses= -k $PWD" start
                psql --host=$PWD --username=postgres --no-psqlrc --tuples-only --no-align \
                  --file=${./postgres/NumAcc4.sql} > actual
                pg_ctl --pgdata=data --wait --silent stop
                echo 0 | diff -u - actual
                touch $out
              '';
            # PostgreSQL's code, as vendor/postgres keeps it and as the C
            # `rerun` example quotes it.
            postgres = pkgs.runCommand "check-postgres" { nativeBuildInputs = [ pkgs.python3 ]; } ''
              diff -u ${inputs.postgres-float} ${./vendor/postgres/src/backend/utils/adt/float.c}
              diff -u ${inputs.postgres-copyright} ${./vendor/postgres/COPYRIGHT}
              python3 ${./vendor/postgres/excerpt.py} ${./vendor/postgres/src/backend/utils/adt/float.c} \
                ${./examples/c/rerun/rewrite/main.c} float8_accum float8_stddev_samp
              touch $out
            '';
          }
          // lib.filterAttrs (_: drv: drv != null) (lib.listToAttrs (map example examples));
        }
      );
    in
    # `perSystem` is keyed by system first; flake outputs are keyed by
    # output first.
    lib.genAttrs [ "packages" "checks" ] (
      output: lib.mapAttrs (_: outputs: outputs.${output}) perSystem
    );
}
