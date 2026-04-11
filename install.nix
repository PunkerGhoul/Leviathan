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

    ensure_power_profiles_daemon() {
      local ppd_path
      local ppd_exec
      local ppd_dbus_services_dir
      local ppd_dbus_policies_dir
      local ppd_polkit_policy
      local svc
      local conflicts

      conflicts="tlp.service tuned.service auto-cpufreq.service system76-power.service thinkfan.service"

      if ! command -v systemctl >/dev/null 2>&1; then
        log "systemctl no disponible; omitiendo configuracion de power-profiles-daemon."
        return 0
      fi

      if systemctl is-active --quiet power-profiles-daemon.service; then
        log "power-profiles-daemon ya esta activo."
        return 0
      fi

      if ! command -v sudo >/dev/null 2>&1; then
        log "sudo no disponible; no se puede activar power-profiles-daemon."
        return 0
      fi

      for svc in $conflicts; do
        if systemctl list-unit-files "$svc" >/dev/null 2>&1; then
          if systemctl is-enabled --quiet "$svc" 2>/dev/null || systemctl is-active --quiet "$svc" 2>/dev/null; then
            log "Desactivando servicio en conflicto: $svc"
            /usr/bin/sudo /usr/bin/systemctl disable --now "$svc" >/dev/null 2>&1 || true
          fi
        fi
      done

      if command -v powerprofilesctl >/dev/null 2>&1 && powerprofilesctl list >/dev/null 2>&1; then
        log "power-profiles-daemon ya esta disponible por D-Bus."
        return 0
      fi

      log "Preparando power-profiles-daemon a nivel sistema (una sola vez)"
      ppd_path="$(nix build --no-link --print-out-paths nixpkgs#power-profiles-daemon 2>/dev/null | head -n 1 || true)"
      ppd_exec="$ppd_path/libexec/power-profiles-daemon"
      ppd_dbus_services_dir="$ppd_path/share/dbus-1/system-services"
      ppd_dbus_policies_dir="$ppd_path/share/dbus-1/system.d"
      ppd_polkit_policy="$ppd_path/share/polkit-1/actions/power-profiles-daemon.policy"

      if [ -z "$ppd_path" ] || [ ! -x "$ppd_exec" ]; then
        log "No se pudo resolver el ejecutable de power-profiles-daemon desde Nix."
        return 0
      fi

      if [ -d "$ppd_dbus_services_dir" ]; then
        /usr/bin/sudo /usr/bin/install -Dm644 /dev/null \
          /usr/share/dbus-1/system-services/org.freedesktop.UPower.PowerProfiles.service || true
        /usr/bin/sudo /usr/bin/install -Dm644 /dev/null \
          /usr/share/dbus-1/system-services/net.hadess.PowerProfiles.service || true

        /usr/bin/sudo /bin/sh -c "printf '%s\n' '[D-BUS Service]' 'Name=org.freedesktop.UPower.PowerProfiles' 'Exec=$ppd_exec' 'User=root' > /usr/share/dbus-1/system-services/org.freedesktop.UPower.PowerProfiles.service" || true

        /usr/bin/sudo /bin/sh -c "printf '%s\n' '[D-BUS Service]' 'Name=net.hadess.PowerProfiles' 'Exec=$ppd_exec' 'User=root' > /usr/share/dbus-1/system-services/net.hadess.PowerProfiles.service" || true
      fi

      if [ -d "$ppd_dbus_policies_dir" ]; then
        /usr/bin/sudo /usr/bin/install -Dm644 "$ppd_dbus_policies_dir/org.freedesktop.UPower.PowerProfiles.conf" \
          /etc/dbus-1/system.d/org.freedesktop.UPower.PowerProfiles.conf || true
        /usr/bin/sudo /usr/bin/install -Dm644 "$ppd_dbus_policies_dir/net.hadess.PowerProfiles.conf" \
          /etc/dbus-1/system.d/net.hadess.PowerProfiles.conf || true
      fi

      if [ -f "$ppd_polkit_policy" ]; then
        /usr/bin/sudo /usr/bin/install -Dm644 "$ppd_polkit_policy" \
          /usr/share/polkit-1/actions/power-profiles-daemon.policy || true
      fi

      # Use D-Bus activation as primary mode to avoid systemd unit ownership conflicts.
      /usr/bin/sudo /usr/bin/systemctl disable --now power-profiles-daemon.service >/dev/null 2>&1 || true
      /usr/bin/sudo /usr/bin/systemctl reset-failed power-profiles-daemon.service >/dev/null 2>&1 || true
      /usr/bin/sudo /usr/bin/systemctl daemon-reload || true
      /usr/bin/sudo /usr/bin/systemctl reload dbus.service >/dev/null 2>&1 || true

      if command -v powerprofilesctl >/dev/null 2>&1 && powerprofilesctl list >/dev/null 2>&1; then
        log "power-profiles-daemon activo correctamente."
      else
        log "power-profiles-daemon no quedo activo por D-Bus; revisa 'journalctl -u dbus -n 200'."
      fi
    }

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

    ensure_power_profiles_daemon

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
