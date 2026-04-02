{ config, lib, pkgs, ... }:

let
  hyprlandRuntime = import ./runtime {
    inherit config lib pkgs;
  };
in
{
  xdg.configFile = {
    "hypr/.current-theme".source = ./config/.current-theme;
    "hypr/autostart.conf".source = ./config/autostart.conf;
    "hypr/hypridle.conf".source = ./config/hypridle.conf;
    "hypr/hyprlock.conf".source = ./config/hyprlock.conf;
    "hypr/hyprshot.conf".source = ./config/hyprshot.conf;
    "hypr/input.conf".source = ./config/input.conf;
    "hypr/keybinds.conf".source = ./config/keybinds.conf;
    "hypr/look-and-feel.conf".source = ./config/look-and-feel.conf;
    "hypr/monitors.conf".source = ./config/monitors.conf;
    "hypr/programs.conf".source = ./config/programs.conf;
    "hypr/rules.conf".source = ./config/rules.conf;
    "hypr/theme-switcher.conf".source = ./config/theme-switcher.conf;
    "hypr/variables.conf".source = ./config/variables.conf;
    "hypr/themes" = {
      source = ./config/themes;
      recursive = true;
    };
  };

  # Cursor global
  home.pointerCursor = {
    name = "Adwaita";
    package = pkgs.adwaita-icon-theme;
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };

  home.sessionVariables = {
    XCURSOR_THEME = "Adwaita";
    XCURSOR_SIZE = "24";
  };

  home.packages = [
    hyprlandRuntime.hyprlandPackage
    hyprlandRuntime.nixGLCompat
    hyprlandRuntime.nixGLIntelCompat
    hyprlandRuntime.primeRunCompat
  ];

  # Hyprland para Home Manager
  wayland.windowManager.hyprland = {
    enable = true;
    package = hyprlandRuntime.hyprlandPackage;
    #portalPackage = pkgs.xdg-desktop-portal-hyprland;
    extraConfig = builtins.readFile ./hyprland.conf;
    systemd.enable = false;
  };
}
