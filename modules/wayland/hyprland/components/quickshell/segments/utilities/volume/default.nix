{ pkgs }:
pkgs.stdenv.mkDerivation {
  pname = "leviathan-volume-status";
  version = "0.1.0";

  dontUnpack = true;
  nativeBuildInputs = [ pkgs.pkg-config ];
  buildInputs = [ pkgs.pipewire ];

  buildPhase = ''
    $CC -O2 -o leviathan-volume-status ${./volume-status.c} $(pkg-config --cflags --libs libpipewire-0.3) -lm
  '';

  installPhase = ''
    mkdir -p "$out/bin"
    install -m755 leviathan-volume-status "$out/bin/leviathan-volume-status"
  '';
}