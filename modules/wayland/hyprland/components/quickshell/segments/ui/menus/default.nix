{ pkgs }:
let
  powerMenu = import ./power-menu.nix { inherit pkgs; };
  settingsMenu = import ./settings-menu.nix { inherit pkgs; };
in
{
  scripts = [
    powerMenu
    settingsMenu
  ];

  inherit powerMenu settingsMenu;
}
