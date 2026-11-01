{ pkgs, inputs, ... }:
let
  inherit (pkgs) lib;
  jdk = pkgs.jdk_headless;
  # What `bin/wyvern` puts on the class path: the compiled tools and the
  # jars they need at run time.
  classpath = [
    "tools/build"
    "tools/lib/CopperRuntime.jar"
    "tools/lib/asm-debug-all-5.0.1.jar"
    "tools/lib/junit-4.11.jar"
    "tools/lib/protobuf-java-3.5.1.jar"
  ];
  wyvern = pkgs.stdenv.mkDerivation {
    pname = "wyvern";
    version = "0-unstable-2026-10-21";
    src = inputs.wyvern;
    # The type checker guards against runaway recursion with a static
    # counter, which it doesn't decrement when an exception unwinds through
    # it, and some of those exceptions are caught; so in a big enough program
    # the count creeps up until a well-typed one fails with "Internal error:
    # recursion". This decrements it however the call ends.
    patches = [ ./nesting-count.patch ];
    nativeBuildInputs = [
      pkgs.ant
      jdk
      pkgs.makeWrapper
    ];
    # Generate the lexers and parsers (with Copper and JavaCC, from the
    # repository's jars) and compile the interpreter.
    buildPhase = ''
      runHook preBuild
      (cd tools && ant build)
      runHook postBuild
    '';
    # The interpreter finds the standard library through `WYVERN_HOME`, and
    # the program's own modules in the working directory.
    installPhase = ''
      runHook preInstall
      mkdir -p $out/share/wyvern/tools $out/bin
      cp -r stdlib $out/share/wyvern
      cp -r tools/build tools/lib $out/share/wyvern/tools
      makeWrapper ${jdk}/bin/java $out/bin/wyvern \
        --set WYVERN_HOME $out/share/wyvern \
        --add-flags "-cp ${
          lib.concatMapStringsSep ":" (path: "$out/share/wyvern/${path}") classpath
        } wyvern.tools.Interpreter"
      runHook postInstall
    '';
  };
in
{
  packages = [ wyvern ];
  run = "wyvern main.wyv";
}
