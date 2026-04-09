{ pkgs }:
let
  battery = import ./battery.nix { inherit pkgs; };
  bluetooth = import ./bluetooth.nix { inherit pkgs; };
  volume = import ./volume { inherit pkgs; };
  volumeEvent = import ./volume/event.nix { inherit pkgs; };
  calendarMonth = import ./calendar-month.nix { inherit pkgs; };
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
    volume
    volumeEvent
    calendarMonth
    updates.updatesScript
    updates.runUpdatesScript
    network.vpnStatusScript
    network.networkConnectUiScript
    network.networkForgetUiScript
    powerIconScript
  ];

  inherit battery bluetooth volume volumeEvent calendarMonth updates network powerIconScript;
}
