{ pkgs, ... }:
{
  packages = [
    pkgs.scala_3
    pkgs.jdk
  ];
  # `scala` is the scala-cli launcher, which wants the network, so run the
  # compiled class on the JVM directly.
  run = ''
    mkdir out
    scalac -d out expr.scala >&2
    lib=$(dirname "$(readlink -f "$(command -v scalac)")")/../lib
    java -cp "out:$lib/scala.jar" run
  '';
}
