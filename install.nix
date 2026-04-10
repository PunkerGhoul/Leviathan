{ pkgs, homeManagerBin, updatesInstallBin ? null }:
pkgs.writeShellApplication {
  name = "leviathan";
  runtimeInputs = [
    pkgs.coreutils
    pkgs.bash
  ];
  text = ''
    set -euo pipefail

    ROOT_DIR="$(pwd)"
    LOCAL_DIR="$ROOT_DIR/local"
    LOCAL_CONFIG_FILE="$LOCAL_DIR/default.nix"

    log() {
      printf '[leviathan] %s\n' "$1"
    }

    ensure_local_config() {
      local detected_user
      local detected_host

      mkdir -p "$LOCAL_DIR"

      if [ -f "$LOCAL_CONFIG_FILE" ]; then
        log "local/default.nix ya existe."
        return 0
      fi

      detected_user="$(id -un 2>/dev/null || printf 'ghoul')"
      detected_host="$(cat /etc/hostname 2>/dev/null | head -n 1 || printf 'leviathan')"

      cat > "$LOCAL_CONFIG_FILE" <<EOF
    {
      username = "''${detected_user}";
      hostname = "''${detected_host}";
    }
    EOF

      log "Se creo local/default.nix con valores detectados."
    }

    ensure_local_config

    log "Validando instalacion"
    if ! command -v nix >/dev/null 2>&1; then
      log "No se encontro 'nix' en PATH."
      exit 1
    fi

    if [ ! -f "$ROOT_DIR/flake.nix" ]; then
      log "No se encontro flake.nix en $ROOT_DIR."
      exit 1
    fi

    if [ ! -f "$ROOT_DIR/home.nix" ]; then
      log "No se encontro home.nix en $ROOT_DIR."
      exit 1
    fi

    log "Ejecutando rebuild con Home Manager"
    "${homeManagerBin}" switch --flake "path:$ROOT_DIR#ghoul" -b backup "$@"

    ${if updatesInstallBin == null then ''
      log "No se encontro updates-install para auto-aplicar stage."
    '' else ''
      log "Aplicando stage automatico: updates-install"
      "${updatesInstallBin}"
    ''}
  '';
}
