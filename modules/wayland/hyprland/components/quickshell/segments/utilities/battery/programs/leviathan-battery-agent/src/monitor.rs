use std::io::{BufRead, BufReader};
use std::process::{Command, Stdio};
use std::sync::mpsc::{self, Receiver, Sender};
use std::thread;

#[derive(Debug, Clone)]
pub enum MonitorEvent {
    BatterySignal,
    ProfileSignal,
}

pub struct Monitor {
    rx: Receiver<MonitorEvent>,
}

impl Monitor {
    pub fn start() -> Result<Self, String> {
        let (tx, rx) = mpsc::channel::<MonitorEvent>();

        spawn_udev_listener(tx.clone())?;
        spawn_ppd_listener(tx)?;

        Ok(Self { rx })
    }

    pub fn recv(&self) -> Option<MonitorEvent> {
        self.rx.recv().ok()
    }
}

fn spawn_udev_listener(tx: Sender<MonitorEvent>) -> Result<(), String> {
    spawn_line_listener(
        "udevadm",
        &["monitor", "--kernel", "--udev", "--subsystem-match=power_supply"],
        move |line| {
            if line.contains("power_supply") || line.contains("POWER_SUPPLY") {
                let _ = tx.send(MonitorEvent::BatterySignal);
            }
        },
    )
}

fn spawn_ppd_listener(tx: Sender<MonitorEvent>) -> Result<(), String> {
    spawn_line_listener(
        "dbus-monitor",
        &[
            "--system",
            "type='signal',sender='net.hadess.PowerProfiles'",
        ],
        move |line| {
            if line.contains("signal") {
                let _ = tx.send(MonitorEvent::ProfileSignal);
            }
        },
    )
}

fn spawn_line_listener<F>(program: &str, args: &[&str], mut on_line: F) -> Result<(), String>
where
    F: FnMut(&str) + Send + 'static,
{
    let mut child = Command::new(program)
        .args(args)
        .stdout(Stdio::piped())
        .stderr(Stdio::null())
        .spawn()
        .map_err(|e| format!("failed to spawn {}: {}", program, e))?;

    let Some(stdout) = child.stdout.take() else {
        return Err(format!("{} did not provide stdout", program));
    };

    thread::spawn(move || {
        let reader = BufReader::new(stdout);
        for line in reader.lines().map_while(Result::ok) {
            on_line(&line);
        }

        let _ = child.wait();
    });

    Ok(())
}
