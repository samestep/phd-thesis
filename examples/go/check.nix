{ pkgs, ... }:
{
  packages = [ pkgs.go ];
  run = ''
    export GOCACHE=$HOME/go-cache GOPATH=$HOME/go GO111MODULE=off
    go run expr.go
  '';
}
