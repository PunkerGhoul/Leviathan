{ config, lib, pkgs, ... }:

let
  mkHyprlandPackage = { enableXWayland ? true }:
    let
      hyprlandBase = pkgs.hyprland.override { inherit enableXWayland; };
      hyprlandWrapped = config.lib.nixGL.wrap hyprlandBase;
    in
    pkgs.runCommand "hyprland-nixgl-session" {
      nativeBuildInputs = [ pkgs.makeWrapper ];
    } ''
      mkdir -p "$out"
      cp -r ${hyprlandWrapped}/. "$out"/
      chmod -R u+w "$out"
      mv "$out/bin/Hyprland" "$out/bin/Hyprland-real"
      cat > "$out/bin/Hyprland" <<EOF
#!/bin/sh
state_dir="''${XDG_STATE_HOME:-$HOME/.local/state}"
log_file="$state_dir/hyprland.log"

mkdir -p "$state_dir"
echo "=== $(date -Is) starting Hyprland ===" >> "$log_file"

exec "$out/bin/Hyprland-real" >> "$log_file" 2>&1
EOF
      chmod +x "$out/bin/Hyprland"
      rm -f "$out/bin/start-hyprland"
      cat > "$out/bin/start-hyprland" <<EOF
#!/bin/sh
exec "$out/bin/Hyprland"
EOF
      chmod +x "$out/bin/start-hyprland"
    '';

  hyprlandPackage = lib.makeOverridable mkHyprlandPackage { };
in
{
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
    pkgs.uwsm
  ];

  # Hyprland para Home Manager
  wayland.windowManager.hyprland = {
    enable = true;
    package = hyprlandPackage;
    #portalPackage = pkgs.xdg-desktop-portal-hyprland;

    settings = {
      monitor = ",1920x1080@60,auto,auto";
      "$terminal" = "kitty";
      "$filemanager" = "dolphin";
      "$menu" = "rofi -show drun";

      general = {
        gaps_in = 8;
        gaps_out = 15;
        border_size = 3;
        layout = "dwindle";
        resize_on_border = true;
        allow_tearing = true;
        "col.active_border" = "rgba(e879f9ff) rgba(c084fcff) rgba(a855f7ff) rgba(7c3aedff) 45deg";
        "col.inactive_border" = "rgba(6b21a866) rgba(4c1d95aa) 45deg";
      };

      decoration = {
        rounding = 12;
        active_opacity = 0.98;
        inactive_opacity = 0.85;
        shadow = {
          enabled = true;
          range = 12;
          render_power = 4;
          color = "rgba(e879f9aa)";
          color_inactive = "rgba(6b21a855)";
        };
        blur = {
          enabled = true;
          size = 8;
          passes = 2;
          vibrancy = 0.3;
          vibrancy_darkness = 0.8;
          new_optimizations = true;
          xray = false;
        };
        dim_inactive = true;
        dim_strength = 0.1;
        dim_special = 0.4;
        dim_around = 0.6;
      };

      dwindle = { pseudotile = true; preserve_split = true; force_split = 0; special_scale_factor = 0.9; };
      master = { new_status = "master"; new_on_top = false; mfact = 0.55; orientation = "left"; inherit_fullscreen = true; };

      misc = {
        force_default_wallpaper = 0;
        disable_hyprland_logo = true;
        vfr = true;
        vrr = 1;
        mouse_move_enables_dpms = true;
        key_press_enables_dpms = true;
        always_follow_on_dnd = true;
        layers_hog_keyboard_focus = true;
        animate_manual_resizes = true;
        animate_mouse_windowdragging = true;
        disable_autoreload = false;
        enable_swallow = true;
        swallow_regex = "^(kitty)$";
        focus_on_activate = false;
      };

      debug = {
        disable_logs = false;
      };

      input = { kb_layout = "latam"; kb_variant = ""; kb_model = ""; kb_options = ""; kb_rules = ""; follow_mouse = 1; sensitivity = 0; touchpad = { natural_scroll = false; }; };
      device = { name = "epic-mouse-v1"; sensitivity = -0.5; };
      cursor = { no_hardware_cursors = false; no_break_fs_vrr = false; min_refresh_rate = 24; hotspot_padding = 1; inactive_timeout = 0; no_warps = false; persistent_warps = false; warp_on_change_workspace = false; };

      group = {
        "col.border_active" = "rgba(e879f9ff) rgba(c084fcff) 45deg";
        "col.border_inactive" = "rgba(6b21a866)";
        "col.border_locked_active" = "rgba(c084fcff) rgba(a855f7ff) 45deg";
        "col.border_locked_inactive" = "rgba(4c1d95aa)";
        groupbar = {
          enabled = true;
          font_family = "Hack Nerd Font Mono";
          font_size = 10;
          gradients = true;
          height = 14;
          priority = 3;
          render_titles = true;
          scrolling = true;
          text_color = "rgba(e879f9ff)";
          "col.active" = "rgba(e879f9aa)";
          "col.inactive" = "rgba(6b21a866)";
          "col.locked_active" = "rgba(c084fcaa)";
          "col.locked_inactive" = "rgba(4c1d9566)";
        };
      };

      "$mainMod" = "SUPER";
    };

    extraConfig = builtins.readFile ./hyprland.conf;
    systemd.enable = false;
  };
}
