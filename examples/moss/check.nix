{ moss, ... }:
{
  packages = [ moss ];
  run = ''
    cp -r ${moss}/share/moss/lib lib
    chmod -R u+w lib
    moss expr.moss
  '';
}
