{ pkgs }:
pkgs.writeShellScriptBin "leviathan-settings" ''
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
''
