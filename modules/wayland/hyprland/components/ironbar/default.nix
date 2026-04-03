{ lib, pkgs }:
let
  segments = import ./segments {
    inherit pkgs;
  };
in
{
  networkStatus = pkgs.callPackage ./scripts/network-status { inherit lib pkgs; };

  restartBarScript = pkgs.writeShellScriptBin "leviathan-restart-bar" ''
    ${pkgs.procps}/bin/pkill -x ironbar >/dev/null 2>&1 || true
    exec ${pkgs.ironbar}/bin/ironbar
  '';

  inherit segments;
}