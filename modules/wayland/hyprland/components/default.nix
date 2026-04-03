{ config, lib, pkgs }:

let
  nixgl = import ./nixgl {
    inherit config lib pkgs;
  };

  ironbar = import ./ironbar {
    inherit lib pkgs;
  };
in
nixgl // ironbar
