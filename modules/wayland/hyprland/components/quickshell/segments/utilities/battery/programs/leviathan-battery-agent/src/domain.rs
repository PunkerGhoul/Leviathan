use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CliRequest {
    pub executable: String,
    pub args: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CliResponse {
    pub success: bool,
}

impl CliResponse {
    pub fn ok() -> Self {
        Self { success: true }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BatterySummaryDto {
    pub status: String,
    pub capacity: i64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BatteryInfoDto {
    pub status: String,
    pub capacity: i64,
    pub profile: String,
    pub voltage: String,
    pub cycles: String,
    pub rate: String,
    pub time_remaining: String,
    pub ac_state: String,
    pub cpu_temp: String,
    pub gpu_temp: String,
    pub fans: String,
    pub thermal_zones: String,
    pub thermal_state: String,
    pub auto_target: String,
    pub auto_source: String,
    pub backend: String,
    pub start_threshold: i64,
    pub stop_threshold: i64,
}
