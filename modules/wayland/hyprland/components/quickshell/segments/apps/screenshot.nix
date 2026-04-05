{ pkgs }:
pkgs.writeShellScriptBin "leviathan-screenshot" ''
  exec ${pkgs.hyprshot}/bin/hyprshot -m region --clipboard-only
''
