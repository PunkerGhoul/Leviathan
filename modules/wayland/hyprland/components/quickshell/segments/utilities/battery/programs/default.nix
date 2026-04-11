{ pkgs, lib }:
let
  batteryAgent = pkgs.rustPlatform.buildRustPackage rec {
    pname = "leviathan-battery-agent";
    version = "0.1.0";

    src = lib.cleanSource ./leviathan-battery-agent;

    cargoLock = {
      lockFile = ./leviathan-battery-agent/Cargo.lock;
    };

    meta = with lib; {
      description = "Battery telemetry and control tools for Leviathan Quickshell";
      license = licenses.mit;
      platforms = platforms.linux;
    };
  };

  batteryTools = pkgs.runCommand "leviathan-battery-tools" { } ''
    mkdir -p "$out/bin"
    ln -s ${batteryAgent}/bin/leviathan-battery-agent "$out/bin/leviathan-battery"
    ln -s ${batteryAgent}/bin/leviathan-battery-agent "$out/bin/leviathan-battery-info"
    ln -s ${batteryAgent}/bin/leviathan-battery-agent "$out/bin/leviathan-battery-thresholds-info"
    ln -s ${batteryAgent}/bin/leviathan-battery-agent "$out/bin/leviathan-power-profile"
    ln -s ${batteryAgent}/bin/leviathan-battery-agent "$out/bin/leviathan-battery-threshold"
    ln -s ${batteryAgent}/bin/leviathan-battery-agent "$out/bin/leviathan-battery-threshold-pair"
    ln -s ${batteryAgent}/bin/leviathan-battery-agent "$out/bin/leviathan-auto-profile-eval"
    ln -s ${batteryAgent}/bin/leviathan-battery-agent "$out/bin/leviathan-battery-monitor"
  '';
in
{
  inherit batteryAgent batteryTools;
}
