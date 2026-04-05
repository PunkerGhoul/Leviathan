{ pkgs }:
let
  launcher = import ./apps/launcher.nix { inherit pkgs; };
  calendar = import ./apps/calendar.nix { inherit pkgs; };
  wallpaper = import ./apps/wallpaper.nix { inherit pkgs; };
  screenshot = import ./apps/screenshot.nix { inherit pkgs; };
  menus = import ./ui/menus { inherit pkgs; };
  utilities = import ./utilities { inherit pkgs; };
  # Keep quick imported/exported for compatibility, but do not package its scripts by default.
  quick = import ./ui/quick { inherit pkgs; };
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
    ++ utilities.scripts;
}
