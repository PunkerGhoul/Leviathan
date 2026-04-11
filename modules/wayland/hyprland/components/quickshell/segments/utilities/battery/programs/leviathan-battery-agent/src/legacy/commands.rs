use std::fs;
use std::process::{Command, Stdio};

use super::shared::*;

pub fn cmd_battery_summary() -> Result<(), String> {
    let summary = crate::infrastructure::read_summary_via_usecase()
        .map_err(|e| e.to_string())?;
    crate::infrastructure::render_summary_to_stdout(&summary);
    Ok(())
}

pub fn cmd_battery_info() -> Result<(), String> {
    let info = crate::infrastructure::read_info_via_usecase()
        .map_err(|e| e.to_string())?;
    crate::infrastructure::render_info_to_stdout(&info);
    Ok(())
}

pub fn cmd_thresholds_info() -> Result<(), String> {
    if let Some(snapshot) = read_snapshot_map() {
        let start = snapshot
            .get("START_THRESHOLD")
            .cloned()
            .unwrap_or_else(|| String::from("-1"));
        let stop = snapshot
            .get("STOP_THRESHOLD")
            .cloned()
            .unwrap_or_else(|| String::from("-1"));

        println!("START_THRESHOLD={}", start);
        println!("STOP_THRESHOLD={}", stop);
        return Ok(());
    }

    let Some(bat) = find_battery_path() else {
        println!("START_THRESHOLD=-1");
        println!("STOP_THRESHOLD=-1");
        return Ok(());
    };

    let start = read_first_existing_i64(&[
        bat.join("charge_control_start_threshold"),
        bat.join("charge_start_threshold"),
    ])
    .unwrap_or(-1);

    let stop = read_first_existing_i64(&[
        bat.join("charge_control_end_threshold"),
        bat.join("charge_stop_threshold"),
    ])
    .unwrap_or(-1);

    println!("START_THRESHOLD={}", start);
    println!("STOP_THRESHOLD={}", stop);
    Ok(())
}

pub fn cmd_power_profile(profile: Option<&str>) -> Result<(), String> {
    let profile = profile.unwrap_or("").trim();
    if !matches!(profile, "power-saver" | "balanced" | "performance" | "auto" | "turbo") {
        println!("error:Invalid profile (use auto, power-saver, balanced, performance, turbo)");
        return Ok(());
    }

    let ac = detect_ac_state("Unknown");
    if profile == "turbo" && ac != "Connected" {
        println!("error:Turbo requires AC power");
        return Ok(());
    }

    if !ppd_available() {
        println!("error:power-profiles-daemon is not active");
        return Ok(());
    }

    let ppd_target = match profile {
        "auto" => {
            if ac == "Connected" {
                "balanced"
            } else {
                "power-saver"
            }
        }
        "turbo" => "performance",
        other => other,
    };

    let set_status = Command::new("powerprofilesctl")
        .arg("set")
        .arg(ppd_target)
        .stdout(Stdio::null())
        .stderr(Stdio::piped())
        .output();

    let Ok(out) = set_status else {
        println!("error:powerprofilesctl is not installed");
        return Ok(());
    };

    if !out.status.success() {
        let msg = String::from_utf8_lossy(&out.stderr).trim().to_string();
        println!("error:{}", if msg.is_empty() { "Failed to set power profile" } else { &msg });
        return Ok(());
    }

    apply_cpu_policy(profile, ac == "Connected");

    let state_root = state_root();
    let _ = fs::create_dir_all(&state_root);
    let _ = fs::write(state_root.join("power-profile-mode"), format!("{}\n", profile));
    let _ = fs::write(state_root.join("power-profile-stable"), format!("{}\n", profile));

    sync_profile_to_snapshot(profile);

    if profile == "auto" {
        println!("ok:Auto applied: {} ({})", ppd_target, if ac == "Connected" { "connected" } else { "battery" });
    } else if profile == "turbo" {
        println!("ok:Turbo enabled (AC): performance");
    } else {
        println!("ok:Profile set to {}", ppd_target);
    }

    Ok(())
}

pub fn cmd_threshold(kind: Option<&str>, value: Option<&str>) -> Result<(), String> {
    let kind = kind.unwrap_or("");
    let value = match parse_percent(value) {
        Some(v) => v,
        None => {
            println!("error:Threshold must be a number between 0 and 100");
            return Ok(());
        }
    };

    if kind != "start" && kind != "stop" {
        println!("error:Invalid threshold kind (start or stop)");
        return Ok(());
    }

    let Some(bat) = find_battery_path() else {
        println!("error:Battery not found");
        return Ok(());
    };

    let path = if kind == "start" {
        first_existing_path(&[
            bat.join("charge_control_start_threshold"),
            bat.join("charge_start_threshold"),
        ])
    } else {
        first_existing_path(&[
            bat.join("charge_control_end_threshold"),
            bat.join("charge_stop_threshold"),
        ])
    };

    let Some(path) = path else {
        println!("error:Charge threshold is not supported on this battery");
        return Ok(());
    };

    if write_string(&path, &format!("{}\n", value)).is_ok() {
        println!("ok:Updated {} threshold to {}%", kind, value);
        return Ok(());
    }

    if try_pkexec_write(&path, &[value.to_string()]) {
        println!("ok:Updated {} threshold to {}%", kind, value);
    } else {
        println!("error:Authorization failed or write denied");
    }

    Ok(())
}

pub fn cmd_threshold_pair(start: Option<&str>, stop: Option<&str>) -> Result<(), String> {
    let start = match parse_percent(start) {
        Some(v) => v,
        None => {
            println!("error:Start threshold must be a number between 0 and 100");
            return Ok(());
        }
    };

    let stop = match parse_percent(stop) {
        Some(v) => v,
        None => {
            println!("error:Stop threshold must be a number between 0 and 100");
            return Ok(());
        }
    };

    if start > stop.saturating_sub(5) {
        println!("error:Start must be at most Stop - 5");
        return Ok(());
    }

    let Some(bat) = find_battery_path() else {
        println!("error:Battery not found");
        return Ok(());
    };

    let start_path = first_existing_path(&[
        bat.join("charge_control_start_threshold"),
        bat.join("charge_start_threshold"),
    ]);
    let stop_path = first_existing_path(&[
        bat.join("charge_control_end_threshold"),
        bat.join("charge_stop_threshold"),
    ]);

    let (Some(start_path), Some(stop_path)) = (start_path, stop_path) else {
        println!("error:Charge thresholds are not supported on this battery");
        return Ok(());
    };

    if write_string(&start_path, &format!("{}\n", start)).is_ok() && write_string(&stop_path, &format!("{}\n", stop)).is_ok() {
        println!("ok:Updated thresholds: start={}% stop={}%", start, stop);
        return Ok(());
    }

    if try_pkexec_write_pair(&start_path, &stop_path, start, stop) {
        println!("ok:Updated thresholds: start={}% stop={}%", start, stop);
    } else {
        println!("error:Authorization failed or write denied");
    }

    Ok(())
}

pub fn cmd_auto_profile_eval() -> Result<(), String> {
    let state_root = state_root();
    let mode_file = state_root.join("power-profile-mode");
    let state_file = state_root.join("auto-profile.state");

    let mode = read_trimmed(&mode_file).unwrap_or_default();
    if mode != "auto" {
        return Ok(());
    }

    if !ppd_available() {
        return Ok(());
    }

    let source = if detect_ac_state("Unknown") == "Connected" { "ac" } else { "battery" };
    let cpu_temp = read_cpu_temp_milli();
    let hot = cpu_temp.unwrap_or(0) >= 85_000;

    let target = match (source, hot) {
        ("ac", false) => "performance",
        ("ac", true) => "balanced",
        ("battery", _) => "power-saver",
        _ => "balanced",
    };

    let _ = Command::new("powerprofilesctl").arg("set").arg(target).status();
    apply_cpu_policy(target, source == "ac");

    let _ = fs::create_dir_all(&state_root);
    let state = format!("current_target={}\npower_source={}\n", target, source);
    let _ = fs::write(&state_file, state);

    println!("ok:auto:{}:{}:0:0:0", source, target);
    Ok(())
}
