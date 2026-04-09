{ pkgs }:
pkgs.stdenv.mkDerivation {
  pname = "leviathan-volume-event";
  version = "0.1.0";

  dontUnpack = true;
  nativeBuildInputs = [ pkgs.pkg-config ];
  buildInputs = [ pkgs.pipewire ];

  buildPhase = ''
    $CC -O2 -o leviathan-volume-event ${./volume-event.c} $(pkg-config --cflags --libs libpipewire-0.3)
  '';

  installPhase = ''
    mkdir -p "$out/bin"
    install -m755 leviathan-volume-event "$out/bin/leviathan-volume-event"
  '';
}