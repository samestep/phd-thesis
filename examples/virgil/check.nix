{ pkgs, inputs, ... }:
let
  inherit (pkgs) lib stdenv;
  # Virgil's compiler, Aeneas, is written in Virgil, and its repository has
  # stable binaries of it for x86 Linux and macOS and for the JVM, to compile
  # the compiler from source with. Arm64 Linux compiles it through the JVM
  # to a native compiler; there's no arm64 macOS target, so there the
  # compiler is the JVM one.
  host =
    {
      x86_64-linux = "x86-64-linux";
      aarch64-linux = "arm64-linux";
      aarch64-darwin = "jar";
    }
    .${stdenv.hostPlatform.system};
  stable = if host == "x86-64-linux" then host else "jar";
  jdk = pkgs.jdk_headless;
  virgil = stdenv.mkDerivation {
    pname = "virgil";
    version = "0-unstable-2026-10-30";
    src = inputs.virgil;
    nativeBuildInputs = [
      jdk
      pkgs.makeWrapper
    ];
    postPatch = "patchShebangs bin";
    # What `aeneas bootstrap` does: compile the compiler with the stable one,
    # then with the result. But the JVM compiler's launcher script that the
    # first step makes starts with `/usr/bin/env`, which the build sandbox
    # lacks, so it has to be patched before the second step runs it.
    buildPhase = ''
      runHook preBuild
      compile() {
        mkdir -p bin/$1/$3
        V3C=$2 bin/v3c-$3 -fp -heap-size=800m -jvm.script \
          -jvm.args="-client -Xms900m -Xmx900m -XX:+UseSerialGC" \
          -output=bin/$1/$3 aeneas/src/*/*.v3 $(cat aeneas/DEPS)
        patchShebangs bin/$1/$3
      }
      compile bootstrap bin/stable/${stable}/Aeneas ${stable}
      compile current bin/bootstrap/${stable}/Aeneas ${host}
      runHook postBuild
    '';
    # Aeneas's native executables are static and have no section headers,
    # which stripping would break.
    dontStrip = true;
    dontPatchELF = true;
    # Keep the repository's layout, which the compiler's launcher scripts
    # find the runtime and the libraries by. They compile for Wasm with
    # WASI preview 1 (`wasm`, a linear memory with Virgil's own collector)
    # or with Wasm GC objects too (`wasm-gc`).
    installPhase = ''
      runHook preInstall
      mkdir -p $out/share/virgil/bin/dev $out/bin
      cp -r rt lib $out/share/virgil
      cp -r bin/current/${host} $out/share/virgil/bin/aeneas
      ln -s aeneas/Aeneas $out/share/virgil/bin/v3c
      cp bin/dev/v3c-wasm-wasi1 bin/dev/v3c-wasm-gc-wasi1 $out/share/virgil/bin/dev
      for script in v3c-wasm-wasi1 v3c-wasm-gc-wasi1; do
        makeWrapper $out/share/virgil/bin/dev/$script $out/bin/$script \
          ${lib.optionalString (host == "jar") "--prefix PATH : ${jdk}/bin"}
      done
      runHook postInstall
    '';
  };
in
{
  packages = [
    virgil
    pkgs.wasmtime
  ];
  # Compile for both Wasm targets, run each under Wasmtime, and check that
  # they agree. `lib/util` is Virgil's library (`Vector`, `Strings`, ...).
  run = ''
    lib=${virgil}/share/virgil/lib/util
    v3c-wasm-wasi1 -program-name=main -output=. main.v3 $lib/*.v3 >&2
    mkdir gc
    v3c-wasm-gc-wasi1 -program-name=main -output=gc main.v3 $lib/*.v3 >&2
    wasmtime run main.wasm > linear.txt
    wasmtime run -W gc,function-references gc/main.wasm > gc.txt
    cmp linear.txt gc.txt >&2
    cat gc.txt
  '';
}
