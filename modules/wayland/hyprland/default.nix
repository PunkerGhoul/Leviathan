{ config, lib, pkgs, ... }:

let
  hyprlandRuntime = import ./runtime {
    inherit config lib pkgs;
  };

  launcherScript = pkgs.writeShellScriptBin "leviathan-launcher" ''
    exec ${pkgs.wofi}/bin/wofi --show drun --allow-images
  '';

  archButtonScript = pkgs.writeShellScriptBin "leviathan-arch-button" ''
    ${pkgs.coreutils}/bin/printf '󰣇\n'
  '';

  quickTerminalButtonScript = pkgs.writeShellScriptBin "leviathan-quick-terminal" ''
    ${pkgs.coreutils}/bin/printf '\n'
  '';

  quickFilesButtonScript = pkgs.writeShellScriptBin "leviathan-quick-files" ''
    ${pkgs.coreutils}/bin/printf '󰉋\n'
  '';

  quickBrowserButtonScript = pkgs.writeShellScriptBin "leviathan-quick-browser" ''
    ${pkgs.coreutils}/bin/printf '󰖟\n'
  '';

  quickWallpaperButtonScript = pkgs.writeShellScriptBin "leviathan-quick-wallpaper" ''
    ${pkgs.coreutils}/bin/printf '󰸉\n'
  '';

  quickScreenshotButtonScript = pkgs.writeShellScriptBin "leviathan-quick-screenshot" ''
    ${pkgs.coreutils}/bin/printf '󰄀\n'
  '';

  quickSettingsButtonScript = pkgs.writeShellScriptBin "leviathan-quick-settings" ''
    ${pkgs.coreutils}/bin/printf '󰒓\n'
  '';

  calendarScript = pkgs.writeShellScriptBin "leviathan-calendar" ''
    exec ${pkgs.kitty}/bin/kitty --class kitty-calendar ${pkgs.bash}/bin/bash -lc \
      '${pkgs.util-linux}/bin/cal -m; echo; ${pkgs.coreutils}/bin/date "+%A, %d %B %Y"; echo; read -n 1 -s -r -p "Press any key to close..."'
  '';

  powerMenuScript = pkgs.writeShellScriptBin "leviathan-power-menu" ''
    choice="$(${pkgs.coreutils}/bin/printf '%s\n' \
      "lock" \
      "logout" \
      "suspend" \
      "reboot" \
      "shutdown" | ${pkgs.wofi}/bin/wofi --dmenu --prompt "power")"

    case "$choice" in
      lock)
        exec ${pkgs.hyprlock}/bin/hyprlock
        ;;
      logout)
        exec hyprctl dispatch exit
        ;;
      suspend)
        exec ${pkgs.systemd}/bin/systemctl suspend
        ;;
      reboot)
        exec ${pkgs.systemd}/bin/systemctl reboot
        ;;
      shutdown)
        exec ${pkgs.systemd}/bin/systemctl poweroff
        ;;
    esac
  '';

  settingsScript = pkgs.writeShellScriptBin "leviathan-settings" ''
    choice="$(${pkgs.coreutils}/bin/printf '%s\n' \
      "audio" \
      "network" \
      "bluetooth" \
      "power" | ${pkgs.wofi}/bin/wofi --dmenu --prompt "settings")"

    case "$choice" in
      audio)
        exec ${pkgs.pavucontrol}/bin/pavucontrol
        ;;
      network)
        exec ${pkgs.kitty}/bin/kitty --class kitty-nmtui ${pkgs.networkmanager}/bin/nmtui
        ;;
      bluetooth)
        exec ${pkgs.blueman}/bin/blueman-manager
        ;;
      power)
        exec ${pkgs.xfce4-power-manager}/bin/xfce4-power-manager-settings
        ;;
    esac
  '';

  wallpaperPickerScript = pkgs.writeShellScriptBin "leviathan-wallpaper-picker" ''
    exec ${pkgs.waypaper}/bin/waypaper
  '';

  screenshotScript = pkgs.writeShellScriptBin "leviathan-screenshot" ''
    exec ${pkgs.hyprshot}/bin/hyprshot -m region --clipboard-only
  '';

  restartBarScript = pkgs.writeShellScriptBin "leviathan-restart-bar" ''
    ${pkgs.procps}/bin/pkill -x ironbar >/dev/null 2>&1 || true
    exec ${pkgs.ironbar}/bin/ironbar
  '';

  restartBarFile = pkgs.writeShellScript "restart-ironbar.sh" ''
    ${pkgs.procps}/bin/pkill -x ironbar >/dev/null 2>&1 || true
    exec ${pkgs.ironbar}/bin/ironbar
  '';

  updatesScript = pkgs.writeShellScriptBin "leviathan-updates" ''
    official=0
    aur=0

    if command -v checkupdates >/dev/null 2>&1; then
      official="$(${pkgs.bash}/bin/bash -lc 'checkupdates 2>/dev/null | wc -l' 2>/dev/null || ${pkgs.coreutils}/bin/printf '0')"
    fi

    if command -v paru >/dev/null 2>&1; then
      aur="$(${pkgs.bash}/bin/bash -lc 'paru -Qua 2>/dev/null | wc -l' 2>/dev/null || ${pkgs.coreutils}/bin/printf '0')"
    elif command -v yay >/dev/null 2>&1; then
      aur="$(${pkgs.bash}/bin/bash -lc 'yay -Qua 2>/dev/null | wc -l' 2>/dev/null || ${pkgs.coreutils}/bin/printf '0')"
    fi

    count=$((official + aur))
    ${pkgs.coreutils}/bin/printf '󰚰 %s\n' "$count"
  '';

  runUpdatesScript = pkgs.writeShellScriptBin "leviathan-run-updates" ''
    update_cmd='if command -v paru >/dev/null 2>&1; then paru -Syu; elif command -v yay >/dev/null 2>&1; then yay -Syu; else sudo pacman -Syu; fi; echo; read -n 1 -s -r -p "Press any key to close..."'
    exec ${pkgs.kitty}/bin/kitty --class kitty-updates ${pkgs.bash}/bin/bash -lc "$update_cmd"
  '';

  batteryScript = pkgs.writeShellScriptBin "leviathan-battery" ''
    battery_path="$(${pkgs.findutils}/bin/find /sys/class/power_supply -maxdepth 1 -type l -name 'BAT*' | ${pkgs.coreutils}/bin/head -n 1)"

    if [ -z "$battery_path" ]; then
      ${pkgs.coreutils}/bin/printf '\n'
      exit 0
    fi

    capacity="$(${pkgs.coreutils}/bin/cat "$battery_path/capacity" 2>/dev/null || ${pkgs.coreutils}/bin/printf '0')"
    status="$(${pkgs.coreutils}/bin/cat "$battery_path/status" 2>/dev/null || ${pkgs.coreutils}/bin/printf 'Unknown')"

    if [ "$status" = "Charging" ]; then
      icon='󰂄'
    elif [ "$capacity" -ge 95 ]; then
      icon='󰁹'
    elif [ "$capacity" -ge 90 ]; then
      icon='󰂂'
    elif [ "$capacity" -ge 80 ]; then
      icon='󰂁'
    elif [ "$capacity" -ge 70 ]; then
      icon='󰂀'
    elif [ "$capacity" -ge 60 ]; then
      icon='󰁿'
    elif [ "$capacity" -ge 50 ]; then
      icon='󰁾'
    elif [ "$capacity" -ge 40 ]; then
      icon='󰁽'
    elif [ "$capacity" -ge 30 ]; then
      icon='󰁼'
    elif [ "$capacity" -ge 20 ]; then
      icon='󰁻'
    elif [ "$capacity" -ge 10 ]; then
      icon='󰁺'
    else
      icon='󰂃'
    fi

    ${pkgs.coreutils}/bin/printf '%s %s%%\n' "$icon" "$capacity"
  '';

  bluetoothScript = pkgs.writeShellScriptBin "leviathan-bluetooth-status" ''
    if ! command -v bluetoothctl >/dev/null 2>&1; then
      ${pkgs.coreutils}/bin/printf '󰂲\n'
      exit 0
    fi

    if bluetoothctl show 2>/dev/null | ${pkgs.gnugrep}/bin/grep -q "Powered: yes"; then
      ${pkgs.coreutils}/bin/printf '󰂯\n'
    else
      ${pkgs.coreutils}/bin/printf '󰂲\n'
    fi
  '';

  powerIconScript = pkgs.writeShellScriptBin "leviathan-power-icon" ''
    ${pkgs.coreutils}/bin/printf '󰐥\n'
  '';

  wifiIconScript = pkgs.writeShellScriptBin "leviathan-wifi-icon" ''
    CONNECTED=$(${pkgs.networkmanager}/bin/nmcli -t -f type,state,names,device dev 2>/dev/null | ${pkgs.gnugrep}/bin/grep "^wifi:connected" | ${pkgs.gawk}/bin/awk -F: '{print $3}')

    if [ -z "$CONNECTED" ]; then
      ${pkgs.coreutils}/bin/printf '󰤨'
      exit 0
    fi

    SIGNAL=$(${pkgs.networkmanager}/bin/nmcli -t -f type,signal,device dev 2>/dev/null | ${pkgs.gnugrep}/bin/grep "^wifi" | ${pkgs.gawk}/bin/awk -F: '{print $2}' | ${pkgs.coreutils}/bin/head -n 1)

    if [ -z "$SIGNAL" ]; then
      ${pkgs.coreutils}/bin/printf '󰤨'
      exit 0
    fi

    if [ "$SIGNAL" -ge 75 ]; then
      ${pkgs.coreutils}/bin/printf '󰤟'
    elif [ "$SIGNAL" -ge 50 ]; then
      ${pkgs.coreutils}/bin/printf '󰤢'
    elif [ "$SIGNAL" -ge 25 ]; then
      ${pkgs.coreutils}/bin/printf '󰤥'
    else
      ${pkgs.coreutils}/bin/printf '󰤨'
    fi
  '';

  wifiNetworksScript = pkgs.writeShellScriptBin "leviathan-wifi-networks" ''
    MODE="''${1:-display}"

    CONNECTED_SSID=$(${pkgs.networkmanager}/bin/nmcli -t -f active,ssid dev wifi 2>/dev/null | ${pkgs.gnugrep}/bin/grep '^yes:' | ${pkgs.coreutils}/bin/cut -d: -f2)

    case "$MODE" in
      connected)
        if [ -n "$CONNECTED_SSID" ]; then
          SIGNAL=$(${pkgs.networkmanager}/bin/nmcli -t -f type,signal dev | ${pkgs.gnugrep}/bin/grep "^wifi" | ${pkgs.gawk}/bin/awk -F: '{print $2}')
          SPEED=$(${pkgs.networkmanager}/bin/nmcli -t -f type,speed dev 2>/dev/null | ${pkgs.gnugrep}/bin/grep "^wifi" | ${pkgs.gawk}/bin/awk -F: '{print $2}')
          echo "$CONNECTED_SSID | Signal: $SIGNAL% | Speed: $SPEED"
        else
          echo "Not connected"
        fi
        ;;
      known)
        ${pkgs.networkmanager}/bin/nmcli -t -f name connection show 2>/dev/null | ${pkgs.gnugrep}/bin/grep -v "^$" | ${pkgs.coreutils}/bin/head -10
        ;;
      available)
        ${pkgs.networkmanager}/bin/nmcli device wifi list --rescan yes 2>/dev/null | ${pkgs.coreutils}/bin/tail -n +2 | ${pkgs.gawk}/bin/awk '
        {
          if (NF > 0) {
            ssid = $1
            signal = $(NF-2)
            
            if (signal >= 75) bars = "󰤟"
            else if (signal >= 50) bars = "󰤢"
            else if (signal >= 25) bars = "󰤥"
            else bars = "󰤨"
            
            printf "%s %d%%  %s\n", bars, signal, ssid
          }
        }' | ${pkgs.coreutils}/bin/sort -t'%' -k1 -rn | ${pkgs.gawk}/bin/awk '!seen[$2]++' | ${pkgs.coreutils}/bin/head -10
        ;;
      *)
        echo "Usage: leviathan-wifi-networks [connected|known|available]"
        ;;
    esac
  '';
in
{
  fonts.fontconfig.enable = true;

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
    "hypr/scripts/restart-ironbar.sh".source = restartBarFile;
    "hypr/variables.conf".source = ./config/variables.conf;
    "hypr/themes" = {
      source = ./config/themes;
      recursive = true;
    };
    "ironbar/config.corn".source = ./config/ironbar/config.corn;
    "ironbar/style.css".source = ./config/ironbar/style.css;
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
    launcherScript
    archButtonScript
    quickTerminalButtonScript
    quickFilesButtonScript
    quickBrowserButtonScript
    quickWallpaperButtonScript
    quickScreenshotButtonScript
    quickSettingsButtonScript
    calendarScript
    powerMenuScript
    settingsScript
    wallpaperPickerScript
    screenshotScript
    restartBarScript
    updatesScript
    runUpdatesScript
    batteryScript
    bluetoothScript
    powerIconScript
    wifiIconScript
    wifiNetworksScript
    pkgs.bluez
    pkgs.blueman
    pkgs.hyprlock
    pkgs.hyprshot
    pkgs.ironbar
    pkgs.kitty
    pkgs.networkmanager
    pkgs.networkmanagerapplet
    pkgs.nerd-fonts.symbols-only
    pkgs.pavucontrol
    pkgs.rofi
    pkgs.waypaper
    pkgs.wofi
    pkgs.xfce4-power-manager
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
