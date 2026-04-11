use std::sync::Arc;
use std::thread;

use crate::domain::{BatteryInfoDto, BatterySummaryDto, CliRequest, CliResponse};
use crate::error::{AppError, AppResult};
use crate::ports::{BatteryPort, BatteryQueryPort};

pub struct LegacyBatteryPort;

impl BatteryPort for LegacyBatteryPort {
    fn execute(&self, request: &CliRequest) -> AppResult<CliResponse> {
        crate::legacy::dispatch_entry(&request.executable, &request.args)
            .map_err(AppError::Execution)?;
        Ok(CliResponse::ok())
    }
}

pub struct SysBatteryQueryPort;

impl BatteryQueryPort for SysBatteryQueryPort {
    fn read_summary(&self) -> AppResult<BatterySummaryDto> {
        if !bypass_snapshot_read() {
            if let Some(snapshot) = crate::legacy::shared::read_snapshot_map() {
                let status = snapshot
                    .get("STATUS")
                    .cloned()
                    .unwrap_or_else(|| String::from("Unknown"));
                let capacity = snapshot
                    .get("CAPACITY")
                    .and_then(|v| v.parse::<i64>().ok())
                    .unwrap_or(0);
                return Ok(BatterySummaryDto { status, capacity });
            }
        }

        let Some(bat) = crate::legacy::shared::find_battery_path() else {
            return Ok(BatterySummaryDto {
                status: String::from("Unknown"),
                capacity: 0,
            });
        };

        let status = crate::legacy::shared::read_trimmed(bat.join("status"))
            .unwrap_or_else(|| String::from("Unknown"));
        let capacity = crate::legacy::shared::read_i64(bat.join("capacity")).unwrap_or(0);

        Ok(BatterySummaryDto { status, capacity })
    }

    fn read_info(&self) -> AppResult<BatteryInfoDto> {
        if !bypass_snapshot_read() {
            if let Some(snapshot) = crate::legacy::shared::read_snapshot_map() {
                return Ok(BatteryInfoDto {
                    status: snapshot
                        .get("STATUS")
                        .cloned()
                        .unwrap_or_else(|| String::from("Unknown")),
                    capacity: snapshot
                        .get("CAPACITY")
                        .and_then(|v| v.parse::<i64>().ok())
                        .unwrap_or(0),
                    profile: snapshot
                        .get("PROFILE")
                        .cloned()
                        .unwrap_or_else(|| String::from("N/A")),
                    voltage: snapshot
                        .get("VOLTAGE")
                        .cloned()
                        .unwrap_or_else(|| String::from("N/A")),
                    cycles: snapshot
                        .get("CYCLES")
                        .cloned()
                        .unwrap_or_else(|| String::from("N/A")),
                    rate: snapshot
                        .get("RATE")
                        .cloned()
                        .unwrap_or_else(|| String::from("N/A")),
                    time_remaining: snapshot
                        .get("TIME_REMAINING")
                        .cloned()
                        .unwrap_or_else(|| String::from("N/A")),
                    ac_state: snapshot
                        .get("AC_STATE")
                        .cloned()
                        .unwrap_or_else(|| String::from("Unknown")),
                    cpu_temp: snapshot
                        .get("CPU_TEMP")
                        .cloned()
                        .unwrap_or_else(|| String::from("N/A")),
                    gpu_temp: snapshot
                        .get("GPU_TEMP")
                        .cloned()
                        .unwrap_or_else(|| String::from("N/A")),
                    fans: snapshot
                        .get("FANS")
                        .cloned()
                        .unwrap_or_else(|| String::from("N/A")),
                    thermal_zones: snapshot
                        .get("THERMAL_ZONES")
                        .cloned()
                        .unwrap_or_else(|| String::from("N/A")),
                    thermal_state: snapshot
                        .get("THERMAL_STATE")
                        .cloned()
                        .unwrap_or_else(|| String::from("Unknown")),
                    auto_target: snapshot
                        .get("AUTO_TARGET")
                        .cloned()
                        .unwrap_or_else(|| String::from("N/A")),
                    auto_source: snapshot
                        .get("AUTO_SOURCE")
                        .cloned()
                        .unwrap_or_else(|| String::from("N/A")),
                    backend: snapshot
                        .get("BACKEND")
                        .cloned()
                        .unwrap_or_else(|| String::from("ppd:off | sysfs:off")),
                    start_threshold: snapshot
                        .get("START_THRESHOLD")
                        .and_then(|v| v.parse::<i64>().ok())
                        .unwrap_or(-1),
                    stop_threshold: snapshot
                        .get("STOP_THRESHOLD")
                        .and_then(|v| v.parse::<i64>().ok())
                        .unwrap_or(-1),
                });
            }
        }

        let Some(bat) = crate::legacy::shared::find_battery_path() else {
            let ppd_state = if crate::legacy::shared::ppd_available() {
                "on"
            } else {
                "off"
            };
            return Ok(BatteryInfoDto {
                status: String::from("No battery"),
                capacity: 0,
                profile: String::from("N/A"),
                voltage: String::from("N/A"),
                cycles: String::from("N/A"),
                rate: String::from("N/A"),
                time_remaining: String::from("N/A"),
                ac_state: String::from("N/A"),
                cpu_temp: String::from("N/A"),
                gpu_temp: String::from("N/A"),
                fans: crate::legacy::shared::format_fans_metric(),
                thermal_zones: crate::legacy::shared::format_thermal_zones_metric(None, None),
                thermal_state: String::from("Unknown"),
                auto_target: String::from("N/A"),
                auto_source: String::from("N/A"),
                backend: format!("ppd:{} | sysfs:off", ppd_state),
                start_threshold: -1,
                stop_threshold: -1,
            });
        };

        let status = crate::legacy::shared::read_trimmed(bat.join("status"))
            .unwrap_or_else(|| String::from("Unknown"));
        let capacity = crate::legacy::shared::read_i64(bat.join("capacity")).unwrap_or(0);
        let voltage_now = crate::legacy::shared::read_i64(bat.join("voltage_now")).unwrap_or(0);
        let current_now = crate::legacy::shared::read_i64(bat.join("current_now")).unwrap_or(0);
        let power_now = crate::legacy::shared::read_i64(bat.join("power_now")).unwrap_or(0);
        let cycle_count = crate::legacy::shared::read_trimmed(bat.join("cycle_count"))
            .unwrap_or_else(|| String::from("N/A"));
        let energy_now = crate::legacy::shared::read_i64(bat.join("energy_now")).unwrap_or(0);
        let energy_full = crate::legacy::shared::read_i64(bat.join("energy_full")).unwrap_or(0);
        let charge_now = crate::legacy::shared::read_i64(bat.join("charge_now")).unwrap_or(0);
        let charge_full = crate::legacy::shared::read_i64(bat.join("charge_full")).unwrap_or(0);

        let start_threshold = crate::legacy::shared::read_first_existing_i64(&[
            bat.join("charge_control_start_threshold"),
            bat.join("charge_start_threshold"),
        ])
        .unwrap_or(-1);

        let stop_threshold = crate::legacy::shared::read_first_existing_i64(&[
            bat.join("charge_control_end_threshold"),
            bat.join("charge_stop_threshold"),
        ])
        .unwrap_or(-1);

        let ac_state = crate::legacy::shared::detect_ac_state(&status);

        let state_root = crate::legacy::shared::state_root();
        let mode_file = state_root.join("power-profile-mode");
        let auto_state_file = state_root.join("auto-profile.state");

        let mut profile = crate::legacy::shared::current_ppd_profile().unwrap_or_else(|| {
            crate::legacy::shared::read_trimmed("/sys/firmware/acpi/platform_profile")
                .unwrap_or_else(|| String::from("auto"))
        });

        if let Some(mode) = crate::legacy::shared::read_trimmed(&mode_file) {
            if mode == "auto" || mode == "turbo" {
                profile = mode;
            }
        }

        let mut auto_target = String::from("N/A");
        let mut auto_source = String::from("N/A");
        if profile == "auto" {
            let st = crate::legacy::shared::read_kv_file(&auto_state_file);
            auto_target = st
                .get("current_target")
                .cloned()
                .unwrap_or_else(|| String::from("N/A"));
            auto_source = match st.get("power_source").map(String::as_str) {
                Some("ac") => String::from("AC"),
                Some("ups") => String::from("UPS"),
                Some("battery") => String::from("Battery"),
                Some(other) => String::from(other),
                None => String::from("N/A"),
            };
        }

        let rate = crate::legacy::shared::compute_rate_watts(power_now, current_now, voltage_now);
        let time_remaining = crate::legacy::shared::estimate_time_remaining(
            &status,
            energy_now,
            energy_full,
            charge_now,
            charge_full,
            power_now,
            current_now,
            ac_state == "Connected",
        );

        let cpu_handle = thread::spawn(crate::legacy::shared::read_cpu_temp_milli);
        let gpu_handle = thread::spawn(crate::legacy::shared::read_gpu_temp_milli);
        let system_thermal_handle = thread::spawn(crate::legacy::shared::read_max_thermal_zone_temp_milli);
        let cpu_temp_milli = cpu_handle.join().unwrap_or(None);
        let gpu_temp_milli = gpu_handle.join().unwrap_or(None);
        let system_thermal_milli = system_thermal_handle.join().unwrap_or(None);

        let cpu_temp = crate::legacy::shared::fmt_temp(cpu_temp_milli);
        let gpu_temp = crate::legacy::shared::fmt_temp(gpu_temp_milli);
        let fans = crate::legacy::shared::format_fans_metric();
        let thermal_zones = crate::legacy::shared::format_thermal_zones_metric(cpu_temp_milli, gpu_temp_milli);
        let thermal_probe = match (cpu_temp_milli, gpu_temp_milli, system_thermal_milli) {
            (Some(cpu), Some(gpu), Some(sys)) => Some(cpu.max(gpu).max(sys)),
            (Some(cpu), Some(gpu), None) => Some(cpu.max(gpu)),
            (Some(cpu), None, Some(sys)) => Some(cpu.max(sys)),
            (None, Some(gpu), Some(sys)) => Some(gpu.max(sys)),
            (Some(cpu), None, None) => Some(cpu),
            (None, Some(gpu), None) => Some(gpu),
            (None, None, Some(sys)) => Some(sys),
            (None, None, None) => None,
        };
        let thermal_state = String::from(crate::legacy::shared::classify_thermal(thermal_probe));

        let ppd_state = if crate::legacy::shared::ppd_available() {
            "on"
        } else {
            "off"
        };
        let sysfs_state = if start_threshold >= 0 || stop_threshold >= 0 {
            "on"
        } else {
            "off"
        };

        Ok(BatteryInfoDto {
            status,
            capacity,
            profile,
            voltage: crate::legacy::shared::fmt_voltage(voltage_now),
            cycles: cycle_count,
            rate,
            time_remaining,
            ac_state,
            cpu_temp,
            gpu_temp,
            fans,
            thermal_zones,
            thermal_state,
            auto_target,
            auto_source,
            backend: format!("ppd:{} | sysfs:{}", ppd_state, sysfs_state),
            start_threshold,
            stop_threshold,
        })
    }
}

pub fn render_summary_to_stdout(summary: &BatterySummaryDto) {
    println!("STATUS={}", summary.status);
    println!("CAPACITY={}", summary.capacity);
}

pub fn render_info_to_stdout(info: &BatteryInfoDto) {
    println!("STATUS={}", info.status);
    println!("CAPACITY={}", info.capacity);
    println!("PROFILE={}", info.profile);
    println!("VOLTAGE={}", info.voltage);
    println!("CYCLES={}", info.cycles);
    println!("RATE={}", info.rate);
    println!("TIME_REMAINING={}", info.time_remaining);
    println!("AC_STATE={}", info.ac_state);
    println!("CPU_TEMP={}", info.cpu_temp);
    println!("GPU_TEMP={}", info.gpu_temp);
    println!("FANS={}", info.fans);
    println!("THERMAL_ZONES={}", info.thermal_zones);
    println!("THERMAL_STATE={}", info.thermal_state);
    println!("AUTO_TARGET={}", info.auto_target);
    println!("AUTO_SOURCE={}", info.auto_source);
    println!("BACKEND={}", info.backend);
    println!("START_THRESHOLD={}", info.start_threshold);
    println!("STOP_THRESHOLD={}", info.stop_threshold);
}

pub fn read_info_via_usecase() -> AppResult<BatteryInfoDto> {
    let port: Arc<dyn BatteryQueryPort> = Arc::new(SysBatteryQueryPort);
    let usecase = crate::usecases::GetBatteryInfoUseCase::new(port);
    usecase.run()
}

pub fn read_summary_via_usecase() -> AppResult<BatterySummaryDto> {
    let port: Arc<dyn BatteryQueryPort> = Arc::new(SysBatteryQueryPort);
    let usecase = crate::usecases::GetBatterySummaryUseCase::new(port);
    usecase.run()
}

fn bypass_snapshot_read() -> bool {
    matches!(
        std::env::var("LEVIATHAN_BATTERY_BYPASS_SNAPSHOT")
            .ok()
            .as_deref(),
        Some("1") | Some("true") | Some("yes") | Some("on")
    )
}
