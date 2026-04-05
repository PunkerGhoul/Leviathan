{ pkgs, lib }:

pkgs.rustPlatform.buildRustPackage rec {
  pname = "network-status";
  version = "0.1.0";
  
  src = lib.cleanSource ./.;
  
  cargoLock = {
    lockFile = ./Cargo.lock;
  };

  meta = with lib; {
    description = "Fast network status utility for quickshell";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}

