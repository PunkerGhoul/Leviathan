{ config, lib, pkgs }:

let
  nixgl = import ./nixgl {
    inherit config lib pkgs;
  };

  quickshell = import ./quickshell {
    inherit config lib pkgs;
  };
in
nixgl // quickshell
