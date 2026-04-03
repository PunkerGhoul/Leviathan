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
    network.networkConnectKnownScript
    network.networkConnectAvailableScript
    powerIconScript
  ];

  inherit battery bluetooth updates network powerIconScript;
}
