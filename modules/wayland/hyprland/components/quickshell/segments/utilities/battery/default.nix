{ pkgs, lib ? pkgs.lib }:
let
  qml = import ./qml.nix;
  programs = import ./programs { inherit pkgs lib; };
in
{
  scripts = [
    programs.batteryTools
  ];

  inherit qml;
  inherit (programs) batteryAgent batteryTools;
}
