
USING: kernel system alien.syntax combinators vocabs.loader ;

IN: unix.types

TYPEDEF: void* caddr_t

os
  {
    { "linux"   [ "unix.types.linux"   require ] }
    { "macosx"  [ "unix.types.macosx"  require ] }
    { "freebsd" [ "unix.types.freebsd" require ] }
    { "openbsd" [ "unix.types.openbsd" require ] }
    { "netbsd"  [ "unix.types.netbsd"  require ] }
    [ drop ]
  }
case
