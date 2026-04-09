{ pkgs }:
pkgs.writeShellScriptBin "leviathan-vpn-status" ''
  iface="$(${pkgs.iproute2}/bin/ip -o link show up 2>/dev/null \
    | ${pkgs.gawk}/bin/awk -F': ' '{print $2}' \
    | ${pkgs.gnugrep}/bin/grep -E '^(tun|wg|ppp|tap|vpn)[0-9A-Za-z._-]*$' \
    | ${pkgs.coreutils}/bin/head -n 1)"

  if [ -z "$iface" ]; then
    exit 0
  fi

  ip4="$(${pkgs.iproute2}/bin/ip -o -4 addr show dev "$iface" scope global 2>/dev/null \
    | ${pkgs.gawk}/bin/awk '{print $4}' \
    | ${pkgs.coreutils}/bin/cut -d/ -f1 \
    | ${pkgs.coreutils}/bin/head -n 1)"

  if [ -n "$ip4" ]; then
    ${pkgs.coreutils}/bin/printf '󰖂 %s\n' "$ip4"
  fi
''