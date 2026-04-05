{ pkgs }:
let
  battery = import ./battery.nix { inherit pkgs; };
  bluetooth = import ./bluetooth.nix { inherit pkgs; };
  updates = import ./updates.nix { inherit pkgs; };
  network = import ./network { inherit pkgs; };

  powerIconScript = pkgs.writeShellScriptBin "leviathan-power-icon" ''
    ${pkgs.coreutils}/bin/printf '󰐥\n'
  '';
in
{
  scripts = [
    battery
    bluetooth
    updates.updatesScript
    updates.runUpdatesScript
    network.networkConnectUiScript
    network.networkForgetUiScript
    powerIconScript
  ];

  inherit battery bluetooth updates network powerIconScript;
}
