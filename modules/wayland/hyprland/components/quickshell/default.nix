{ config, lib, pkgs }:
let
  segments = import ./segments {
    inherit pkgs;
  };

  shellQml = import ./config {
    inherit lib pkgs;
  };
in
{
  networkStatus = pkgs.callPackage ./segments/utilities/network/network-status { };

  restartBarScript = pkgs.writeShellScriptBin "leviathan-restart-bar" ''
    shell_qml="${config.home.homeDirectory}/.config/quickshell/shell.qml"
    user_id="$(${pkgs.coreutils}/bin/id -u)"
    ${pkgs.procps}/bin/pkill -u "$user_id" -f "$shell_qml" >/dev/null 2>&1 || true
    ${pkgs.coreutils}/bin/sleep 0.12
    ${pkgs.util-linux}/bin/setsid -f ${pkgs.quickshell}/bin/qs -p "$shell_qml" >/dev/null 2>&1
  '';

  inherit shellQml;
  inherit segments;
}
