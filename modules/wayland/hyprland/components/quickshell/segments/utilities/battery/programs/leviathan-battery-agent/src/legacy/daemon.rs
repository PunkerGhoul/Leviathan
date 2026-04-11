use std::path::Path;
use std::process::Command;

pub fn cmd_event_monitor_daemon(args: &[String]) -> Result<(), String> {
    let exe_path = std::env::current_exe().map_err(|e| format!("failed to resolve current exe: {}", e))?;

    let mut roller = crate::roller::Roller::new();

    // Initial snapshot bootstrap on startup; afterwards only event-driven updates.
    let initial = collect_info_via_agent(&exe_path)?;
    let _ = roller.apply_raw_snapshot(&initial).map_err(|e| format!("roller write failed: {}", e))?;

    let monitor = crate::monitor::Monitor::start()?;

    loop {
        let _event = monitor.recv().ok_or_else(|| String::from("monitor channel closed"))?;
        let latest = collect_info_via_agent(&exe_path)?;
        let _ = roller.apply_raw_snapshot(&latest).map_err(|e| format!("roller write failed: {}", e))?;
    }
}

pub fn collect_info_via_agent(exe_path: &Path) -> Result<String, String> {
    let output = Command::new(exe_path)
        .env("LEVIATHAN_BATTERY_BYPASS_SNAPSHOT", "1")
        .arg("info")
        .output()
        .map_err(|e| format!("failed to execute info command: {}", e))?;

    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr).trim().to_string();
        return Err(if stderr.is_empty() {
            String::from("info command failed")
        } else {
            format!("info command failed: {}", stderr)
        });
    }

    Ok(String::from_utf8_lossy(&output.stdout).to_string())
}
