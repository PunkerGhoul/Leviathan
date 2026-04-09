{ pkgs }:
pkgs.writeShellScriptBin "leviathan-calendar-month" ''
  exec ${pkgs.util-linux}/bin/cal -m
''