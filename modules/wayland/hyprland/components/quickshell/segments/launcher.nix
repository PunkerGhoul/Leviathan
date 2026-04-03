{ pkgs }:
pkgs.writeShellScriptBin "leviathan-launcher" ''
  exec ${pkgs.wofi}/bin/wofi --show drun --allow-images
''
