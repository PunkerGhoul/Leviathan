{ lib, pkgs }:
let
  segments = import ./segments {
    inherit pkgs;
  };
in
{
  networkStatus = pkgs.callPackage ./scripts/network-status { inherit lib pkgs; };

  restartBarScript = pkgs.writeShellScriptBin "leviathan-restart-bar" ''
    ${pkgs.procps}/bin/pkill -x qs >/dev/null 2>&1 || true
    ${pkgs.procps}/bin/pkill -x quickshell >/dev/null 2>&1 || true
    exec ${pkgs.quickshell}/bin/qs -p "$HOME/.config/quickshell/shell.qml"
  '';

  inherit segments;
}
