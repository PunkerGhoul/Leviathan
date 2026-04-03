{ config, lib, pkgs }:

let
  nixgl = import ./nixgl {
    inherit config lib pkgs;
  };

  quickshell = import ./quickshell {
    inherit lib pkgs;
  };
in
nixgl // quickshell
