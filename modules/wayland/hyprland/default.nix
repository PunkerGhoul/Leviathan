{ config, pkgs, ... }:

{
  # Configure cursor theme globally - using reliable Adwaita
  home.pointerCursor = {
    name = "Adwaita";
    package = pkgs.adwaita-icon-theme;
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };

  # Ensure cursor is set via environment variables
  home.sessionVariables = {
    XCURSOR_THEME = "Adwaita";
    XCURSOR_SIZE = "24";
  };

  wayland.windowManager.hyprland = {
    enable = true;
    package = (config.lib.nixGL.wrap pkgs.hyprland);
    portalPackage = (config.lib.nixGL.wrap pkgs.xdg-desktop-portal-hyprland);
    settings = {
      # Refer to the wiki for more information
      # https://wiki.hypr.land/Configuration/

      ## Monitors
      monitor = ",1920x1080@60,auto,auto";

      ## My Programs
      ### https://wiki.hypr.land/Configuring/Keywords/
      "$terminal" = "kitty";
      "$filemanager" = "dolphin";
      "$menu" = "rofi -show drun";

      ## Look and Feel
      ### https://wiki.hypr.land/Configuring/Variables/
      #### https://wiki.hypr.land/Configuring/Variables/#general
      general = {
        gaps_in = 8;
        gaps_out = 15;

        border_size = 3;

        #### https://wiki.hypr.land/Configuring/Variables/#variables-types
        # Cyberpunk purple gradient borders to match eww theme
        "col.active_border" = "rgba(e879f9ff) rgba(c084fcff) rgba(a855f7ff) rgba(7c3aedff) 45deg";
        "col.inactive_border" = "rgba(6b21a866) rgba(4c1d95aa) 45deg";

        #### Set to true to enable resizing windows by clicking and dragging on borders and gaps
        resize_on_border = true;

        #### https://wiki.hypr.land/Configuring/Tearing/
        allow_tearing = true;

        layout = "dwindle";
      };

      #### https://wiki.hypr.land/Configuring/Variables/#decoration
      decoration = {
        rounding = 12;

        #### Change transparency of focused and unfocused windows for cyberpunk aesthetic
        active_opacity = 0.98;
        inactive_opacity = 0.85;

        shadow = {
          enabled = true;
          range = 12;
          render_power = 4;
          # Cyberpunk purple shadow with glow effect
          color = "rgba(e879f9aa)";
          color_inactive = "rgba(6b21a855)";
        };

        #### https://wiki.hypr.land/Configuring/Variables/#blur
        blur = {
          enabled = true;
          size = 8;
          passes = 2;
          vibrancy = 0.3;
          vibrancy_darkness = 0.8;
          new_optimizations = true;
          xray = false;
        };

        # Dim inactive windows for cyberpunk depth
        dim_inactive = true;
        dim_strength = 0.1;
        dim_special = 0.4;
        dim_around = 0.6;
      };

      ## Dwindle Layout 
      ### https://wiki.hypr.land/Configuring/Dwindle-Layout/
      dwindle = {
        #### Master switch for pseudotiling. Enabling is bound to mainMod + P in the keybinds section below
        pseudotile = true;
        #### You probably want this
        preserve_split = true;
        #### Valid dwindle options
        force_split = 0;
        special_scale_factor = 0.9;
      };

      ## Master Layout
      ### https://wiki.hypr.land/Configuring/Master-Layout/
      master = {
        new_status = "master";
        new_on_top = false;
        mfact = 0.55;
        orientation = "left";
        inherit_fullscreen = true;
      };

      ## Misc
      ### https://wiki.hypr.land/Configuring/Variables/#misc
      misc = {
        force_default_wallpaper = 0; # Disable anime mascot for cyberpunk aesthetic
        disable_hyprland_logo = true;  # Clean cyberpunk look
        vfr = true; # Variable frame rate for performance
        vrr = 1; # Variable refresh rate
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

      ## Input
      ### https://wiki.hypr.land/Configuring/Variables/#input
      input = {
        kb_layout = "latam";
        kb_variant = "";
        kb_model = "";
        kb_options = "";
        kb_rules = "";

        follow_mouse = 1;

        sensitivity = 0;  # -1.0 - 1.0, 0 means no modification.

        touchpad = {
          natural_scroll = false;
        };
      };

      ### Example per-device config
      #### https://wiki.hypr.land/Configuring/Keywords/#per-device-input-configs
      device = {
        name = "epic-mouse-v1";
        sensitivity = -0.5;
      };

      ### Cursor
      cursor = {
        no_hardware_cursors = false;
        no_break_fs_vrr = false;
        min_refresh_rate = 24;
        hotspot_padding = 1;
        inactive_timeout = 0;
        no_warps = false;
        persistent_warps = false;
        warp_on_change_workspace = false;
      };

      ## Group Configuration
      ### https://wiki.hypr.land/Configuring/Variables/#group
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

      ## Keybindings
      ### https://wiki.hypr.land/Configuring/Keywords/
      "$mainMod" = "SUPER"; # Sets "Windows" key as main modifier
    };
    extraConfig = builtins.readFile ./hyprland.conf;
    systemd.enableXdgAutostart = true;
  };
}
