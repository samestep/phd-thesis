{ pkgs, inputs, ... }:
let
  inherit (pkgs) lib stdenv;
  sdk = pkgs.apple-sdk.sdkroot;
  # Roc's alpha4 release, the last of the old compiler, which has module
  # params; nixpkgs builds it only for x86_64 Linux, so use the official
  # release binaries.
  roc = stdenv.mkDerivation {
    pname = "roc";
    version = "alpha4-rolling";
    src =
      {
        x86_64-linux = inputs.roc-linux-x86_64;
        aarch64-linux = inputs.roc-linux-arm64;
        aarch64-darwin = inputs.roc-macos-arm64;
      }
      .${stdenv.hostPlatform.system};
    nativeBuildInputs = [
      pkgs.makeBinaryWrapper
    ]
    ++ lib.optional stdenv.hostPlatform.isLinux pkgs.autoPatchelfHook;
    buildInputs = lib.optionals stdenv.hostPlatform.isLinux [
      stdenv.cc.cc.lib
      pkgs.zlib
      pkgs.zstd
      pkgs.ncurses
    ];
    installPhase =
      if stdenv.hostPlatform.isLinux then
        # As nixpkgs' own `roc` does: tell its linker where glibc and libgcc
        # are.
        ''
          install -Dm755 roc $out/bin/roc
          wrapProgram $out/bin/roc \
            --set NIX_GLIBC_PATH ${pkgs.glibc.out}/lib \
            --set NIX_LIBGCC_S_PATH ${stdenv.cc.cc.lib}/lib \
            --prefix PATH : ${lib.makeBinPath [ stdenv.cc ]}
        ''
      else
        # The macOS binary links zstd from Homebrew. Its linker asks
        # `sw_vers` for the deployment target and looks for the SDK under
        # /Library, so point it at Nixpkgs' instead, plus libresolv, which
        # that SDK lacks: otherwise `-lresolv` finds the SDK under /Library,
        # which may be newer than the linker understands. (It still signs
        # the executable with /usr/bin/codesign.)
        ''
          install -Dm755 roc $out/bin/roc
          install_name_tool -change /opt/homebrew/opt/zstd/lib/libzstd.1.dylib \
            ${lib.getLib pkgs.zstd}/lib/libzstd.1.dylib $out/bin/roc
          mkdir -p $out/libexec
          printf '#!/bin/sh\necho ${stdenv.hostPlatform.darwinMinVersion}\n' > $out/libexec/sw_vers
          chmod +x $out/libexec/sw_vers
          wrapProgram $out/bin/roc \
            --set ROC_LINK_FLAGS "-L${sdk}/usr/lib -L${lib.getLib pkgs.darwin.libresolv}/lib -F${sdk}/System/Library/Frameworks" \
            --prefix PATH : $out/libexec:${lib.makeBinPath [ stdenv.cc ]}
        '';
  };
  # The build has no network, so put the basic-cli release where Roc caches
  # the URL in the app header.
  basicCli = "github.com/roc-lang/basic-cli/releases/download/0.20.0/X73hGh05nNTkDHU06FHC0YfFaQB1pimX7gncRcao5mU";
in
{
  packages = [
    roc
    pkgs.brotli
  ];
  run = ''
    mkdir -p $HOME/.cache/roc/packages/${basicCli}
    brotli -dc ${inputs.roc-basic-cli} | tar -x -C $HOME/.cache/roc/packages/${basicCli}
    roc build main.roc >&2
    ./main
  '';
}
