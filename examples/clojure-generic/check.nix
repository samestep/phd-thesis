{ pkgs, ... }:
{
  packages = [ pkgs.jdk ];
  # The `clojure` CLI resolves dependencies over the network; the tools jar
  # it ships already bundles Clojure itself.
  run = "java -cp ${pkgs.clojure}/libexec/clojure-tools-${pkgs.clojure.version}.jar clojure.main expr.clj";
}
