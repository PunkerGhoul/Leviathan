{ pkgs }:
let
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
in
{
  inherit updatesScript runUpdatesScript;
}
