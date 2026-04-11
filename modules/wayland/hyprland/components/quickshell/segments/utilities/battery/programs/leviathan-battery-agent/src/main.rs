use std::env;
use std::path::Path;
use std::sync::Arc;

mod domain;
mod error;
mod infrastructure;
mod legacy;
mod monitor;
mod normalizer;
mod ports;
mod roller;
mod usecases;

fn main() {
    let args: Vec<String> = env::args().collect();
    let executable = Path::new(args.get(0).map(String::as_str).unwrap_or(""))
        .file_name()
        .and_then(|s| s.to_str())
        .unwrap_or("")
        .to_string();

    let request = domain::CliRequest { executable, args };

    let port: Arc<dyn ports::BatteryPort> = Arc::new(infrastructure::LegacyBatteryPort);
    let usecase = usecases::ExecuteCliUseCase::new(port);

    if let Err(err) = usecase.run(&request) {
        eprintln!("{}", err);
    }
}
