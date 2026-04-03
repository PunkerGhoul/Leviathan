{ pkgs }:
let
  networkSlotUiScript = pkgs.writeShellScriptBin "leviathan-network-slot-ui" ''
    group="''${1:-available}"
    ui_index="''${2:-0}"
    offset_dir="''${XDG_CACHE_HOME:-$HOME/.cache}/leviathan"

    case "$group" in
      known) offset_file="$offset_dir/network-known-offset" ;;
      available) offset_file="$offset_dir/network-available-offset" ;;
      *) ${pkgs.coreutils}/bin/printf -- "-\n"; exit 0 ;;
    esac

    offset=0
    if [ -f "$offset_file" ]; then
      offset="$(${pkgs.coreutils}/bin/cat "$offset_file" 2>/dev/null || ${pkgs.coreutils}/bin/printf '0')"
    fi

    abs_index=$((offset + ui_index))
    network-status slot "$group" "$abs_index"
  '';

  networkConnectUiScript = pkgs.writeShellScriptBin "leviathan-network-connect-ui" ''
    group="''${1:-available}"
    ui_index="''${2:-0}"
    offset_dir="''${XDG_CACHE_HOME:-$HOME/.cache}/leviathan"

    case "$group" in
      known) offset_file="$offset_dir/network-known-offset" ;;
      available) offset_file="$offset_dir/network-available-offset" ;;
      *) exit 0 ;;
    esac

    offset=0
    if [ -f "$offset_file" ]; then
      offset="$(${pkgs.coreutils}/bin/cat "$offset_file" 2>/dev/null || ${pkgs.coreutils}/bin/printf '0')"
    fi

    abs_index=$((offset + ui_index))
    ssid="$(network-status ssid "$group" "$abs_index")"

    if [ -z "$ssid" ]; then
      exit 0
    fi

    ${pkgs.networkmanager}/bin/nmcli dev wifi connect "$ssid" >/dev/null 2>&1 || true
  '';

  networkScrollScript = pkgs.writeShellScriptBin "leviathan-network-scroll" ''
    group="''${1:-available}"
    direction="''${2:-down}"
    visible="''${3:-6}"
    offset_dir="''${XDG_CACHE_HOME:-$HOME/.cache}/leviathan"

    ${pkgs.coreutils}/bin/mkdir -p "$offset_dir"

    case "$group" in
      known)
        offset_file="$offset_dir/network-known-offset"
        count="$(network-status known | ${pkgs.coreutils}/bin/wc -l)"
        ;;
      available)
        offset_file="$offset_dir/network-available-offset"
        count="$(network-status available | ${pkgs.coreutils}/bin/wc -l)"
        ;;
      *)
        exit 0
        ;;
    esac

    offset=0
    if [ -f "$offset_file" ]; then
      offset="$(${pkgs.coreutils}/bin/cat "$offset_file" 2>/dev/null || ${pkgs.coreutils}/bin/printf '0')"
    fi

    max_offset=$((count - visible))
    if [ "$max_offset" -lt 0 ]; then
      max_offset=0
    fi

    if [ "$direction" = "up" ]; then
      offset=$((offset - 1))
    else
      offset=$((offset + 1))
    fi

    if [ "$offset" -lt 0 ]; then
      offset=0
    fi

    if [ "$offset" -gt "$max_offset" ]; then
      offset="$max_offset"
    fi

    ${pkgs.coreutils}/bin/printf '%s\n' "$offset" > "$offset_file"
  '';

  networkResetScrollScript = pkgs.writeShellScriptBin "leviathan-network-scroll-reset" ''
    offset_dir="''${XDG_CACHE_HOME:-$HOME/.cache}/leviathan"
    ${pkgs.coreutils}/bin/mkdir -p "$offset_dir"
    ${pkgs.coreutils}/bin/printf '0\n' > "$offset_dir/network-known-offset"
    ${pkgs.coreutils}/bin/printf '0\n' > "$offset_dir/network-available-offset"
  '';

in
{
  inherit
    networkSlotUiScript
    networkConnectUiScript
    networkScrollScript
    networkResetScrollScript;
}
