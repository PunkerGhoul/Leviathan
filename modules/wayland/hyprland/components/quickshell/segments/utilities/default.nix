{ pkgs }:
let
  battery = import ./battery.nix { inherit pkgs; };
  bluetooth = import ./bluetooth.nix { inherit pkgs; };
  updates = import ./updates.nix { inherit pkgs; };
  network = import ./network.nix { inherit pkgs; };

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
    network.networkSlotUiScript
    network.networkConnectUiScript
    network.networkScrollScript
    network.networkResetScrollScript
    powerIconScript
  ];

  inherit battery bluetooth updates network powerIconScript;
}
