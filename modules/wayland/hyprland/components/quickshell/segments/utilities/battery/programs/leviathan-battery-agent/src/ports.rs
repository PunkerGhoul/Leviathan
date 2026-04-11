use crate::domain::{BatteryInfoDto, BatterySummaryDto, CliRequest, CliResponse};
use crate::error::AppResult;

/// Boundary for command execution.
///
/// Contract: execute the requested CLI command and return a typed success/failure result.
pub trait BatteryPort: Send + Sync {
    fn execute(&self, request: &CliRequest) -> AppResult<CliResponse>;
}

/// Boundary for battery telemetry reads used by application query use cases.
pub trait BatteryQueryPort: Send + Sync {
    fn read_summary(&self) -> AppResult<BatterySummaryDto>;
    fn read_info(&self) -> AppResult<BatteryInfoDto>;
}
