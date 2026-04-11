{ pkgs }:
let
  batterySummaryScript = pkgs.writeShellScriptBin "leviathan-battery" ''
    battery_path="$(${pkgs.findutils}/bin/find /sys/class/power_supply -mindepth 1 -maxdepth 1 -name 'BAT*' | ${pkgs.coreutils}/bin/head -n 1)"

    if [ -z "$battery_path" ]; then
      ${pkgs.coreutils}/bin/printf '\n'
      exit 0
    fi

    capacity="$(${pkgs.coreutils}/bin/cat "$battery_path/capacity" 2>/dev/null || ${pkgs.coreutils}/bin/printf '0')"
    status="$(${pkgs.coreutils}/bin/cat "$battery_path/status" 2>/dev/null || ${pkgs.coreutils}/bin/printf 'Unknown')"

    if [ "$status" = "Charging" ]; then
      icon='󰂄'
    elif [ "$capacity" -ge 95 ]; then
      icon='󰁹'
    elif [ "$capacity" -ge 90 ]; then
      icon='󰂂'
    elif [ "$capacity" -ge 80 ]; then
      icon='󰂁'
    elif [ "$capacity" -ge 70 ]; then
      icon='󰂀'
    elif [ "$capacity" -ge 60 ]; then
      icon='󰁿'
    elif [ "$capacity" -ge 50 ]; then
      icon='󰁾'
    elif [ "$capacity" -ge 40 ]; then
      icon='󰁽'
    elif [ "$capacity" -ge 30 ]; then
      icon='󰁼'
    elif [ "$capacity" -ge 20 ]; then
      icon='󰁻'
    elif [ "$capacity" -ge 10 ]; then
      icon='󰁺'
    else
      icon='󰂃'
    fi

    ${pkgs.coreutils}/bin/printf '%s %s%%\n' "$icon" "$capacity"
  '';

  batteryInfoScript = pkgs.writeShellScriptBin "leviathan-battery-info" ''
    battery_path="$(${pkgs.findutils}/bin/find /sys/class/power_supply -mindepth 1 -maxdepth 1 -name 'BAT*' | ${pkgs.coreutils}/bin/head -n 1)"
    ac_path=""

    for supply in /sys/class/power_supply/*; do
      [ -d "$supply" ] || continue
      [ -f "$supply/online" ] || continue
      type="$(${pkgs.coreutils}/bin/cat "$supply/type" 2>/dev/null || true)"
      case "$type" in
        Mains|USB|USB_C)
          ac_path="$supply"
          break
          ;;
      esac
    done

    read_value() {
      file="$1"
      fallback="$2"
      ${pkgs.coreutils}/bin/cat "$file" 2>/dev/null || ${pkgs.coreutils}/bin/printf '%s' "$fallback"
    }

    read_first_existing() {
      fallback="$1"
      shift
      for candidate in "$@"; do
        if [ -f "$candidate" ]; then
          read_value "$candidate" "$fallback"
          return 0
        fi
      done
      ${pkgs.coreutils}/bin/printf '%s' "$fallback"
    }

    read_state_value() {
      file="$1"
      key="$2"
      fallback="$3"

      if [ ! -f "$file" ]; then
        ${pkgs.coreutils}/bin/printf '%s' "$fallback"
        return
      fi

      value="$(${pkgs.gawk}/bin/awk -F= -v key="$key" '$1 == key { print substr($0, index($0, "=") + 1); exit }' "$file" 2>/dev/null)"
      if [ -n "$value" ]; then
        ${pkgs.coreutils}/bin/printf '%s' "$value"
      else
        ${pkgs.coreutils}/bin/printf '%s' "$fallback"
      fi
    }

    format_auto_source_label() {
      raw="$1"
      case "$raw" in
        ac) ${pkgs.coreutils}/bin/printf 'AC' ;;
        ups) ${pkgs.coreutils}/bin/printf 'UPS' ;;
        battery) ${pkgs.coreutils}/bin/printf 'Battery' ;;
        *) ${pkgs.coreutils}/bin/printf '%s' "$raw" ;;
      esac
    }

    fmt_voltage() {
      raw="$1"
      if [ -z "$raw" ] || [ "$raw" = "0" ]; then
        ${pkgs.coreutils}/bin/printf 'N/A'
      else
        ${pkgs.gawk}/bin/awk -v uV="$raw" 'BEGIN { printf "%.2f V", (uV / 1000000.0) }'
      fi
    }

    fmt_watts_from_uW() {
      raw="$1"
      [ -n "$raw" ] || raw="0"
      ${pkgs.gawk}/bin/awk -v uW="$raw" 'BEGIN { printf "%.2f W", (uW / 1000000.0) }'
    }

    abs_raw() {
      raw="$1"
      ${pkgs.gawk}/bin/awk -v x="$raw" 'BEGIN { if (x < 0) x = -x; printf "%.0f", x }'
    }

    fmt_watts_from_uA_uV() {
      current_uA="$1"
      voltage_uV="$2"
      if [ -z "$current_uA" ] || [ "$current_uA" = "0" ]; then
        ${pkgs.coreutils}/bin/printf '0.00 W'
      elif [ -z "$voltage_uV" ] || [ "$voltage_uV" = "0" ]; then
        ${pkgs.coreutils}/bin/printf 'N/A'
      else
        ${pkgs.gawk}/bin/awk -v uA="$current_uA" -v uV="$voltage_uV" 'BEGIN { printf "%.2f W", ((uA * uV) / 1000000000000.0) }'
      fi
    }

    fmt_time_hm() {
      hours="$1"
      suffix="$2"

      if [ -z "$hours" ]; then
        ${pkgs.coreutils}/bin/printf 'N/A'
        return
      fi

      if ! ${pkgs.gawk}/bin/awk -v h="$hours" 'BEGIN { exit !(h > 0) }'; then
        ${pkgs.coreutils}/bin/printf 'N/A'
        return
      fi

      ${pkgs.gawk}/bin/awk -v h="$hours" -v suffix="$suffix" 'BEGIN {
        total = int(h * 60 + 0.5);
        hh = int(total / 60);
        mm = total % 60;
        printf "%dh %dm %s", hh, mm, suffix;
      }'
    }

    fmt_temp_c() {
      milli_c="$1"
      if [ -z "$milli_c" ]; then
        ${pkgs.coreutils}/bin/printf 'N/A'
        return
      fi

      if ! ${pkgs.gawk}/bin/awk -v t="$milli_c" 'BEGIN { exit !(t > 0) }'; then
        ${pkgs.coreutils}/bin/printf 'N/A'
        return
      fi

      ${pkgs.gawk}/bin/awk -v t="$milli_c" 'BEGIN { printf "%.1f C", (t / 1000.0) }'
    }

    read_cpu_temp_milli() {
      selected=""

      for zone in /sys/class/thermal/thermal_zone*; do
        [ -d "$zone" ] || continue
        [ -f "$zone/type" ] || continue
        [ -f "$zone/temp" ] || continue
        ztype="$(${pkgs.coreutils}/bin/cat "$zone/type" 2>/dev/null || true)"
        case "$ztype" in
          x86_pkg_temp)
            ${pkgs.coreutils}/bin/cat "$zone/temp" 2>/dev/null || true
            return 0
            ;;
          cpu-thermal|CPU-thermal|soc_thermal|Tctl)
            if [ -z "$selected" ]; then
              selected="$zone/temp"
            fi
            ;;
        esac
      done

      if [ -n "$selected" ]; then
        ${pkgs.coreutils}/bin/cat "$selected" 2>/dev/null || true
        return 0
      fi

      # Fallback: first valid thermal zone.
      for zone in /sys/class/thermal/thermal_zone*; do
        [ -f "$zone/temp" ] || continue
        ${pkgs.coreutils}/bin/cat "$zone/temp" 2>/dev/null || true
        return 0
      done
    }

    read_gpu_temp_milli() {
      for zone in /sys/class/thermal/thermal_zone*; do
        [ -d "$zone" ] || continue
        [ -f "$zone/type" ] || continue
        [ -f "$zone/temp" ] || continue
        ztype="$(${pkgs.coreutils}/bin/cat "$zone/type" 2>/dev/null || true)"
        case "$ztype" in
          gpu*|amdgpu*)
            ${pkgs.coreutils}/bin/cat "$zone/temp" 2>/dev/null || true
            return 0
            ;;
        esac
      done

      if command -v nvidia-smi >/dev/null 2>&1; then
        temp_c="$(${pkgs.coreutils}/bin/timeout 0.20s nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null | ${pkgs.coreutils}/bin/head -n 1 | ${pkgs.coreutils}/bin/tr -d '\r\n ' || true)"
        if [ -n "$temp_c" ] && [ "$temp_c" != "[Not Supported]" ]; then
          ${pkgs.gawk}/bin/awk -v c="$temp_c" 'BEGIN { if (c > 0) printf "%.0f", (c * 1000.0) }'
          return 0
        fi
      fi
    }

    classify_thermal_state() {
      cpu_milli="$1"
      if [ -z "$cpu_milli" ] || ! ${pkgs.gawk}/bin/awk -v t="$cpu_milli" 'BEGIN { exit !(t > 0) }'; then
        ${pkgs.coreutils}/bin/printf 'Unknown'
        return
      fi

      if ${pkgs.gawk}/bin/awk -v t="$cpu_milli" 'BEGIN { exit !(t >= 92000) }'; then
        ${pkgs.coreutils}/bin/printf 'Critical'
      elif ${pkgs.gawk}/bin/awk -v t="$cpu_milli" 'BEGIN { exit !(t >= 85000) }'; then
        ${pkgs.coreutils}/bin/printf 'Hot'
      elif ${pkgs.gawk}/bin/awk -v t="$cpu_milli" 'BEGIN { exit !(t >= 75000) }'; then
        ${pkgs.coreutils}/bin/printf 'Warm'
      else
        ${pkgs.coreutils}/bin/printf 'Normal'
      fi
    }

    if [ -z "$battery_path" ]; then
      ppd_state="off"
      sysfs_tweaks_state="off"
      if command -v powerprofilesctl >/dev/null 2>&1 && powerprofilesctl list >/dev/null 2>&1; then
        ppd_state="on"
      fi

      ${pkgs.coreutils}/bin/printf 'STATUS=No battery\n'
      ${pkgs.coreutils}/bin/printf 'PROFILE=N/A\n'
      ${pkgs.coreutils}/bin/printf 'VOLTAGE=N/A\n'
      ${pkgs.coreutils}/bin/printf 'CYCLES=N/A\n'
      ${pkgs.coreutils}/bin/printf 'RATE=N/A\n'
      ${pkgs.coreutils}/bin/printf 'TIME_REMAINING=N/A\n'
      ${pkgs.coreutils}/bin/printf 'AC_STATE=N/A\n'
      ${pkgs.coreutils}/bin/printf 'CPU_TEMP=N/A\n'
      ${pkgs.coreutils}/bin/printf 'GPU_TEMP=N/A\n'
      ${pkgs.coreutils}/bin/printf 'THERMAL_STATE=Unknown\n'
      ${pkgs.coreutils}/bin/printf 'AUTO_TARGET=N/A\n'
      ${pkgs.coreutils}/bin/printf 'AUTO_SOURCE=N/A\n'
      ${pkgs.coreutils}/bin/printf 'BACKEND=ppd:%s | sysfs:%s\n' "$ppd_state" "$sysfs_tweaks_state"
      ${pkgs.coreutils}/bin/printf 'START_THRESHOLD=-1\n'
      ${pkgs.coreutils}/bin/printf 'STOP_THRESHOLD=-1\n'
      exit 0
    fi

    status="$(read_value "$battery_path/status" "Unknown")"
    capacity="$(read_value "$battery_path/capacity" "0")"
    voltage_now="$(read_value "$battery_path/voltage_now" "0")"
    current_now="$(read_value "$battery_path/current_now" "0")"
    power_now="$(read_value "$battery_path/power_now" "0")"
    cycle_count="$(read_value "$battery_path/cycle_count" "N/A")"
    energy_now="$(read_value "$battery_path/energy_now" "0")"
    energy_full="$(read_value "$battery_path/energy_full" "0")"
    charge_now="$(read_value "$battery_path/charge_now" "0")"
    charge_full="$(read_value "$battery_path/charge_full" "0")"

    power_abs="$(abs_raw "$power_now")"
    current_abs="$(abs_raw "$current_now")"

    start_threshold="$(read_first_existing "-1" "$battery_path/charge_control_start_threshold" "$battery_path/charge_start_threshold")"
    stop_threshold="$(read_first_existing "-1" "$battery_path/charge_control_end_threshold" "$battery_path/charge_stop_threshold")"

    if [ -n "$ac_path" ]; then
      ac_online="$(read_value "$ac_path/online" "0")"
      if [ "$ac_online" = "1" ]; then
        ac_state="Connected"
      else
        ac_state="Disconnected"
      fi
    else
      if [ "$status" = "Charging" ] || [ "$status" = "Full" ]; then
        ac_state="Connected"
      elif [ "$status" = "Discharging" ]; then
        ac_state="Disconnected"
      else
        ac_state="Unknown"
      fi
    fi

    state_root="''${XDG_STATE_HOME:-$HOME/.local/state}/leviathan"
    mode_file="$state_root/power-profile-mode"
    auto_state_file="$state_root/auto-profile.state"
    selected_mode=""

    profile=""
    if command -v powerprofilesctl >/dev/null 2>&1; then
      profile="$(powerprofilesctl get 2>/dev/null | ${pkgs.coreutils}/bin/head -n 1 | ${pkgs.coreutils}/bin/tr -d '\r')"
    fi

    [ -n "$profile" ] || profile="$(read_first_existing "" /sys/firmware/acpi/platform_profile)"
    [ -n "$profile" ] || profile="auto"

    if [ -f "$mode_file" ]; then
      selected_mode="$(read_value "$mode_file" "" | ${pkgs.coreutils}/bin/tr -d '\r\n')"
      if [ "$selected_mode" = "auto" ] || [ "$selected_mode" = "turbo" ]; then
        profile="$selected_mode"
      fi
    fi

    auto_target="N/A"
    auto_source="N/A"
    if [ "$profile" = "auto" ]; then
      auto_target="$(read_state_value "$auto_state_file" "current_target" "N/A")"
      auto_source="$(read_state_value "$auto_state_file" "power_source" "N/A")"
      auto_source="$(format_auto_source_label "$auto_source")"
    fi

    ppd_state="off"
    sysfs_tweaks_state="off"
    if command -v powerprofilesctl >/dev/null 2>&1 && powerprofilesctl list >/dev/null 2>&1; then
      ppd_state="on"
    fi
    if [ "$start_threshold" != "-1" ] || [ "$stop_threshold" != "-1" ]; then
      sysfs_tweaks_state="on"
    fi

    rate="$(fmt_watts_from_uW "$power_abs")"
    if [ "$rate" = "0.00 W" ] || [ "$rate" = "N/A" ]; then
      rate="$(fmt_watts_from_uA_uV "$current_abs" "$voltage_now")"
    fi

    time_remaining="Estimating..."
    if [ "$status" = "Discharging" ]; then
      hours="$(
        ${pkgs.gawk}/bin/awk -v eNow="$energy_now" -v pAbs="$power_abs" -v cNow="$charge_now" -v cAbs="$current_abs" 'BEGIN {
          if (eNow > 0 && pAbs > 0) {
            printf "%.6f", eNow / pAbs;
            exit 0;
          }
          if (cNow > 0 && cAbs > 0) {
            printf "%.6f", cNow / cAbs;
          }
        }'
      )"
      remaining_fmt="$(fmt_time_hm "$hours" "to empty")"
      if [ "$remaining_fmt" != "N/A" ]; then
        time_remaining="$remaining_fmt"
      fi
    elif [ "$status" = "Charging" ]; then
      hours="$(
        ${pkgs.gawk}/bin/awk -v eFull="$energy_full" -v eNow="$energy_now" -v pAbs="$power_abs" -v cFull="$charge_full" -v cNow="$charge_now" -v cAbs="$current_abs" 'BEGIN {
          eRem = eFull - eNow;
          cRem = cFull - cNow;
          if (eRem > 0 && pAbs > 0) {
            printf "%.6f", eRem / pAbs;
            exit 0;
          }
          if (cRem > 0 && cAbs > 0) {
            printf "%.6f", cRem / cAbs;
          }
        }'
      )"
      remaining_fmt="$(fmt_time_hm "$hours" "to full")"
      if [ "$remaining_fmt" != "N/A" ]; then
        time_remaining="$remaining_fmt"
      fi
    elif [ "$status" = "Not charging" ]; then
      if [ "$ac_state" = "Connected" ]; then
        time_remaining="Holding (plugged in)"
      else
        time_remaining="Idle"
      fi
    elif [ "$status" = "Full" ]; then
      time_remaining="At limit"
    fi

    cpu_temp_milli="$(read_cpu_temp_milli | ${pkgs.coreutils}/bin/head -n 1 | ${pkgs.coreutils}/bin/tr -d '\r\n')"
    gpu_temp_milli="$(read_gpu_temp_milli | ${pkgs.coreutils}/bin/head -n 1 | ${pkgs.coreutils}/bin/tr -d '\r\n')"
    cpu_temp_fmt="$(fmt_temp_c "$cpu_temp_milli")"
    gpu_temp_fmt="$(fmt_temp_c "$gpu_temp_milli")"
    thermal_state="$(classify_thermal_state "$cpu_temp_milli")"

    ${pkgs.coreutils}/bin/printf 'STATUS=%s\n' "$status"
    ${pkgs.coreutils}/bin/printf 'CAPACITY=%s\n' "$capacity"
    ${pkgs.coreutils}/bin/printf 'PROFILE=%s\n' "$profile"
    ${pkgs.coreutils}/bin/printf 'VOLTAGE=%s\n' "$(fmt_voltage "$voltage_now")"
    ${pkgs.coreutils}/bin/printf 'CYCLES=%s\n' "$cycle_count"
    ${pkgs.coreutils}/bin/printf 'RATE=%s\n' "$rate"
    ${pkgs.coreutils}/bin/printf 'TIME_REMAINING=%s\n' "$time_remaining"
    ${pkgs.coreutils}/bin/printf 'AC_STATE=%s\n' "$ac_state"
    ${pkgs.coreutils}/bin/printf 'CPU_TEMP=%s\n' "$cpu_temp_fmt"
    ${pkgs.coreutils}/bin/printf 'GPU_TEMP=%s\n' "$gpu_temp_fmt"
    ${pkgs.coreutils}/bin/printf 'THERMAL_STATE=%s\n' "$thermal_state"
    ${pkgs.coreutils}/bin/printf 'AUTO_TARGET=%s\n' "$auto_target"
    ${pkgs.coreutils}/bin/printf 'AUTO_SOURCE=%s\n' "$auto_source"
    ${pkgs.coreutils}/bin/printf 'BACKEND=ppd:%s | sysfs:%s\n' "$ppd_state" "$sysfs_tweaks_state"
    ${pkgs.coreutils}/bin/printf 'START_THRESHOLD=%s\n' "$start_threshold"
    ${pkgs.coreutils}/bin/printf 'STOP_THRESHOLD=%s\n' "$stop_threshold"
  '';

  batteryThresholdsInfoScript = pkgs.writeShellScriptBin "leviathan-battery-thresholds-info" ''
    battery_path="$(${pkgs.findutils}/bin/find /sys/class/power_supply -mindepth 1 -maxdepth 1 -name 'BAT*' | ${pkgs.coreutils}/bin/head -n 1)"

    read_value() {
      file="$1"
      fallback="$2"
      ${pkgs.coreutils}/bin/cat "$file" 2>/dev/null || ${pkgs.coreutils}/bin/printf '%s' "$fallback"
    }

    read_first_existing() {
      fallback="$1"
      shift
      for candidate in "$@"; do
        if [ -f "$candidate" ]; then
          read_value "$candidate" "$fallback"
          return 0
        fi
      done
      ${pkgs.coreutils}/bin/printf '%s' "$fallback"
    }

    if [ -z "$battery_path" ]; then
      ${pkgs.coreutils}/bin/printf 'START_THRESHOLD=-1\n'
      ${pkgs.coreutils}/bin/printf 'STOP_THRESHOLD=-1\n'
      exit 0
    fi

    start_threshold="$(read_first_existing "-1" "$battery_path/charge_control_start_threshold" "$battery_path/charge_start_threshold")"
    stop_threshold="$(read_first_existing "-1" "$battery_path/charge_control_end_threshold" "$battery_path/charge_stop_threshold")"

    ${pkgs.coreutils}/bin/printf 'START_THRESHOLD=%s\n' "$start_threshold"
    ${pkgs.coreutils}/bin/printf 'STOP_THRESHOLD=%s\n' "$stop_threshold"
  '';

  powerProfileScript = pkgs.writeShellScriptBin "leviathan-power-profile" ''
    profile="$1"
    profile_ppd=""
    state_root="''${XDG_STATE_HOME:-$HOME/.local/state}/leviathan"
    mode_file="$state_root/power-profile-mode"
    stable_mode_file="$state_root/power-profile-stable"

    emit_error() {
      ${pkgs.coreutils}/bin/printf 'error:%s\n' "$1"
      exit 1
    }

    emit_ok() {
      ${pkgs.coreutils}/bin/printf 'ok:%s\n' "$1"
      exit 0
    }

    detect_ac_state() {
      for supply in /sys/class/power_supply/*; do
        [ -d "$supply" ] || continue
        [ -f "$supply/online" ] || continue
        type="$(${pkgs.coreutils}/bin/cat "$supply/type" 2>/dev/null || true)"
        case "$type" in
          Mains|USB|USB_C)
            online="$(${pkgs.coreutils}/bin/cat "$supply/online" 2>/dev/null || ${pkgs.coreutils}/bin/printf '0')"
            if [ "$online" = "1" ]; then
              ${pkgs.coreutils}/bin/printf 'connected'
            else
              ${pkgs.coreutils}/bin/printf 'disconnected'
            fi
            return 0
            ;;
        esac
      done

      # Fallback: infer from battery status if no explicit AC supply exists.
      battery_path="$(${pkgs.findutils}/bin/find /sys/class/power_supply -mindepth 1 -maxdepth 1 -name 'BAT*' | ${pkgs.coreutils}/bin/head -n 1)"
      if [ -n "$battery_path" ]; then
        status="$(${pkgs.coreutils}/bin/cat "$battery_path/status" 2>/dev/null || ${pkgs.coreutils}/bin/printf 'Unknown')"
        if [ "$status" = "Charging" ] || [ "$status" = "Full" ] || [ "$status" = "Not charging" ]; then
          ${pkgs.coreutils}/bin/printf 'connected'
          return 0
        fi
      fi

      ${pkgs.coreutils}/bin/printf 'unknown'
    }

    apply_turbo_fan_boost() {
      boosted="0"

      if [ -w /proc/acpi/ibm/fan ]; then
        if ${pkgs.coreutils}/bin/printf 'level disengaged\n' > /proc/acpi/ibm/fan 2>/dev/null; then
          boosted="1"
        fi
      fi

      if [ "$boosted" != "1" ]; then
        for hwmon in /sys/class/hwmon/hwmon*; do
          [ -f "$hwmon/pwm1_enable" ] || continue
          [ -f "$hwmon/pwm1" ] || continue
          [ -w "$hwmon/pwm1_enable" ] || continue
          [ -w "$hwmon/pwm1" ] || continue

          ${pkgs.coreutils}/bin/printf '1\n' > "$hwmon/pwm1_enable" 2>/dev/null || continue
          ${pkgs.coreutils}/bin/printf '255\n' > "$hwmon/pwm1" 2>/dev/null || continue

          boosted="1"
          break
        done
      fi

      ${pkgs.coreutils}/bin/printf '%s' "$boosted"
    }

    write_if_writable() {
      file="$1"
      value="$2"

      [ -n "$file" ] || return 1
      [ -w "$file" ] || return 1
      ${pkgs.coreutils}/bin/printf '%s\n' "$value" > "$file" 2>/dev/null
    }

    set_platform_profile() {
      target="$1"
      profile_file="/sys/firmware/acpi/platform_profile"
      choices_file="/sys/firmware/acpi/platform_profile_choices"

      [ -n "$target" ] || return 1
      [ -f "$profile_file" ] || return 1
      [ -w "$profile_file" ] || return 1

      if [ -f "$choices_file" ]; then
        if ! ${pkgs.gnugrep}/bin/grep -qw -- "$target" "$choices_file" 2>/dev/null; then
          return 1
        fi
      fi

      write_if_writable "$profile_file" "$target"
    }

    set_cpu_policy() {
      mode="$1"
      max_pct=""
      min_pct=""
      epp=""
      platform=""

      case "$mode" in
        power-saver)
          max_pct="70"
          min_pct="20"
          epp="balance_power"
          platform="low-power"
          ;;
        balanced)
          max_pct="85"
          min_pct="25"
          epp="balance_performance"
          platform="balanced"
          ;;
        performance)
          # Thermal-safe performance: keep UI responsive while reducing sustained heat.
          max_pct="92"
          min_pct="30"
          epp="balance_performance"
          platform="balanced"
          ;;
        turbo)
          max_pct="100"
          min_pct="35"
          epp="performance"
          platform="performance"
          ;;
        auto)
          if [ "$ac_state" = "connected" ]; then
            max_pct="88"
            min_pct="28"
            epp="balance_performance"
            platform="balanced"
          else
            max_pct="80"
            min_pct="22"
            epp="balance_power"
            platform="balanced"
          fi
          ;;
      esac

      write_if_writable "/sys/devices/system/cpu/intel_pstate/max_perf_pct" "$max_pct" >/dev/null 2>&1 || true
      write_if_writable "/sys/devices/system/cpu/intel_pstate/min_perf_pct" "$min_pct" >/dev/null 2>&1 || true

      for policy in /sys/devices/system/cpu/cpufreq/policy*; do
        [ -d "$policy" ] || continue
        write_if_writable "$policy/energy_performance_preference" "$epp" >/dev/null 2>&1 || true
      done

      set_platform_profile "$platform" >/dev/null 2>&1 || true
    }

    resolve_ppd_for_mode() {
      mode="$1"
      case "$mode" in
        auto)
          if [ "$ac_state" = "connected" ]; then
            ${pkgs.coreutils}/bin/printf 'balanced'
          else
            ${pkgs.coreutils}/bin/printf 'power-saver'
          fi
          ;;
        power-saver|balanced|performance)
          ${pkgs.coreutils}/bin/printf '%s' "$mode"
          ;;
        turbo)
          ${pkgs.coreutils}/bin/printf 'performance'
          ;;
      esac
    }

    case "$profile" in
      power-saver|balanced|performance|auto|turbo) ;;
      *) emit_error "Invalid profile (use auto, power-saver, balanced, performance, turbo)" ;;
    esac

    ac_state="$(detect_ac_state)"

    # Resolve desired targets for each backend.
    if [ "$profile" = "auto" ]; then
      if [ "$ac_state" = "connected" ]; then
        profile_ppd="balanced"
      else
        profile_ppd="power-saver"
      fi
    else
      case "$profile" in
        power-saver)
          profile_ppd="power-saver"
          ;;
        balanced)
          profile_ppd="balanced"
          ;;
        performance)
          profile_ppd="performance"
          ;;
        turbo)
          if [ "$ac_state" != "connected" ]; then
            emit_error "Turbo requires AC power"
          fi
          profile_ppd="performance"
          ;;
      esac
    fi

    if ! command -v powerprofilesctl >/dev/null 2>&1; then
      emit_error "powerprofilesctl is not installed"
    fi

    if ! powerprofilesctl list >/dev/null 2>&1; then
      emit_error "power-profiles-daemon is not active (run leviathan to configure it once)"
    fi

    out="$(powerprofilesctl set "$profile_ppd" 2>&1)"
    if [ $? -eq 0 ]; then
      set_cpu_policy "$profile"

      ${pkgs.coreutils}/bin/mkdir -p "$state_root" >/dev/null 2>&1 || true
      ${pkgs.coreutils}/bin/printf '%s\n' "$profile" > "$mode_file" 2>/dev/null || true
      ${pkgs.coreutils}/bin/printf '%s\n' "$profile" > "$stable_mode_file" 2>/dev/null || true

      if [ "$profile" = "auto" ]; then
        emit_ok "Auto applied: $profile_ppd ($ac_state)"
      fi

      if [ "$profile" = "turbo" ]; then
        fan_boosted="$(apply_turbo_fan_boost)"
        if [ "$fan_boosted" = "1" ]; then
          emit_ok "Turbo enabled (AC): performance + fan boost"
        fi
        emit_ok "Turbo enabled (AC): performance (fan boost unavailable)"
      fi

      emit_ok "Profile set to $profile_ppd"
    fi

    out="$(printf '%s' "$out" | tr '\n' ' ')"

    # Best-effort rollback to last known stable profile.
    last_stable=""
    if [ -f "$stable_mode_file" ]; then
      last_stable="$(${pkgs.coreutils}/bin/cat "$stable_mode_file" 2>/dev/null | ${pkgs.coreutils}/bin/tr -d '\r\n')"
    fi

    if [ -n "$last_stable" ]; then
      rollback_ppd="$(resolve_ppd_for_mode "$last_stable")"
      if [ -n "$rollback_ppd" ]; then
        if powerprofilesctl set "$rollback_ppd" >/dev/null 2>&1; then
          set_cpu_policy "$last_stable"
          emit_error "Failed to set $profile. Reverted to stable profile: $last_stable"
        fi
      fi
    fi

    [ -n "$out" ] || out="Failed to set power profile"
    emit_error "$out"
  '';

  batteryThresholdScript = pkgs.writeShellScriptBin "leviathan-battery-threshold" ''
    kind="$1"
    value="$2"

    emit_error() {
      ${pkgs.coreutils}/bin/printf 'error:%s\n' "$1"
      exit 1
    }

    emit_ok() {
      ${pkgs.coreutils}/bin/printf 'ok:%s\n' "$1"
      exit 0
    }

    case "$kind" in
      start|stop) ;;
      *) emit_error "Invalid threshold kind (start or stop)" ;;
    esac

    case "$value" in
      ""|*[!0-9]*) emit_error "Threshold must be a number" ;;
    esac

    if [ "$value" -lt 0 ] || [ "$value" -gt 100 ]; then
      emit_error "Threshold must be between 0 and 100"
    fi

    battery_path="$(${pkgs.findutils}/bin/find /sys/class/power_supply -mindepth 1 -maxdepth 1 -name 'BAT*' | ${pkgs.coreutils}/bin/head -n 1)"
    if [ -z "$battery_path" ]; then
      emit_error "Battery not found"
    fi

    target_file=""
    if [ "$kind" = "start" ]; then
      for candidate in "$battery_path/charge_control_start_threshold" "$battery_path/charge_start_threshold"; do
        if [ -f "$candidate" ]; then
          target_file="$candidate"
          break
        fi
      done
    else
      for candidate in "$battery_path/charge_control_end_threshold" "$battery_path/charge_stop_threshold"; do
        if [ -f "$candidate" ]; then
          target_file="$candidate"
          break
        fi
      done
    fi

    if [ -z "$target_file" ]; then
      emit_error "Charge threshold is not supported on this battery"
    fi

    ${pkgs.coreutils}/bin/printf '%s\n' "$value" > "$target_file" 2>/dev/null
    if [ $? -eq 0 ]; then
      emit_ok "Updated $kind threshold to $value%"
    fi

    if command -v pkexec >/dev/null 2>&1; then
      if pkexec ${pkgs.bash}/bin/bash -c 'printf "%s\n" "$1" > "$2"' _ "$value" "$target_file" >/dev/null 2>&1; then
        emit_ok "Updated $kind threshold to $value%"
      fi
      emit_error "Authorization failed or cancelled (polkit prompt)."
    fi

    emit_error "Failed to write threshold (no permission and pkexec unavailable)"
  '';

  batteryThresholdPairScript = pkgs.writeShellScriptBin "leviathan-battery-threshold-pair" ''
    start_value="$1"
    stop_value="$2"

    emit_error() {
      ${pkgs.coreutils}/bin/printf 'error:%s\n' "$1"
      exit 1
    }

    emit_ok() {
      ${pkgs.coreutils}/bin/printf 'ok:%s\n' "$1"
      exit 0
    }

    case "$start_value" in
      ""|*[!0-9]*) emit_error "Start threshold must be a number" ;;
    esac
    case "$stop_value" in
      ""|*[!0-9]*) emit_error "Stop threshold must be a number" ;;
    esac

    if [ "$start_value" -lt 0 ] || [ "$start_value" -gt 100 ]; then
      emit_error "Start threshold must be between 0 and 100"
    fi
    if [ "$stop_value" -lt 0 ] || [ "$stop_value" -gt 100 ]; then
      emit_error "Stop threshold must be between 0 and 100"
    fi
    if [ "$start_value" -gt $((stop_value - 5)) ]; then
      emit_error "Start must be at most Stop - 5"
    fi

    battery_path="$(${pkgs.findutils}/bin/find /sys/class/power_supply -mindepth 1 -maxdepth 1 -name 'BAT*' | ${pkgs.coreutils}/bin/head -n 1)"
    if [ -z "$battery_path" ]; then
      emit_error "Battery not found"
    fi

    start_file=""
    stop_file=""

    for candidate in "$battery_path/charge_control_start_threshold" "$battery_path/charge_start_threshold"; do
      if [ -f "$candidate" ]; then
        start_file="$candidate"
        break
      fi
    done

    for candidate in "$battery_path/charge_control_end_threshold" "$battery_path/charge_stop_threshold"; do
      if [ -f "$candidate" ]; then
        stop_file="$candidate"
        break
      fi
    done

    if [ -z "$start_file" ] || [ -z "$stop_file" ]; then
      emit_error "Charge thresholds are not supported on this battery"
    fi

    ${pkgs.coreutils}/bin/printf '%s\n' "$start_value" > "$start_file" 2>/dev/null && \
      ${pkgs.coreutils}/bin/printf '%s\n' "$stop_value" > "$stop_file" 2>/dev/null
    if [ $? -eq 0 ]; then
      emit_ok "Updated thresholds: start=$start_value% stop=$stop_value%"
    fi

    if command -v pkexec >/dev/null 2>&1; then
      if pkexec ${pkgs.bash}/bin/bash -c 'printf "%s\n" "$1" > "$3" && printf "%s\n" "$2" > "$4"' _ "$start_value" "$stop_value" "$start_file" "$stop_file" >/dev/null 2>&1; then
        emit_ok "Updated thresholds: start=$start_value% stop=$stop_value%"
      fi
      emit_error "Authorization failed or cancelled (polkit prompt)."
    fi

    emit_error "Failed to write thresholds (no permission and pkexec unavailable)"
  '';

  autoProfileEvalScript = pkgs.writeShellScriptBin "leviathan-auto-profile-eval" ''
    state_root="''${XDG_STATE_HOME:-$HOME/.local/state}/leviathan"
    mode_file="$state_root/power-profile-mode"
    state_file="$state_root/auto-profile.state"

    ${pkgs.coreutils}/bin/mkdir -p "$state_root" >/dev/null 2>&1 || true

    read_kv() {
      key="$1"
      default="$2"
      if [ ! -f "$state_file" ]; then
        ${pkgs.coreutils}/bin/printf '%s' "$default"
        return
      fi
      value="$(${pkgs.gawk}/bin/awk -F= -v key="$key" '$1 == key { print substr($0, index($0, "=") + 1); exit }' "$state_file" 2>/dev/null)"
      if [ -n "$value" ]; then
        ${pkgs.coreutils}/bin/printf '%s' "$value"
      else
        ${pkgs.coreutils}/bin/printf '%s' "$default"
      fi
    }

    detect_power_source() {
      for supply in /sys/class/power_supply/*; do
        [ -d "$supply" ] || continue
        [ -f "$supply/online" ] || continue
        type="$(${pkgs.coreutils}/bin/cat "$supply/type" 2>/dev/null || true)"
        online="$(${pkgs.coreutils}/bin/cat "$supply/online" 2>/dev/null || ${pkgs.coreutils}/bin/printf '0')"
        [ "$online" = "1" ] || continue
        case "$type" in
          Mains|USB|USB_C)
            ${pkgs.coreutils}/bin/printf 'ac'
            return 0
            ;;
          UPS)
            ${pkgs.coreutils}/bin/printf 'ups'
            return 0
            ;;
        esac
      done
      ${pkgs.coreutils}/bin/printf 'battery'
    }

    write_if_writable() {
      file="$1"
      value="$2"
      [ -n "$file" ] || return 1
      [ -w "$file" ] || return 1
      ${pkgs.coreutils}/bin/printf '%s\n' "$value" > "$file" 2>/dev/null
    }

    set_platform_profile() {
      target="$1"
      profile_file="/sys/firmware/acpi/platform_profile"
      choices_file="/sys/firmware/acpi/platform_profile_choices"

      [ -n "$target" ] || return 1
      [ -f "$profile_file" ] || return 1
      [ -w "$profile_file" ] || return 1

      if [ -f "$choices_file" ]; then
        if ! ${pkgs.gnugrep}/bin/grep -qw -- "$target" "$choices_file" 2>/dev/null; then
          return 1
        fi
      fi

      write_if_writable "$profile_file" "$target"
    }

    apply_cpu_policy_for_target() {
      target="$1"
      max_pct="85"
      min_pct="25"
      epp="balance_performance"
      platform="balanced"

      case "$target" in
        power-saver)
          max_pct="70"
          min_pct="20"
          epp="balance_power"
          platform="low-power"
          ;;
        balanced)
          max_pct="85"
          min_pct="25"
          epp="balance_performance"
          platform="balanced"
          ;;
        performance)
          max_pct="92"
          min_pct="30"
          epp="balance_performance"
          platform="balanced"
          ;;
      esac

      write_if_writable "/sys/devices/system/cpu/intel_pstate/max_perf_pct" "$max_pct" >/dev/null 2>&1 || true
      write_if_writable "/sys/devices/system/cpu/intel_pstate/min_perf_pct" "$min_pct" >/dev/null 2>&1 || true
      for policy in /sys/devices/system/cpu/cpufreq/policy*; do
        [ -d "$policy" ] || continue
        write_if_writable "$policy/energy_performance_preference" "$epp" >/dev/null 2>&1 || true
      done
      set_platform_profile "$platform" >/dev/null 2>&1 || true
    }

    read_cpu_temp_milli() {
      for zone in /sys/class/thermal/thermal_zone*; do
        [ -d "$zone" ] || continue
        [ -f "$zone/type" ] || continue
        [ -f "$zone/temp" ] || continue
        ztype="$(${pkgs.coreutils}/bin/cat "$zone/type" 2>/dev/null || true)"
        case "$ztype" in
          x86_pkg_temp|cpu-thermal|CPU-thermal|soc_thermal|Tctl)
            ${pkgs.coreutils}/bin/cat "$zone/temp" 2>/dev/null || true
            return 0
            ;;
        esac
      done
      ${pkgs.coreutils}/bin/printf '0'
    }

    current_mode=""
    if [ -f "$mode_file" ]; then
      current_mode="$(${pkgs.coreutils}/bin/cat "$mode_file" 2>/dev/null | ${pkgs.coreutils}/bin/tr -d '\r\n')"
    fi
    [ "$current_mode" = "auto" ] || exit 0

    if ! command -v powerprofilesctl >/dev/null 2>&1; then
      exit 0
    fi
    if ! powerprofilesctl list >/dev/null 2>&1; then
      exit 0
    fi

    cpu_line="$(${pkgs.coreutils}/bin/head -n 1 /proc/stat 2>/dev/null)"
    set -- $cpu_line
    user="''${2:-0}"
    nice="''${3:-0}"
    system="''${4:-0}"
    idle="''${5:-0}"
    iowait="''${6:-0}"
    irq="''${7:-0}"
    softirq="''${8:-0}"
    steal="''${9:-0}"

    total_now="$(${pkgs.gawk}/bin/awk -v a="$user" -v b="$nice" -v c="$system" -v d="$idle" -v e="$iowait" -v f="$irq" -v g="$softirq" -v h="$steal" 'BEGIN { printf "%.0f", (a+b+c+d+e+f+g+h) }')"
    idle_now="$(${pkgs.gawk}/bin/awk -v d="$idle" -v e="$iowait" 'BEGIN { printf "%.0f", (d+e) }')"

    disk_io_now="$(${pkgs.gawk}/bin/awk '$3 ~ /^(nvme[0-9]+n[0-9]+|sd[a-z]+|vd[a-z]+)$/ { sum += $13 } END { printf "%.0f", sum + 0 }' /proc/diskstats 2>/dev/null)"
    ts_now="$(date +%s)"

    mem_total_kb="$(${pkgs.gawk}/bin/awk '/^MemTotal:/ { print $2; exit }' /proc/meminfo 2>/dev/null)"
    mem_avail_kb="$(${pkgs.gawk}/bin/awk '/^MemAvailable:/ { print $2; exit }' /proc/meminfo 2>/dev/null)"
    mem_used_pct="$(${pkgs.gawk}/bin/awk -v t="''${mem_total_kb:-0}" -v a="''${mem_avail_kb:-0}" 'BEGIN { if (t <= 0) { print 0; exit } printf "%.2f", ((t-a)*100.0/t) }')"

    gpu_util="0"
    if command -v nvidia-smi >/dev/null 2>&1; then
      gpu_util="$(${pkgs.coreutils}/bin/timeout 0.20s nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null | ${pkgs.coreutils}/bin/head -n 1 | ${pkgs.coreutils}/bin/tr -d '\r\n ' || true)"
      [ -n "$gpu_util" ] || gpu_util="0"
    fi

    prev_total="$(read_kv prev_total "$total_now")"
    prev_idle="$(read_kv prev_idle "$idle_now")"
    prev_disk_io_ms="$(read_kv prev_disk_io_ms "$disk_io_now")"
    prev_ts="$(read_kv prev_ts "$ts_now")"
    heavy_streak="$(read_kv heavy_streak 0)"
    cool_streak="$(read_kv cool_streak 0)"
    current_target="$(read_kv current_target none)"
    prev_power_source="$(read_kv power_source unknown)"

    cpu_usage_pct="$(${pkgs.gawk}/bin/awk -v t1="$prev_total" -v t2="$total_now" -v i1="$prev_idle" -v i2="$idle_now" 'BEGIN {
      dt = t2 - t1;
      di = i2 - i1;
      if (dt <= 0) { print 0; exit }
      busy = dt - di;
      if (busy < 0) busy = 0;
      printf "%.2f", (busy * 100.0 / dt);
    }')"

    dt_sec="$(${pkgs.gawk}/bin/awk -v t1="$prev_ts" -v t2="$ts_now" 'BEGIN { d = t2 - t1; if (d <= 0) d = 1; printf "%.0f", d }')"
    disk_util_pct="$(${pkgs.gawk}/bin/awk -v i1="$prev_disk_io_ms" -v i2="$disk_io_now" -v dt="$dt_sec" 'BEGIN {
      dio = i2 - i1;
      if (dio < 0) dio = 0;
      ms = dt * 1000.0;
      if (ms <= 0) { print 0; exit }
      printf "%.2f", ((dio * 100.0) / ms);
    }')"

    power_source="$(detect_power_source)"
    cpu_temp_milli="$(read_cpu_temp_milli | ${pkgs.coreutils}/bin/head -n 1 | ${pkgs.coreutils}/bin/tr -d '\r\n')"

    is_hot=0
    if ${pkgs.gawk}/bin/awk -v t="''${cpu_temp_milli:-0}" 'BEGIN { exit !(t >= 85000) }'; then
      is_hot=1
    fi

    is_heavy=0
    if ${pkgs.gawk}/bin/awk -v cpu="$cpu_usage_pct" -v mem="$mem_used_pct" -v io="$disk_util_pct" -v gpu="''${gpu_util:-0}" 'BEGIN { exit !(cpu >= 65.0 || mem >= 85.0 || io >= 45.0 || gpu >= 45.0) }'; then
      is_heavy=1
    fi

    is_cool=0
    if ${pkgs.gawk}/bin/awk -v cpu="$cpu_usage_pct" -v mem="$mem_used_pct" -v io="$disk_util_pct" -v gpu="''${gpu_util:-0}" -v hot="$is_hot" 'BEGIN { exit !(hot == 0 && cpu <= 30.0 && mem <= 75.0 && io <= 15.0 && gpu <= 20.0) }'; then
      is_cool=1
    fi

    if [ "$is_heavy" = "1" ] && [ "$is_hot" = "0" ]; then
      heavy_streak=$((heavy_streak + 1))
      cool_streak=0
    elif [ "$is_cool" = "1" ] || [ "$is_hot" = "1" ]; then
      cool_streak=$((cool_streak + 1))
      heavy_streak=0
    else
      # Mixed workload: decay both counters to avoid sticky states.
      if [ "$heavy_streak" -gt 0 ]; then heavy_streak=$((heavy_streak - 1)); fi
      if [ "$cool_streak" -gt 0 ]; then cool_streak=$((cool_streak - 1)); fi
    fi

    base_low="power-saver"
    base_high="balanced"
    case "$power_source" in
      ac)
        base_low="balanced"
        base_high="performance"
        ;;
      ups)
        base_low="balanced"
        base_high="balanced"
        ;;
      battery)
        base_low="power-saver"
        base_high="balanced"
        ;;
    esac

    target="$base_low"
    if [ "$heavy_streak" -ge 2 ] && [ "$is_hot" = "0" ]; then
      target="$base_high"
    fi
    if [ "$cool_streak" -ge 3 ] || [ "$is_hot" = "1" ]; then
      target="$base_low"
    fi

    if [ -z "$current_target" ] || [ "$current_target" = "none" ]; then
      current_target="$target"
    fi

    source_changed=0
    if [ "$power_source" != "$prev_power_source" ]; then
      source_changed=1
    fi

    if [ "$source_changed" = "1" ] || [ "$target" != "$current_target" ]; then
      if powerprofilesctl set "$target" >/dev/null 2>&1; then
        apply_cpu_policy_for_target "$target"
        current_target="$target"
      fi
    fi

    ${pkgs.coreutils}/bin/printf 'prev_total=%s\n' "$total_now" > "$state_file"
    ${pkgs.coreutils}/bin/printf 'prev_idle=%s\n' "$idle_now" >> "$state_file"
    ${pkgs.coreutils}/bin/printf 'prev_disk_io_ms=%s\n' "$disk_io_now" >> "$state_file"
    ${pkgs.coreutils}/bin/printf 'prev_ts=%s\n' "$ts_now" >> "$state_file"
    ${pkgs.coreutils}/bin/printf 'heavy_streak=%s\n' "$heavy_streak" >> "$state_file"
    ${pkgs.coreutils}/bin/printf 'cool_streak=%s\n' "$cool_streak" >> "$state_file"
    ${pkgs.coreutils}/bin/printf 'current_target=%s\n' "$current_target" >> "$state_file"
    ${pkgs.coreutils}/bin/printf 'power_source=%s\n' "$power_source" >> "$state_file"

    ${pkgs.coreutils}/bin/printf 'ok:auto:%s:%s:%s:%s:%s\n' "$power_source" "$current_target" "$cpu_usage_pct" "$mem_used_pct" "$disk_util_pct"
  '';

  qml = {
    imports = [];
    properties = [
      { name = "batteryPopupOpen"; type = "bool"; value = false; }
      { name = "batteryPopupWidth"; type = "real"; value = 360; }
      { name = "batteryPopupHeight"; type = "real"; value = 460; }
      { name = "batteryPopupPosX"; type = "real"; value = 0; }
      { name = "batteryPopupPosY"; type = "real"; value = 0; }
      { name = "batteryActionFeedback"; type = "string"; value = ""; }
      { name = "batteryActionFailed"; type = "bool"; value = false; }
      { name = "batteryAdvancedCollapsed"; type = "bool"; value = true; }
      { name = "batteryThresholdEditing"; type = "bool"; value = false; }
      { name = "batteryStartThresholdValue"; type = "int"; value = 40; }
      { name = "batteryStopThresholdValue"; type = "int"; value = 80; }
    ];
    functions = {
      ensureBatteryPopupBounds = {
        args = [];
        blocks = [
          {
            statements = [
              {
                "if" = {
                  condition = "!panel.screen";
                  "then" = [ { "return" = true; } ];
                };
              }
              {
                assign = {
                  target = "batteryPopupWidth";
                  value = { expr = "Math.max(320, Math.min(Math.max(320, panel.width - 20), batteryPopupWidth))"; };
                };
              }
              {
                assign = {
                  target = "batteryPopupHeight";
                  value = { expr = "Math.max(220, Math.min(Math.max(220, panel.screen.height - 20), batteryPopupHeight))"; };
                };
              }
              {
                assign = {
                  target = "batteryPopupPosX";
                  value = { expr = "Math.max(10, Math.min(Math.max(10, panel.width - batteryPopupWidth - 10), batteryPopupPosX))"; };
                };
              }
              {
                assign = {
                  target = "batteryPopupPosY";
                  value = { expr = "Math.max(panel.height + 8, Math.min(Math.max(panel.height + 8, panel.screen.height - batteryPopupHeight - 10), batteryPopupPosY))"; };
                };
              }
            ];
          }
        ];
      };

      positionPopupUnderBatteryButton = {
        args = [];
        blocks = [
          {
            statements = [
              {
                "if" = {
                  condition = "!panel.screen";
                  "then" = [ { "return" = true; } ];
                };
              }
              {
                assign = {
                  target = "batteryPopupWidth";
                  value = { expr = "Math.max(320, Math.min(Math.max(320, panel.width - 20), Math.min(520, Math.round(panel.screen.width * 0.34))))"; };
                };
              }
              {
                assign = {
                  target = "batteryPopupPosY";
                  value = { expr = "batteryStatusButton.mapToItem(panelRoot, 0, 0).y + batteryStatusButton.height + 8"; };
                };
              }
              {
                assign = {
                  target = "batteryPopupHeight";
                  value = { expr = "Math.max(220, Math.min(Math.max(220, panel.screen.height - batteryPopupPosY - 10), batteryPopupHeight))"; };
                };
              }
              {
                assign = {
                  target = "batteryPopupPosX";
                  value = { expr = "batteryStatusButton.mapToItem(panelRoot, 0, 0).x + batteryStatusButton.width - batteryPopupWidth"; };
                };
              }
              {
                call = {
                  fn = "ensureBatteryPopupBounds";
                };
              }
            ];
          }
        ];
      };

      fitBatteryPopupHeightToContent = {
        args = [ "contentHeight" ];
        blocks = [
          {
            statements = [
              {
                "if" = {
                  condition = "!panel.screen";
                  "then" = [ { "return" = true; } ];
                };
              }
              {
                assign = {
                  target = "batteryPopupHeight";
                  value = { expr = "Math.max(220, Math.min(Math.max(220, panel.screen.height - batteryPopupPosY - 10), contentHeight))"; };
                };
              }
              {
                call = {
                  fn = "ensureBatteryPopupBounds";
                };
              }
            ];
          }
        ];
      };

      refreshBatteryPopup = {
        args = [];
        blocks = [
          {
            statements = [
              {
                call = {
                  fn = "refreshBatteryThresholds";
                };
              }
              {
                "if" = {
                  condition = "batteryDetailsProc.running";
                  "then" = [ { "return" = true; } ];
                };
              }
              {
                assign = {
                  target = "batteryDetailsProc.running";
                  value = true;
                };
              }
            ];
          }
        ];
      };

      refreshBatteryThresholds = {
        args = [];
        blocks = [
          {
            statements = [
              {
                "if" = {
                  condition = "batteryThresholdsProc.running";
                  "then" = [ { "return" = true; } ];
                };
              }
              {
                assign = {
                  target = "batteryThresholdsProc.running";
                  value = true;
                };
              }
            ];
          }
        ];
      };

      stopBatteryRealtime = {
        args = [];
        blocks = [
          {
            statements = [
              {
                assign = {
                  target = "batteryDetailsProc.running";
                  value = false;
                };
              }
              {
                assign = {
                  target = "batteryThresholdsProc.running";
                  value = false;
                };
              }
            ];
          }
        ];
      };

      evaluateAutoProfile = {
        args = [];
        blocks = [
          {
            statements = [
              {
                "if" = {
                  condition = "batteryProfileText.text !== \"auto\"";
                  "then" = [ { "return" = true; } ];
                };
              }
              {
                "if" = {
                  condition = "autoProfileEvalProc.running";
                  "then" = [ { "return" = true; } ];
                };
              }
              {
                assign = {
                  target = "autoProfileEvalProc.running";
                  value = true;
                };
              }
            ];
          }
        ];
      };

      applyPowerProfile = {
        args = [ "profile" ];
        blocks = [
          {
            statements = [
              {
                assign = {
                  target = "batteryActionFeedback";
                  value = { expr = "\"Applying \" + profile + \" profile...\""; };
                };
              }
              {
                assign = {
                  target = "batteryActionFailed";
                  value = false;
                };
              }
              {
                assign = {
                  target = "batteryProfileApplyProc.command";
                  value = [
                    "sh"
                    "-lc"
                    { expr = "\"leviathan-power-profile \" + profile"; }
                  ];
                };
              }
              {
                assign = {
                  target = "batteryProfileApplyProc.running";
                  value = true;
                };
              }
            ];
          }
        ];
      };

      applyChargeThreshold = {
        args = [ "kind" "value" ];
        blocks = [
          {
            statements = [
              {
                assign = {
                  target = "batteryPopupOpen";
                  value = false;
                };
              }
              {
                assign = {
                  target = "batteryActionFeedback";
                  value = { expr = "\"Applying \" + kind + \" threshold...\""; };
                };
              }
              {
                assign = {
                  target = "batteryActionFailed";
                  value = false;
                };
              }
              {
                assign = {
                  target = "batteryThresholdApplyProc.command";
                  value = [
                    "sh"
                    "-lc"
                    { expr = "\"leviathan-battery-threshold \" + kind + \" \" + value"; }
                  ];
                };
              }
              {
                assign = {
                  target = "batteryThresholdApplyProc.running";
                  value = true;
                };
              }
            ];
          }
        ];
      };

      applyChargeThresholdPair = {
        args = [ "startValue" "stopValue" ];
        blocks = [
          {
            statements = [
              {
                assign = {
                  target = "batteryPopupOpen";
                  value = false;
                };
              }
              {
                assign = {
                  target = "batteryActionFeedback";
                  value = "Applying start/stop thresholds...";
                };
              }
              {
                assign = {
                  target = "batteryActionFailed";
                  value = false;
                };
              }
              {
                assign = {
                  target = "batteryThresholdPairApplyProc.command";
                  value = [
                    "sh"
                    "-lc"
                    { expr = "\"leviathan-battery-threshold-pair \" + startValue + \" \" + stopValue"; }
                  ];
                };
              }
              {
                assign = {
                  target = "batteryThresholdPairApplyProc.running";
                  value = true;
                };
              }
            ];
          }
        ];
      };
    };

    processes = [
      {
        id = "batteryProfileApplyProc";
        command = [ "sh" "-lc" "true" ];
        running = false;
        stdoutOnStreamFinished = ''{
                        const value = this.text.trim();
                        if (value.startsWith("ok:")) {
                            panel.batteryActionFailed = false;
                            panel.batteryActionFeedback = value.slice(3).trim();
                            panel.refreshBatteryPopup();
                            return;
                        }

                        if (value.startsWith("error:")) {
                            panel.batteryActionFailed = true;
                            panel.batteryActionFeedback = value.slice(6).trim();
                            return;
                        }

                        panel.batteryActionFailed = false;
                        panel.batteryActionFeedback = value;
                    }'';
      }
      {
        id = "batteryThresholdApplyProc";
        command = [ "sh" "-lc" "true" ];
        running = false;
        stdoutOnStreamFinished = ''{
                        const value = this.text.trim();
                        if (value.startsWith("ok:")) {
                            panel.batteryActionFailed = false;
                            panel.batteryActionFeedback = value.slice(3).trim();
                            panel.refreshBatteryPopup();
                            return;
                        }

                        if (value.startsWith("error:")) {
                            panel.batteryActionFailed = true;
                            panel.batteryActionFeedback = value.slice(6).trim();
                            return;
                        }

                        panel.batteryActionFailed = false;
                        panel.batteryActionFeedback = value;
                    }'';
      }
                {
                id = "batteryThresholdPairApplyProc";
                command = [ "sh" "-lc" "true" ];
                running = false;
                stdoutOnStreamFinished = ''{
                        const value = this.text.trim();
                        if (value.startsWith("ok:")) {
                          panel.batteryActionFailed = false;
                          panel.batteryActionFeedback = value.slice(3).trim();
                          panel.refreshBatteryPopup();
                          return;
                        }

                        if (value.startsWith("error:")) {
                          panel.batteryActionFailed = true;
                          panel.batteryActionFeedback = value.slice(6).trim();
                          return;
                        }

                        panel.batteryActionFailed = false;
                        panel.batteryActionFeedback = value;
                      }'';
                }
      {
        id = "autoProfileEvalProc";
        command = [ "sh" "-lc" "leviathan-auto-profile-eval" ];
        running = false;
        stdoutOnStreamFinished = ''{
                        const value = this.text.trim();
                        if (value.startsWith("ok:auto:")) {
                            panel.refreshBatteryPopup();
                        }
                    }'';
      }
    ];
  };
in
{
  scripts = [
    batterySummaryScript
    batteryInfoScript
    powerProfileScript
    batteryThresholdScript
    batteryThresholdPairScript
    batteryThresholdsInfoScript
    autoProfileEvalScript
  ];

  inherit qml;
  inherit batterySummaryScript batteryInfoScript powerProfileScript batteryThresholdScript batteryThresholdPairScript batteryThresholdsInfoScript autoProfileEvalScript;
}
