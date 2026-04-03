{ config, lib, pkgs, ... }:

let
  # Import component environment
  hyprlandComponents = import ./components {
    inherit config lib pkgs;
  };

  # Import packages configuration
  packages = import ./packages.nix {
    inherit pkgs;
    scripts = hyprlandComponents.segments;
  };

in
{
  # Font configuration
  fonts.fontconfig.enable = true;

  # Load modularized configuration files
  imports = [ ./config-files.nix ];

  # Global cursor configuration
  home.pointerCursor = {
    name = "Adwaita";
    package = pkgs.adwaita-icon-theme;
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };

  # Environment variables for cursor
  home.sessionVariables = {
    XCURSOR_THEME = "Adwaita";
    XCURSOR_SIZE = "24";
  };

  # Install all packages
  home.packages = packages.all ++ [
    hyprlandComponents.hyprlandPackage
    hyprlandComponents.nixGLCompat
    hyprlandComponents.nixGLIntelCompat
    hyprlandComponents.primeRunCompat
    hyprlandComponents.networkStatus
    hyprlandComponents.restartBarScript
  ];

  # Hyprland window manager configuration
  wayland.windowManager.hyprland = {
    enable = true;
    package = hyprlandComponents.hyprlandPackage;
    extraConfig = builtins.readFile ./hyprland.conf;
    systemd.enable = false;
  };
}
