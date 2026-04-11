use std::collections::HashMap;
use std::env;
use std::fs;
use std::io;
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};

pub fn find_battery_path() -> Option<PathBuf> {
    let root = Path::new("/sys/class/power_supply");
    let entries = fs::read_dir(root).ok()?;

    for entry in entries.flatten() {
        let name = entry.file_name();
        let name = name.to_string_lossy();
        if name.starts_with("BAT") {
            return Some(entry.path());
        }
    }

    None
}

pub fn read_trimmed<P: AsRef<Path>>(path: P) -> Option<String> {
    fs::read_to_string(path).ok().map(|v| v.trim().to_string())
}

pub fn read_i64<P: AsRef<Path>>(path: P) -> Option<i64> {
    read_trimmed(path)?.parse::<i64>().ok()
}

pub fn read_first_existing_i64(paths: &[PathBuf]) -> Option<i64> {
    for path in paths {
        if path.exists() {
            return read_i64(path);
        }
    }
    None
}

pub fn first_existing_path(paths: &[PathBuf]) -> Option<PathBuf> {
    paths.iter().find(|p| p.exists()).cloned()
}

pub fn parse_percent(value: Option<&str>) -> Option<u8> {
    let raw = value?.trim();
    let parsed = raw.parse::<i32>().ok()?;
    if (0..=100).contains(&parsed) {
        Some(parsed as u8)
    } else {
        None
    }
}

pub fn write_string(path: &Path, content: &str) -> io::Result<()> {
    fs::write(path, content)
}

pub fn detect_ac_state(status_fallback: &str) -> String {
    let root = Path::new("/sys/class/power_supply");
    let entries = match fs::read_dir(root) {
        Ok(v) => v,
        Err(_) => return infer_ac_from_status(status_fallback),
    };

    let mut saw_supply = false;

    for entry in entries.flatten() {
        let p = entry.path();
        let online = p.join("online");
        if !online.exists() {
            continue;
        }

        let supply_name = entry.file_name().to_string_lossy().to_lowercase();
        let ptype = read_trimmed(p.join("type")).unwrap_or_default();
        let ptype_l = ptype.to_lowercase();

        let is_external_supply = matches!(
            ptype_l.as_str(),
            "mains" | "usb" | "usb_c" | "usb_pd" | "ac" | "adp" | "brickid" | "wireless"
        ) || supply_name.starts_with("ac")
            || supply_name.starts_with("adp")
            || supply_name.starts_with("charger");

        if !is_external_supply {
            continue;
        }

        saw_supply = true;
        let is_online = read_trimmed(online).unwrap_or_else(|| String::from("0")) == "1";
        if is_online {
            return String::from("Connected");
        }
    }

    if saw_supply {
        let inferred = infer_ac_from_status(status_fallback);
        if inferred == "Connected" {
            return inferred;
        }
        return String::from("Disconnected");
    }

    infer_ac_from_status(status_fallback)
}

pub fn infer_ac_from_status(status: &str) -> String {
    match status {
        "Charging" | "Full" | "Not charging" => String::from("Connected"),
        "Discharging" => String::from("Disconnected"),
        _ => String::from("Unknown"),
    }
}

pub fn ppd_available() -> bool {
    Command::new("powerprofilesctl")
        .arg("list")
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .status()
        .map(|s| s.success())
        .unwrap_or(false)
}

pub fn current_ppd_profile() -> Option<String> {
    let out = Command::new("powerprofilesctl")
        .arg("get")
        .output()
        .ok()?;

    if !out.status.success() {
        return None;
    }

    let value = String::from_utf8_lossy(&out.stdout).trim().to_string();
    if value.is_empty() { None } else { Some(value) }
}

pub fn fmt_voltage(u_v: i64) -> String {
    if u_v <= 0 {
        String::from("N/A")
    } else {
        format!("{:.2} V", u_v as f64 / 1_000_000.0)
    }
}

pub fn compute_rate_watts(power_now: i64, current_now: i64, voltage_now: i64) -> String {
    let power_abs = power_now.abs();
    if power_abs > 0 {
        return format!("{:.2} W", power_abs as f64 / 1_000_000.0);
    }

    let current_abs = current_now.abs();
    if current_abs > 0 && voltage_now > 0 {
        let watts = (current_abs as f64 * voltage_now as f64) / 1_000_000_000_000.0;
        return format!("{:.2} W", watts);
    }

    String::from("0.00 W")
}

pub fn estimate_time_remaining(
    status: &str,
    energy_now: i64,
    energy_full: i64,
    charge_now: i64,
    charge_full: i64,
    power_now: i64,
    current_now: i64,
    ac_connected: bool,
) -> String {
    let power_abs = power_now.abs() as f64;
    let current_abs = current_now.abs() as f64;

    let mut hours: Option<f64> = None;

    if status == "Discharging" {
        if energy_now > 0 && power_abs > 0.0 {
            hours = Some(energy_now as f64 / power_abs);
        } else if charge_now > 0 && current_abs > 0.0 {
            hours = Some(charge_now as f64 / current_abs);
        }
        if let Some(h) = hours {
            return fmt_hours(h, "to empty");
        }
        return String::from("Estimating...");
    }

    if status == "Charging" {
        let e_rem = (energy_full - energy_now).max(0);
        let c_rem = (charge_full - charge_now).max(0);
        if e_rem > 0 && power_abs > 0.0 {
            hours = Some(e_rem as f64 / power_abs);
        } else if c_rem > 0 && current_abs > 0.0 {
            hours = Some(c_rem as f64 / current_abs);
        }

        if let Some(h) = hours {
            return fmt_hours(h, "to full");
        }
        return String::from("Estimating...");
    }

    if status == "Not charging" {
        return if ac_connected {
            String::from("Holding (plugged in)")
        } else {
            String::from("Idle")
        };
    }

    if status == "Full" {
        return String::from("At limit");
    }

    String::from("Estimating...")
}

pub fn fmt_hours(hours: f64, suffix: &str) -> String {
    if hours <= 0.0 {
        return String::from("N/A");
    }

    let total_mins = (hours * 60.0).round() as i64;
    let hh = total_mins / 60;
    let mm = total_mins % 60;
    format!("{}h {}m {}", hh, mm, suffix)
}

pub fn read_cpu_temp_milli() -> Option<i64> {
    let preferred = ["x86_pkg_temp", "cpu-thermal", "CPU-thermal", "soc_thermal", "Tctl"];
    read_thermal_zone_by_type(&preferred).or_else(read_any_thermal)
}

pub fn read_gpu_temp_milli() -> Option<i64> {
    let preferred = ["gpu", "amdgpu"];
    read_thermal_zone_prefix(&preferred).or_else(read_nvidia_gpu_temp_milli)
}

pub fn read_nvidia_gpu_temp_milli() -> Option<i64> {
    let out = Command::new("nvidia-smi")
        .args(["--query-gpu=temperature.gpu", "--format=csv,noheader,nounits"])
        .output()
        .ok()?;

    if !out.status.success() {
        return None;
    }

    let raw = String::from_utf8_lossy(&out.stdout);
    let first = raw.lines().next()?.trim();
    let celsius = first.parse::<f64>().ok()?;
    if celsius <= 0.0 {
        return None;
    }

    Some((celsius * 1000.0).round() as i64)
}

pub fn read_thermal_zone_by_type(types: &[&str]) -> Option<i64> {
    let root = Path::new("/sys/class/thermal");
    let entries = fs::read_dir(root).ok()?;

    for entry in entries.flatten() {
        let p = entry.path();
        if !p.file_name()?.to_string_lossy().starts_with("thermal_zone") {
            continue;
        }

        let ztype = read_trimmed(p.join("type"))?;
        if types.iter().any(|t| *t == ztype) {
            return read_i64(p.join("temp"));
        }
    }

    None
}

pub fn read_thermal_zone_prefix(prefixes: &[&str]) -> Option<i64> {
    let root = Path::new("/sys/class/thermal");
    let entries = fs::read_dir(root).ok()?;

    for entry in entries.flatten() {
        let p = entry.path();
        if !p.file_name()?.to_string_lossy().starts_with("thermal_zone") {
            continue;
        }

        let ztype = read_trimmed(p.join("type"))?.to_lowercase();
        if prefixes.iter().any(|pref| ztype.starts_with(pref)) {
            return read_i64(p.join("temp"));
        }
    }

    None
}

pub fn read_any_thermal() -> Option<i64> {
    let root = Path::new("/sys/class/thermal");
    let entries = fs::read_dir(root).ok()?;

    for entry in entries.flatten() {
        let p = entry.path();
        if !p.file_name()?.to_string_lossy().starts_with("thermal_zone") {
            continue;
        }

        if let Some(v) = read_i64(p.join("temp")) {
            return Some(v);
        }
    }

    None
}

pub fn read_max_thermal_zone_temp_milli() -> Option<i64> {
    let root = Path::new("/sys/class/thermal");
    let entries = fs::read_dir(root).ok()?;

    let mut max_temp: Option<i64> = None;
    for entry in entries.flatten() {
        let p = entry.path();
        if !p.file_name()?.to_string_lossy().starts_with("thermal_zone") {
            continue;
        }

        if let Some(v) = read_i64(p.join("temp")) {
            max_temp = Some(match max_temp {
                Some(prev) => prev.max(v),
                None => v,
            });
        }
    }

    max_temp
}

pub fn read_thermal_zone_entries() -> Vec<(u32, String, i64)> {
    let mut out: Vec<(u32, String, i64)> = Vec::new();
    let Ok(entries) = fs::read_dir("/sys/class/thermal") else {
        return out;
    };

    for entry in entries.flatten() {
        let path = entry.path();
        let name = entry.file_name().to_string_lossy().to_string();
        if !name.starts_with("thermal_zone") {
            continue;
        }

        let zone_index = name
            .trim_start_matches("thermal_zone")
            .parse::<u32>()
            .ok()
            .unwrap_or(9999);

        let Some(temp_milli) = read_i64(path.join("temp")) else {
            continue;
        };
        if temp_milli <= 0 {
            continue;
        }

        let raw_label = read_trimmed(path.join("type")).unwrap_or_else(|| format!("zone{}", zone_index));
        out.push((zone_index, raw_label, temp_milli));
    }

    out.sort_by_key(|(idx, _, _)| *idx);
    out
}

pub fn format_thermal_zones_metric(exclude_cpu_milli: Option<i64>, exclude_gpu_milli: Option<i64>) -> String {
    let zones = read_thermal_zone_entries();
    if zones.is_empty() {
        return String::from("N/A");
    }

    zones
        .iter()
        .filter(|(_, raw_label, temp_milli)| {
            let raw_l = raw_label.to_lowercase();

            // Keep ACPI/firmware aggregate sensors even if close to CPU package temp.
            if raw_l == "acpitz" || raw_l == "int3400 thermal" {
                return true;
            }

            let cpu_like = raw_l.contains("cpu")
                || raw_l.contains("pkg")
                || raw_l.contains("tctl")
                || raw_l.contains("tcpu");

            let gpu_like = raw_l.contains("gpu")
                || raw_l.contains("amdgpu")
                || raw_l.contains("nvidia");

            if cpu_like && exclude_cpu_milli.is_some() {
                return false;
            }

            if gpu_like && exclude_gpu_milli.is_some() {
                return false;
            }

            let near_cpu = exclude_cpu_milli
                .map(|cpu| (cpu - *temp_milli).abs() <= 1000)
                .unwrap_or(false);
            if cpu_like && near_cpu {
                return false;
            }

            let near_gpu = exclude_gpu_milli
                .map(|gpu| (gpu - *temp_milli).abs() <= 1000)
                .unwrap_or(false);
            if gpu_like && near_gpu {
                return false;
            }

            true
        })
        .map(|(zone_idx, raw_label, temp_milli)| {
            let friendly = friendly_thermal_label(raw_label, *zone_idx);
            format!("{} - {:.1}°C", friendly, *temp_milli as f64 / 1000.0)
        })
        .collect::<Vec<String>>()
        .join(" | ")
}

pub fn read_fan_rpms() -> Vec<(u32, i64)> {
    let mut out: Vec<(u32, i64)> = Vec::new();

    let Ok(hwmons) = fs::read_dir("/sys/class/hwmon") else {
        return out;
    };

    for hw in hwmons.flatten() {
        let hw_path = hw.path();
        let Ok(entries) = fs::read_dir(&hw_path) else {
            continue;
        };

        for entry in entries.flatten() {
            let file_name = entry.file_name().to_string_lossy().to_string();
            if !file_name.starts_with("fan") || !file_name.ends_with("_input") {
                continue;
            }

            let idx_part = &file_name[3..file_name.len() - 6];
            let Ok(fan_index) = idx_part.parse::<u32>() else {
                continue;
            };

            let Some(rpm) = read_i64(entry.path()) else {
                continue;
            };

            if rpm > 0 {
                out.push((fan_index, rpm));
            }
        }
    }

    out.sort_by_key(|(idx, _)| *idx);
    out
}

pub fn format_fans_metric() -> String {
    let fans = read_fan_rpms();
    if fans.is_empty() {
        return String::from("N/A");
    }

    fans
        .iter()
        .map(|(idx, rpm)| format!("fan{} - {} RPM", idx, rpm))
        .collect::<Vec<String>>()
        .join(" | ")
}

pub fn fmt_temp(temp_milli: Option<i64>) -> String {
    match temp_milli {
        Some(v) if v > 0 => format!("{:.1}°C", v as f64 / 1000.0),
        _ => String::from("N/A"),
    }
}

fn friendly_thermal_label(raw_label: &str, zone_idx: u32) -> String {
    let normalized = raw_label.trim().to_lowercase().replace('_', " ");

    if normalized == "acpitz" {
        return String::from("ACPI");
    }

    if normalized == "int3400 thermal" {
        return String::from("Intel DPTF");
    }

    if normalized.starts_with("sen") {
        let idx = normalized.trim_start_matches("sen").trim();
        if !idx.is_empty() {
            return format!("Sensor {}", idx);
        }
        return String::from("Sensor");
    }

    if normalized.contains("iwlwifi") {
        return String::from("Wi-Fi");
    }

    if normalized.contains("pch") {
        return String::from("Chipset");
    }

    if normalized.contains("gpu") || normalized.contains("amdgpu") || normalized.contains("nvidia") {
        return String::from("GPU hotspot");
    }

    if normalized.contains("cpu") || normalized.contains("pkg") || normalized.contains("tctl") || normalized.contains("tcpu") {
        return String::from("CPU package");
    }

    if normalized.starts_with("zone") {
        return format!("Zone {}", zone_idx);
    }

    raw_label.replace('_', " ")
}

pub fn classify_thermal(temp_milli: Option<i64>) -> &'static str {
    let t = temp_milli.unwrap_or(0);
    if t >= 92_000 {
        "Critical"
    } else if t >= 85_000 {
        "Hot"
    } else if t >= 75_000 {
        "Warm"
    } else if t > 0 {
        "Normal"
    } else {
        "Unknown"
    }
}

pub fn state_root() -> PathBuf {
    if let Ok(path) = env::var("XDG_STATE_HOME") {
        PathBuf::from(path).join("leviathan")
    } else {
        let home = env::var("HOME").unwrap_or_else(|_| String::from("/tmp"));
        PathBuf::from(home).join(".local/state/leviathan")
    }
}

pub fn read_kv_file(path: &Path) -> HashMap<String, String> {
    let mut out = HashMap::new();
    let Ok(content) = fs::read_to_string(path) else {
        return out;
    };

    for line in content.lines() {
        let Some(idx) = line.find('=') else {
            continue;
        };
        let k = line[..idx].trim();
        let v = line[idx + 1..].trim();
        if !k.is_empty() {
            out.insert(String::from(k), String::from(v));
        }
    }

    out
}

pub fn snapshot_path() -> PathBuf {
    if let Ok(dir) = env::var("XDG_RUNTIME_DIR") {
        return PathBuf::from(dir).join("leviathan").join("battery.snapshot");
    }

    PathBuf::from("/tmp").join("leviathan-battery.snapshot")
}

pub fn read_snapshot_map() -> Option<HashMap<String, String>> {
    let path = snapshot_path();
    if !path.exists() {
        return None;
    }

    let content = fs::read_to_string(path).ok()?;
    let mut map = HashMap::new();

    for line in content.lines() {
        let Some(idx) = line.find('=') else {
            continue;
        };
        let key = line[..idx].trim();
        let value = line[idx + 1..].trim();
        if !key.is_empty() {
            map.insert(String::from(key), String::from(value));
        }
    }

    if map.is_empty() {
        None
    } else {
        Some(map)
    }
}

pub fn write_snapshot_map(map: &HashMap<String, String>) -> io::Result<()> {
    let path = snapshot_path();

    if let Some(parent) = path.parent() {
        fs::create_dir_all(parent)?;
    }

    let mut keys: Vec<&String> = map.keys().collect();
    keys.sort();

    let mut out = String::new();
    for key in keys {
        if let Some(value) = map.get(key) {
            out.push_str(&format!("{}={}\n", key, value));
        }
    }

    let tmp = path.with_extension("tmp");
    fs::write(&tmp, out)?;
    fs::rename(tmp, path)?;
    Ok(())
}

pub fn sync_profile_to_snapshot(profile: &str) {
    let mut snapshot = read_snapshot_map().unwrap_or_default();
    snapshot.insert(String::from("PROFILE"), String::from(profile));
    let _ = write_snapshot_map(&snapshot);
}

pub fn apply_cpu_policy(mode: &str, ac_connected: bool) {
    let (max_pct, min_pct, epp, platform) = match mode {
        "power-saver" => ("70", "20", "balance_power", "low-power"),
        "balanced" => ("85", "25", "balance_performance", "balanced"),
        "performance" => ("92", "30", "balance_performance", "balanced"),
        "turbo" => ("100", "35", "performance", "performance"),
        "auto" => {
            if ac_connected {
                ("88", "28", "balance_performance", "balanced")
            } else {
                ("80", "22", "balance_power", "balanced")
            }
        }
        _ => ("85", "25", "balance_performance", "balanced"),
    };

    let _ = write_if_writable("/sys/devices/system/cpu/intel_pstate/max_perf_pct", max_pct);
    let _ = write_if_writable("/sys/devices/system/cpu/intel_pstate/min_perf_pct", min_pct);

    if let Ok(entries) = fs::read_dir("/sys/devices/system/cpu/cpufreq") {
        for entry in entries.flatten() {
            let p = entry.path();
            let name = entry.file_name().to_string_lossy().to_string();
            if !name.starts_with("policy") {
                continue;
            }
            let _ = write_if_writable(p.join("energy_performance_preference"), epp);
        }
    }

    let _ = set_platform_profile(platform);
}

pub fn write_if_writable<P: AsRef<Path>>(path: P, value: &str) -> io::Result<()> {
    let path = path.as_ref();
    let meta = fs::metadata(path)?;
    if meta.permissions().readonly() {
        return Err(io::Error::new(io::ErrorKind::PermissionDenied, "readonly"));
    }
    fs::write(path, format!("{}\n", value))
}

pub fn set_platform_profile(value: &str) -> io::Result<()> {
    let profile = Path::new("/sys/firmware/acpi/platform_profile");
    let choices = Path::new("/sys/firmware/acpi/platform_profile_choices");

    if choices.exists() {
        let opts = read_trimmed(choices).unwrap_or_default();
        if !opts.split_whitespace().any(|v| v == value) {
            return Err(io::Error::new(io::ErrorKind::InvalidInput, "profile not available"));
        }
    }

    write_if_writable(profile, value)
}

pub fn try_pkexec_write(path: &Path, values: &[String]) -> bool {
    let mut cmd = Command::new("pkexec");
    cmd.arg("sh")
        .arg("-c")
        .arg("printf '%s\\n' \"$1\" > \"$2\"")
        .arg("_")
        .arg(values.get(0).map(String::as_str).unwrap_or(""))
        .arg(path.to_string_lossy().as_ref());

    cmd.status().map(|s| s.success()).unwrap_or(false)
}

pub fn try_pkexec_write_pair(start_path: &Path, stop_path: &Path, start: u8, stop: u8) -> bool {
    Command::new("pkexec")
        .arg("sh")
        .arg("-c")
        .arg("printf '%s\\n' \"$1\" > \"$3\" && printf '%s\\n' \"$2\" > \"$4\"")
        .arg("_")
        .arg(start.to_string())
        .arg(stop.to_string())
        .arg(start_path.to_string_lossy().as_ref())
        .arg(stop_path.to_string_lossy().as_ref())
        .status()
        .map(|s| s.success())
        .unwrap_or(false)
}
