{ pkgs }:
let
  networkConnectKnownScript = pkgs.writeShellScriptBin "leviathan-network-connect-known" ''
    index="''${1:-0}"
    ssid="$(network-status ssid known "$index")"

    if [ -z "$ssid" ]; then
      exit 0
    fi

    ${pkgs.networkmanager}/bin/nmcli dev wifi connect "$ssid" >/dev/null 2>&1 || true
  '';

  networkConnectAvailableScript = pkgs.writeShellScriptBin "leviathan-network-connect-available" ''
    index="''${1:-0}"
    ssid="$(network-status ssid available "$index")"

    if [ -z "$ssid" ]; then
      exit 0
    fi

    ${pkgs.networkmanager}/bin/nmcli dev wifi connect "$ssid" >/dev/null 2>&1 || true
  '';
in
{
  inherit networkConnectKnownScript networkConnectAvailableScript;
}
