{ pkgs }:
pkgs.writeShellScriptBin "leviathan-calendar" ''
  exec ${pkgs.kitty}/bin/kitty --class kitty-calendar ${pkgs.bash}/bin/bash -lc \
    '${pkgs.util-linux}/bin/cal -m; echo; ${pkgs.coreutils}/bin/date "+%A, %d %B %Y"; echo; read -n 1 -s -r -p "Press any key to close..."'
''
