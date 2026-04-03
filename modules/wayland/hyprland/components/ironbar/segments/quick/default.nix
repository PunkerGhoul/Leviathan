{ pkgs }:
let
  buttons = import ./buttons.nix { inherit pkgs; };
in
{
  scripts = with buttons; [
    arch
    terminal
    files
    browser
    wallpaper
    screenshot
    settings
  ];

  inherit buttons;
}
