{ pkgs }:
let
  launcher = import ./launcher.nix { inherit pkgs; };
  calendar = import ./calendar.nix { inherit pkgs; };
  wallpaper = import ./wallpaper.nix { inherit pkgs; };
  screenshot = import ./screenshot.nix { inherit pkgs; };
  menus = import ./menus { inherit pkgs; };
  utilities = import ./utilities { inherit pkgs; };
  quick = import ./quick { inherit pkgs; };
in
{
  # Export all individual scripts
  inherit launcher calendar wallpaper screenshot;
  inherit menus utilities quick;

  # Aggregate all scripts for home.packages
  allScripts = [
    launcher
    calendar
    wallpaper
    screenshot
  ] ++ menus.scripts
    ++ utilities.scripts
    ++ quick.scripts;
}
