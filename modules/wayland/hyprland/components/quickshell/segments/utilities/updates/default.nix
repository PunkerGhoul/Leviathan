{ pkgs }:
let
  updatesScript = pkgs.writeShellScriptBin "leviathan-updates" ''
    cache_root="''${XDG_CACHE_HOME:-$HOME/.cache}/leviathan"
    cache_file="$cache_root/updates-count.txt"
    lock_dir="$cache_root/updates-count.lock"
    ttl_seconds=1800
    force_refresh=0

    if [ "''${1:-}" = "--force" ]; then
      force_refresh=1
    fi

    ${pkgs.coreutils}/bin/mkdir -p "$cache_root"

    if [ "$force_refresh" -eq 0 ]; then
      now="$(${pkgs.coreutils}/bin/date +%s)"
      if [ -f "$cache_file" ]; then
        mtime="$(${pkgs.coreutils}/bin/stat -c %Y "$cache_file" 2>/dev/null || ${pkgs.coreutils}/bin/printf '0')"
        age=$((now - mtime))
        if [ "$age" -lt "$ttl_seconds" ]; then
          ${pkgs.coreutils}/bin/cat "$cache_file"
          exit 0
        fi
      fi
    fi

    if ! ${pkgs.coreutils}/bin/mkdir "$lock_dir" 2>/dev/null; then
      if [ -f "$cache_file" ]; then
        ${pkgs.coreutils}/bin/cat "$cache_file"
        exit 0
      fi
    fi

    cleanup() {
      ${pkgs.coreutils}/bin/rmdir "$lock_dir" >/dev/null 2>&1 || true
    }
    trap cleanup EXIT

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
    ${pkgs.coreutils}/bin/printf '%s\n' "$count" > "$cache_file"
    ${pkgs.coreutils}/bin/cat "$cache_file"
  '';

  runUpdatesScript = pkgs.writeShellScriptBin "leviathan-run-updates" ''
    cache_root="''${XDG_CACHE_HOME:-$HOME/.cache}/leviathan"
    cache_file="$cache_root/updates-count.txt"
    run_result_file="$cache_root/updates-run-result.txt"
    db_path="/var/lib/pacman/local"

    ${pkgs.coreutils}/bin/mkdir -p "$cache_root"
    before_mtime="$(${pkgs.coreutils}/bin/stat -c %Y "$db_path" 2>/dev/null || ${pkgs.coreutils}/bin/printf '0')"

    export cache_file run_result_file db_path before_mtime

    update_cmd='if command -v paru >/dev/null 2>&1; then paru -Syu; elif command -v yay >/dev/null 2>&1; then yay -Syu; else sudo pacman -Syu; fi; status=$?; after_mtime=$(${pkgs.coreutils}/bin/stat -c %Y "$db_path" 2>/dev/null || ${pkgs.coreutils}/bin/printf "0"); if [ "$after_mtime" -gt "$before_mtime" ]; then ${pkgs.coreutils}/bin/rm -f "$cache_file"; ${pkgs.coreutils}/bin/printf "changed\n" > "$run_result_file"; else ${pkgs.coreutils}/bin/printf "unchanged\n" > "$run_result_file"; fi; echo; read -n 1 -s -r -p "Press any key to close..."; exit "$status"'

    exec ${pkgs.kitty}/bin/kitty --class kitty-updates ${pkgs.bash}/bin/bash -lc "$update_cmd"
  '';

  updatesRunResultScript = pkgs.writeShellScriptBin "leviathan-updates-run-result" ''
    cache_root="''${XDG_CACHE_HOME:-$HOME/.cache}/leviathan"
    run_result_file="$cache_root/updates-run-result.txt"

    if [ -f "$run_result_file" ]; then
      result="$(${pkgs.coreutils}/bin/cat "$run_result_file" 2>/dev/null || ${pkgs.coreutils}/bin/printf 'unchanged')"
      ${pkgs.coreutils}/bin/rm -f "$run_result_file"
      ${pkgs.coreutils}/bin/printf '%s\n' "$result"
      exit 0
    fi

    ${pkgs.coreutils}/bin/printf 'unchanged\n'
  '';

  updatesStartupScript = pkgs.writeShellScriptBin "leviathan-updates-startup" ''
    cache_root="''${XDG_CACHE_HOME:-$HOME/.cache}/leviathan"
    cache_file="$cache_root/updates-count.txt"

    if result="$(${pkgs.coreutils}/bin/timeout 12s leviathan-updates --force 2>/dev/null)"; then
      ${pkgs.coreutils}/bin/printf '%s\n' "$result"
      exit 0
    fi

    if [ -f "$cache_file" ]; then
      ${pkgs.coreutils}/bin/cat "$cache_file"
      exit 0
    fi

    ${pkgs.coreutils}/bin/printf '0\n'
  '';

in
{
  inherit updatesScript runUpdatesScript updatesRunResultScript updatesStartupScript;
}
