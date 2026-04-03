{ pkgs }:
pkgs.writeShellScriptBin "leviathan-wallpaper-picker" ''
  exec ${pkgs.waypaper}/bin/waypaper
''
