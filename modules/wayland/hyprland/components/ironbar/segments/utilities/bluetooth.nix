{ pkgs }:
pkgs.writeShellScriptBin "leviathan-bluetooth-status" ''
  if ! command -v bluetoothctl >/dev/null 2>&1; then
    ${pkgs.coreutils}/bin/printf '󰂲\n'
    exit 0
  fi

  if bluetoothctl show 2>/dev/null | ${pkgs.gnugrep}/bin/grep -q "Powered: yes"; then
    ${pkgs.coreutils}/bin/printf '󰂯\n'
  else
    ${pkgs.coreutils}/bin/printf '󰂲\n'
  fi
''
