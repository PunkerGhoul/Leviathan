{ pkgs }:
pkgs.writeShellScriptBin "leviathan-power-menu" ''
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
''
