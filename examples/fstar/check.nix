{ pkgs, ... }:
let
  # On ARM64, use the upstream stage-2 build because the examples only need
  # F* and its standard library. Help the solver by supplying the unsigned
  # bit-vector lemma explicitly in the signed proof.
  fstar =
    if pkgs.stdenv.hostPlatform.isAarch64 then
      pkgs.fstar.overrideAttrs (old: {
        env = old.env // {
          FSTAR_DEFAULT_GOAL = "stage2";
        };
        installPhase =
          pkgs.lib.replaceStrings
            [ "make install" ]
            [
              ''
                make -C stage2 install FSTAR_DUNE_RELEASE=1 FSTAR_LINK_LIBDIRS=0
                make -C karamel install LOWSTAR=false
              ''
            ]
            old.installPhase;
        postPatch = (old.postPatch or "") + ''
          substituteInPlace ulib/FStar.Int.fst \
            --replace-fail 'let ones_to_vec_lemma #n i = ()' \
                           'let ones_to_vec_lemma #n i = UInt.ones_to_vec_lemma #n i'
        '';
      })
    else
      pkgs.fstar;
in
{
  packages = [ fstar ];
  run = "fstar.exe Main.fst | sed -n 's/^TAC>> \\(-\\?[0-9]*\\) .*/\\1/p'";
}
