use std::sync::Arc;

use crate::domain::{BatteryInfoDto, BatterySummaryDto, CliRequest, CliResponse};
use crate::error::AppResult;
use crate::ports::{BatteryPort, BatteryQueryPort};

pub struct ExecuteCliUseCase {
    port: Arc<dyn BatteryPort>,
}

impl ExecuteCliUseCase {
    pub fn new(port: Arc<dyn BatteryPort>) -> Self {
        Self { port }
    }

    pub fn run(&self, request: &CliRequest) -> AppResult<CliResponse> {
        self.port.execute(request)
    }
}

pub struct GetBatterySummaryUseCase {
    port: Arc<dyn BatteryQueryPort>,
}

impl GetBatterySummaryUseCase {
    pub fn new(port: Arc<dyn BatteryQueryPort>) -> Self {
        Self { port }
    }

    pub fn run(&self) -> AppResult<BatterySummaryDto> {
        self.port.read_summary()
    }
}

pub struct GetBatteryInfoUseCase {
    port: Arc<dyn BatteryQueryPort>,
}

impl GetBatteryInfoUseCase {
    pub fn new(port: Arc<dyn BatteryQueryPort>) -> Self {
        Self { port }
    }

    pub fn run(&self) -> AppResult<BatteryInfoDto> {
        self.port.read_info()
    }
}
