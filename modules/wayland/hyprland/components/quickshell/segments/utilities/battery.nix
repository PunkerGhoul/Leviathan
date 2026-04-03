{ pkgs }:
pkgs.writeShellScriptBin "leviathan-battery" ''
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
''
