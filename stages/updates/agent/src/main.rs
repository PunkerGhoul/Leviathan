use libc::{geteuid, gethostname, getpwuid, getuid};
use std::env;
use std::fs::{self, OpenOptions};
use std::ffi::CStr;
use std::io::Write;
use std::os::unix::fs::PermissionsExt;
use std::path::Path;
use std::process::{Command, ExitCode};
use std::time::{SystemTime, UNIX_EPOCH};

struct Config {
    cache_file: String,
    hostname: String,
    username: String,
}

fn parse_args() -> Result<Config, String> {
    let mut cache_file = String::new();

    let mut args = env::args().skip(1);
    while let Some(arg) = args.next() {
        match arg.as_str() {
            "--cache-file" => {
                cache_file = args
                    .next()
                    .ok_or_else(|| String::from("--cache-file requiere un valor"))?;
            }
            "--help" | "-h" => {
                println!("Uso: leviathan-updates-agent --cache-file <ruta>");
                return Err(String::new());
            }
            _ => return Err(format!("Argumento no reconocido: {arg}")),
        }
    }

    if cache_file.is_empty() {
        return Err(String::from("Debe proporcionar --cache-file"));
    }

    Ok(Config {
        cache_file,
        hostname: get_hostname(),
        username: get_username(),
    })
}

fn get_username() -> String {
    unsafe {
        let uid = getuid();
        let pw = getpwuid(uid);

        if pw.is_null() {
            return String::from("unknown");
        }

        let name = CStr::from_ptr((*pw).pw_name);
        name.to_string_lossy().into_owned()
    }
}

fn get_hostname() -> String {
    let mut buf = [0u8; 256];

    unsafe {
        if gethostname(buf.as_mut_ptr() as *mut i8, buf.len()) == 0 {
            let cstr = CStr::from_ptr(buf.as_ptr() as *const i8);
            cstr.to_string_lossy().into_owned()
        } else {
            String::from("unknown")
        }
    }
}

fn unix_timestamp() -> String {
    let secs = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_secs())
        .unwrap_or(0);
    secs.to_string()
}

fn ensure_log_dir(path: &Path) -> Result<(), String> {
    if !path.exists() {
        fs::create_dir_all(path).map_err(|e| format!("No se pudo crear log dir: {e}"))?;
    }

    let perms = fs::Permissions::from_mode(0o750);
    fs::set_permissions(path, perms).map_err(|e| format!("No se pudo aplicar permisos en log dir: {e}"))
}

fn append_log_line(line: &str) -> Result<(), String> {
    let log_dir = Path::new("/var/log/leviathan");
    ensure_log_dir(log_dir)?;

    let log_file = log_dir.join("auto-update-agent.log");
    let mut file = OpenOptions::new()
        .create(true)
        .append(true)
        .open(&log_file)
        .map_err(|e| format!("No se pudo abrir el log {}: {e}", log_file.display()))?;

    file.write_all(line.as_bytes())
        .and_then(|_| file.write_all(b"\n"))
        .map_err(|e| format!("No se pudo escribir en el log: {e}"))
}

fn run_pacman() -> Result<(), String> {
    let pacman_path = Path::new("/usr/bin/pacman");
    if !pacman_path.exists() {
        return Err(String::from("No existe /usr/bin/pacman en el sistema"));
    }

    let status = Command::new(pacman_path)
        .args(["-Syu", "--noconfirm", "--needed"])
        .status()
        .map_err(|e| format!("No se pudo ejecutar /usr/bin/pacman: {e}"))?;

    if status.success() {
        Ok(())
    } else {
        Err(format!("pacman termino con estado {status}"))
    }
}

fn require_root() -> Result<(), String> {
    let euid = unsafe { geteuid() };
    if euid == 0 {
        Ok(())
    } else {
        Err(String::from("Este agente debe ejecutarse como root"))
    }
}

fn main() -> ExitCode {
    let config = match parse_args() {
        Ok(c) => c,
        Err(e) if e.is_empty() => return ExitCode::SUCCESS,
        Err(e) => {
            eprintln!("{e}");
            return ExitCode::from(2);
        }
    };

    if let Err(e) = require_root() {
        eprintln!("{e}");
        return ExitCode::from(1);
    }

    let prefix = format!("[auto-update-agent][ts={}]", unix_timestamp());
    let start_line = format!(
        "{} inicio host={} user={}",
        prefix, config.hostname, config.username
    );
    if let Err(e) = append_log_line(&start_line) {
        eprintln!("{e}");
    }

    match run_pacman() {
        Ok(()) => {
            let _ = fs::remove_file(&config.cache_file);
            let _ = append_log_line(&format!("{} ok", prefix));
            ExitCode::SUCCESS
        }
        Err(e) => {
            let _ = append_log_line(&format!("{} failed error={}", prefix, e));
            eprintln!("{e}");
            ExitCode::from(1)
        }
    }
}
