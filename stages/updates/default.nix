{ pkgs }:
let
  updatesAgentPackage = pkgs.rustPlatform.buildRustPackage {
    pname = "leviathan-updates-agent";
    version = "0.1.0";
    src = ./agent;
    cargoLock.lockFile = ./agent/Cargo.lock;
    RUSTFLAGS = "-C opt-level=3";
  };

  managerPackage = pkgs.rustPlatform.buildRustPackage {
    pname = "leviathan-updates-manager";
    version = "0.1.0";
    src = ./manager;
    cargoLock.lockFile = ./manager/Cargo.lock;
    RUSTFLAGS = "-C opt-level=3";
  };

  wrapperTemplate = ''
    #!/usr/bin/env bash
    set -euo pipefail
    export LEVIATHAN_SERVICE_TEMPLATE_PATH="${./units/service.unit}"
    export LEVIATHAN_TIMER_TEMPLATE_PATH="${./units/timer.unit}"
    exec "$(dirname "$0")/leviathan-updates-manager" __MODE__ "$@"
  '';

  wrapperFor = mode:
    pkgs.writeText "leviathan-updates-${mode}" (
      builtins.replaceStrings [ "__MODE__" ] [ mode ] wrapperTemplate
    );

  commandsPackage = pkgs.runCommand "leviathan-updates-commands" { } ''
    mkdir -p "$out/bin"

    install -m 0555 ${managerPackage}/bin/leviathan-updates-manager "$out/bin/leviathan-updates-manager"
    install -m 0555 ${wrapperFor "install"} "$out/bin/leviathan-updates-install"
    install -m 0555 ${wrapperFor "uninstall"} "$out/bin/leviathan-updates-uninstall"
    install -m 0555 ${wrapperFor "status"} "$out/bin/leviathan-updates-status"

    ln -s ${updatesAgentPackage}/bin/leviathan-updates-agent "$out/bin/leviathan-updates-agent"
  '';
in
{
  packages = {
    updates-agent = updatesAgentPackage;
    updates-manager = managerPackage;
    updates-commands = commandsPackage;
  };

  install = {
    package = commandsPackage;
    binary = "leviathan-updates-install";
    description = "Install the updates stage agent.";
  };

  uninstall = {
    package = commandsPackage;
    binary = "leviathan-updates-uninstall";
    description = "Uninstall the updates stage agent.";
  };

  status = {
    package = commandsPackage;
    binary = "leviathan-updates-status";
    description = "Show updates stage status.";
  };
}
