use libc::{geteuid, getpwuid, getuid, uid_t};
use std::env;
use std::ffi::{CStr, OsString};
use std::fs;
use std::io;
use std::os::unix::fs::PermissionsExt;
use std::path::{Path, PathBuf};
use std::process::{Command, ExitCode};

enum Mode {
    Install,
    Uninstall,
    Status,
}

impl Mode {
    fn as_str(&self) -> &'static str {
        match self {
            Mode::Install => "install",
            Mode::Uninstall => "uninstall",
            Mode::Status => "status",
        }
    }
}

const SERVICE_PATH: &str = "/etc/systemd/system/leviathan-auto-update-agent.service";
const TIMER_PATH: &str = "/etc/systemd/system/leviathan-auto-update-agent.timer";
const LEVIATHAN_STATE_ROOT: &str = "/var/lib/leviathan";
const MANAGED_ROOT: &str = "/var/lib/leviathan/updates";
const BIN_DIR: &str = "/var/lib/leviathan/updates/bin";
const BIN_LINK: &str = "/var/lib/leviathan/updates/bin/leviathan-updates-agent";
const STATE_DIR: &str = "/var/lib/leviathan/updates/state";
const BACKUP_SERVICE_PATH: &str = "/var/lib/leviathan/updates/state/service.unit.bak";
const BACKUP_TIMER_PATH: &str = "/var/lib/leviathan/updates/state/timer.unit.bak";
const STATE_FILE_PATH: &str = "/var/lib/leviathan/updates/state/state.env";
const MANAGED_MARKER: &str = "# ManagedBy=leviathan-updates-manager";

fn log(msg: &str) {
    println!("[updates-manager] {msg}");
}

fn parse_mode(argv0: &str, args: &[OsString]) -> Result<Mode, String> {
    if let Some(first) = args.first().and_then(|s| s.to_str()) {
        return match first {
            "install" => Ok(Mode::Install),
            "uninstall" => Ok(Mode::Uninstall),
            "status" => Ok(Mode::Status),
            _ => Err(format!("Comando no soportado: {first}")),
        };
    }

    if argv0.ends_with("updates-install") {
        return Ok(Mode::Install);
    }
    if argv0.ends_with("updates-uninstall") {
        return Ok(Mode::Uninstall);
    }
    Ok(Mode::Status)
}

fn username_from_uid(uid: uid_t) -> Option<String> {
    unsafe {
        let passwd = getpwuid(uid);
        if passwd.is_null() {
            return None;
        }

        let name = CStr::from_ptr((*passwd).pw_name);
        Some(name.to_string_lossy().into_owned())
    }
}

fn get_username() -> Result<String, String> {
    if let Ok(sudo_uid_raw) = env::var("SUDO_UID") {
        if let Ok(sudo_uid) = sudo_uid_raw.parse::<u32>() {
            if let Some(name) = username_from_uid(sudo_uid as uid_t) {
                if !name.is_empty() {
                    return Ok(name);
                }
            }
        }
    }

    if let Ok(sudo_user) = env::var("SUDO_USER") {
        if !sudo_user.trim().is_empty() {
            return Ok(sudo_user);
        }
    }

    let uid = unsafe { getuid() };
    username_from_uid(uid).ok_or_else(|| String::from("No se pudo resolver username desde el sistema"))
}

fn current_euid() -> u32 {
    unsafe { geteuid() as u32 }
}

fn reexec_with_sudo(mode: &Mode) -> Result<ExitCode, String> {
    let exe = env::current_exe().map_err(|e| format!("No se pudo resolver executable: {e}"))?;
    let mut cmd = Command::new("sudo");

    if let Ok(service_template_path) = env::var("LEVIATHAN_SERVICE_TEMPLATE_PATH") {
        cmd.arg(format!("LEVIATHAN_SERVICE_TEMPLATE_PATH={service_template_path}"));
    }

    if let Ok(timer_template_path) = env::var("LEVIATHAN_TIMER_TEMPLATE_PATH") {
        cmd.arg(format!("LEVIATHAN_TIMER_TEMPLATE_PATH={timer_template_path}"));
    }

    let status = cmd
        .arg(exe)
        .arg(mode.as_str())
        .status()
        .map_err(|e| format!("No se pudo ejecutar sudo: {e}"))?;

    if status.success() {
        Ok(ExitCode::SUCCESS)
    } else {
        Ok(ExitCode::from(1))
    }
}

fn manager_bin_dir() -> Result<PathBuf, String> {
    let exe = env::current_exe().map_err(|e| format!("No se pudo resolver executable: {e}"))?;
    exe.parent()
        .map(Path::to_path_buf)
        .ok_or_else(|| String::from("No se pudo obtener directorio del manager"))
}

fn bundled_agent_path() -> Result<PathBuf, String> {
    Ok(manager_bin_dir()?.join("leviathan-updates-agent"))
}

fn write_file(path: &Path, content: &str, mode: u32) -> Result<(), String> {
    fs::write(path, content).map_err(|e| format!("No se pudo escribir {}: {e}", path.display()))?;
    fs::set_permissions(path, fs::Permissions::from_mode(mode))
        .map_err(|e| format!("No se pudo ajustar permisos de {}: {e}", path.display()))
}

fn file_exists(path: &str) -> bool {
    Path::new(path).exists()
}

fn remove_file_if_exists(path: &Path) -> io::Result<()> {
    match fs::remove_file(path) {
        Ok(()) => Ok(()),
        Err(e) if e.kind() == io::ErrorKind::NotFound => Ok(()),
        Err(e) => Err(e),
    }
}

fn remove_dir_if_empty(path: &Path) {
    let _ = fs::remove_dir(path);
}

fn read_file_or_empty(path: &str) -> String {
    fs::read_to_string(path).unwrap_or_else(|_| String::new())
}

fn is_managed_unit(path: &str) -> bool {
    read_file_or_empty(path).contains(MANAGED_MARKER)
}

fn backup_unit_if_needed(source: &str, backup_path: &str) -> Result<bool, String> {
    if !file_exists(source) {
        return Ok(false);
    }

    if is_managed_unit(source) {
        return Ok(false);
    }

    fs::copy(source, backup_path)
        .map_err(|e| format!("No se pudo crear backup de {source} en {backup_path}: {e}"))?;
    Ok(true)
}

fn systemctl_success(args: &[&str]) -> bool {
    match Command::new("systemctl")
        .args(args)
        .stdout(std::process::Stdio::null())
        .stderr(std::process::Stdio::null())
        .status()
    {
        Ok(status) => status.success(),
        Err(_) => false,
    }
}

fn write_state_file(service_backed_up: bool, timer_backed_up: bool, timer_was_enabled: bool) -> Result<(), String> {
    let content = format!(
        "service_backed_up={}\ntimer_backed_up={}\ntimer_was_enabled={}\n",
        if service_backed_up { "1" } else { "0" },
        if timer_backed_up { "1" } else { "0" },
        if timer_was_enabled { "1" } else { "0" },
    );

    let state_dir = Path::new(STATE_DIR);
    fs::create_dir_all(state_dir).map_err(|e| format!("No se pudo crear {}: {e}", state_dir.display()))?;
    fs::set_permissions(state_dir, fs::Permissions::from_mode(0o700))
        .map_err(|e| format!("No se pudieron ajustar permisos de {}: {e}", state_dir.display()))?;

    let tmp_state = format!("{}.tmp", STATE_FILE_PATH);
    write_file(Path::new(&tmp_state), &content, 0o600)?;
    fs::rename(&tmp_state, STATE_FILE_PATH)
        .map_err(|e| format!("No se pudo mover estado atomico a {STATE_FILE_PATH}: {e}"))
}

fn read_state_flag(key: &str) -> bool {
    let content = read_file_or_empty(STATE_FILE_PATH);
    content
        .lines()
        .find_map(|line| {
            let (k, v) = line.split_once('=')?;
            if k == key {
                Some(v == "1")
            } else {
                None
            }
        })
        .unwrap_or(false)
}

fn remove_state_artifacts() {
    let _ = remove_file_if_exists(Path::new(STATE_FILE_PATH));
    let _ = remove_file_if_exists(Path::new(BACKUP_SERVICE_PATH));
    let _ = remove_file_if_exists(Path::new(BACKUP_TIMER_PATH));
    remove_dir_if_empty(Path::new(STATE_DIR));
}

fn get_template_paths() -> Result<(PathBuf, PathBuf), String> {
    let service_path = env::var("LEVIATHAN_SERVICE_TEMPLATE_PATH")
        .map_err(|_| String::from("Falta LEVIATHAN_SERVICE_TEMPLATE_PATH en el entorno"))?;
    let timer_path = env::var("LEVIATHAN_TIMER_TEMPLATE_PATH")
        .map_err(|_| String::from("Falta LEVIATHAN_TIMER_TEMPLATE_PATH en el entorno"))?;

    Ok((PathBuf::from(service_path), PathBuf::from(timer_path)))
}

fn expected_unit_contents(username: &str) -> Result<(String, String), String> {
    let cache_dir = format!("/home/{username}/.cache/leviathan");
    let (service_template_path, timer_template_path) = get_template_paths()?;

    let service_template = fs::read_to_string(&service_template_path)
        .map_err(|e| format!("No se pudo leer template {}: {e}", service_template_path.display()))?;
    let timer_template = fs::read_to_string(&timer_template_path)
        .map_err(|e| format!("No se pudo leer template {}: {e}", timer_template_path.display()))?;

    let expected_service = service_template
        .replace("__BIN_LINK__", BIN_LINK)
        .replace("__CACHE_DIR__", &cache_dir);

    Ok((expected_service, timer_template))
}

fn ensure_runtime_directories(username: &str) -> Result<(), String> {
    let cache_dir = format!("/home/{username}/.cache/leviathan");
    fs::create_dir_all(&cache_dir)
        .map_err(|e| format!("No se pudo crear directorio de cache {cache_dir}: {e}"))?;
    fs::set_permissions(Path::new(&cache_dir), fs::Permissions::from_mode(0o750))
        .map_err(|e| format!("No se pudieron ajustar permisos de {cache_dir}: {e}"))?;

    let log_dir = Path::new("/var/log/leviathan");
    fs::create_dir_all(log_dir)
        .map_err(|e| format!("No se pudo crear directorio de log {}: {e}", log_dir.display()))?;
    fs::set_permissions(log_dir, fs::Permissions::from_mode(0o750))
        .map_err(|e| format!("No se pudieron ajustar permisos de {}: {e}", log_dir.display()))?;

    Ok(())
}

fn needs_install() -> Result<bool, String> {
    let username = get_username()?;
    let (expected_service, expected_timer) = expected_unit_contents(&username)?;
    let expected_agent = bundled_agent_path()?;

    if !Path::new(BIN_LINK).is_symlink() {
      return Ok(true);
    }

    let current_target = fs::read_link(BIN_LINK)
        .map_err(|e| format!("No se pudo leer symlink {BIN_LINK}: {e}"))?;
    if current_target != expected_agent {
        return Ok(true);
    }

    let current_service = match fs::read_to_string(SERVICE_PATH) {
        Ok(v) => v,
        Err(e) if e.kind() == io::ErrorKind::NotFound => return Ok(true),
        Err(e) => return Err(format!("No se pudo leer {SERVICE_PATH}: {e}")),
    };

    let current_timer = match fs::read_to_string(TIMER_PATH) {
        Ok(v) => v,
        Err(e) if e.kind() == io::ErrorKind::NotFound => return Ok(true),
        Err(e) => return Err(format!("No se pudo leer {TIMER_PATH}: {e}")),
    };

    if current_service != expected_service || current_timer != expected_timer {
        return Ok(true);
    }

    if !systemctl_success(&["is-enabled", "leviathan-auto-update-agent.timer"]) {
        return Ok(true);
    }

    Ok(false)
}

fn run_systemctl(args: &[&str]) -> Result<(), String> {
    let status = Command::new("systemctl")
        .args(args)
        .status()
        .map_err(|e| format!("No se pudo ejecutar systemctl {:?}: {e}", args))?;
    if status.success() {
        Ok(())
    } else {
        Err(format!("systemctl {:?} fallo con estado {status}", args))
    }
}

fn run_systemctl_ignore(args: &[&str]) {
    let _ = Command::new("systemctl")
        .args(args)
        .stdout(std::process::Stdio::null())
        .stderr(std::process::Stdio::null())
        .status();
}

fn install_stage() -> Result<(), String> {
    let username = get_username()?;
    let timer_was_enabled = systemctl_success(&["is-enabled", "leviathan-auto-update-agent.timer"]);
    ensure_runtime_directories(&username)?;

    let agent = bundled_agent_path()?;
    if !agent.exists() {
        return Err(format!("No se encontro el agente compilado en {}", agent.display()));
    }

    fs::create_dir_all(STATE_DIR).map_err(|e| format!("No se pudo crear {STATE_DIR}: {e}"))?;
    let _ = remove_file_if_exists(Path::new(BACKUP_SERVICE_PATH));
    let _ = remove_file_if_exists(Path::new(BACKUP_TIMER_PATH));

    let service_backed_up = backup_unit_if_needed(SERVICE_PATH, BACKUP_SERVICE_PATH)?;
    let timer_backed_up = backup_unit_if_needed(TIMER_PATH, BACKUP_TIMER_PATH)?;
    write_state_file(service_backed_up, timer_backed_up, timer_was_enabled)?;

    fs::create_dir_all(BIN_DIR).map_err(|e| format!("No se pudo crear {BIN_DIR}: {e}"))?;
    if Path::new(BIN_LINK).exists() {
        fs::remove_file(BIN_LINK).map_err(|e| format!("No se pudo reemplazar {BIN_LINK}: {e}"))?;
    }
    std::os::unix::fs::symlink(&agent, BIN_LINK)
        .map_err(|e| format!("No se pudo crear symlink {BIN_LINK}: {e}"))?;

    let (rendered_service, timer_template) = expected_unit_contents(&username)?;

    write_file(Path::new(SERVICE_PATH), &rendered_service, 0o644)?;
    write_file(Path::new(TIMER_PATH), &timer_template, 0o644)?;

    run_systemctl(&["daemon-reload"])?;
    run_systemctl(&["enable", "--now", "leviathan-auto-update-agent.timer"])?;

    log(&format!("Instalado: {BIN_LINK} -> {}", agent.display()));
    log(&format!("Instalado: {SERVICE_PATH}"));
    log(&format!("Instalado: {TIMER_PATH}"));
    Ok(())
}

fn uninstall_stage() -> Result<(), String> {
    run_systemctl_ignore(&["disable", "--now", "leviathan-auto-update-agent.timer"]);
    run_systemctl_ignore(&["stop", "leviathan-auto-update-agent.service"]);

    let service_backed_up = read_state_flag("service_backed_up") || file_exists(BACKUP_SERVICE_PATH);
    let timer_backed_up = read_state_flag("timer_backed_up") || file_exists(BACKUP_TIMER_PATH);
    let timer_was_enabled = read_state_flag("timer_was_enabled");

    if service_backed_up && file_exists(BACKUP_SERVICE_PATH) {
        fs::copy(BACKUP_SERVICE_PATH, SERVICE_PATH)
            .map_err(|e| format!("No se pudo restaurar backup de {SERVICE_PATH}: {e}"))?;
        fs::set_permissions(Path::new(SERVICE_PATH), fs::Permissions::from_mode(0o644))
            .map_err(|e| format!("No se pudieron ajustar permisos de {SERVICE_PATH}: {e}"))?;
    } else {
        if is_managed_unit(SERVICE_PATH) {
            remove_file_if_exists(Path::new(SERVICE_PATH))
                .map_err(|e| format!("No se pudo borrar {SERVICE_PATH}: {e}"))?;
        } else if file_exists(SERVICE_PATH) {
            return Err(format!(
                "Se encontro {SERVICE_PATH} no gestionado y sin backup. Se aborta uninstall para evitar dañar el sistema."
            ));
        }
    }

    if timer_backed_up && file_exists(BACKUP_TIMER_PATH) {
        fs::copy(BACKUP_TIMER_PATH, TIMER_PATH)
            .map_err(|e| format!("No se pudo restaurar backup de {TIMER_PATH}: {e}"))?;
        fs::set_permissions(Path::new(TIMER_PATH), fs::Permissions::from_mode(0o644))
            .map_err(|e| format!("No se pudieron ajustar permisos de {TIMER_PATH}: {e}"))?;
    } else {
        if is_managed_unit(TIMER_PATH) {
            remove_file_if_exists(Path::new(TIMER_PATH))
                .map_err(|e| format!("No se pudo borrar {TIMER_PATH}: {e}"))?;
        } else if file_exists(TIMER_PATH) {
            return Err(format!(
                "Se encontro {TIMER_PATH} no gestionado y sin backup. Se aborta uninstall para evitar dañar el sistema."
            ));
        }
    }

    remove_file_if_exists(Path::new(BIN_LINK))
        .map_err(|e| format!("No se pudo borrar {BIN_LINK}: {e}"))?;

    remove_dir_if_empty(Path::new(BIN_DIR));
    remove_dir_if_empty(Path::new(MANAGED_ROOT));

    run_systemctl(&["daemon-reload"])?;

    if timer_backed_up && timer_was_enabled {
        run_systemctl_ignore(&["enable", "--now", "leviathan-auto-update-agent.timer"]);
    }

    remove_state_artifacts();
    remove_dir_if_empty(Path::new(MANAGED_ROOT));
    remove_dir_if_empty(Path::new(LEVIATHAN_STATE_ROOT));

    log("Stage updates desinstalado.");
    Ok(())
}

fn status_stage() -> Result<(), String> {
    if Path::new(BIN_LINK).is_symlink() {
        let target = fs::read_link(BIN_LINK)
            .map_err(|e| format!("No se pudo leer symlink {BIN_LINK}: {e}"))?;
        log(&format!("Binario enlazado: {}", target.display()));
    } else {
        log(&format!("Binario no instalado en {BIN_LINK}"));
    }

    run_systemctl_ignore(&["status", "leviathan-auto-update-agent.timer", "--no-pager"]);
    Ok(())
}

fn main() -> ExitCode {
    let argv: Vec<OsString> = env::args_os().collect();
    let argv0 = argv
        .first()
        .and_then(|v| v.to_str())
        .unwrap_or("leviathan-updates-manager");

    let args = if argv.len() > 1 { &argv[1..] } else { &[][..] };
    let mode = match parse_mode(argv0, args) {
        Ok(mode) => mode,
        Err(err) => {
            eprintln!("[updates-manager] {err}");
            eprintln!("[updates-manager] Uso: leviathan-updates-manager [install|uninstall|status]");
            return ExitCode::from(2);
        }
    };

    if matches!(mode, Mode::Install) {
        match needs_install() {
            Ok(false) => {
                log("Instalacion de updates-agent ya esta correcta y actualizada.");
                return ExitCode::SUCCESS;
            }
            Ok(true) => {
                if current_euid() != 0 {
                    match reexec_with_sudo(&mode) {
                        Ok(code) => return code,
                        Err(err) => {
                            eprintln!("[updates-manager] {err}");
                            return ExitCode::from(1);
                        }
                    }
                }
            }
            Err(err) => {
                eprintln!("[updates-manager] {err}");
                return ExitCode::from(1);
            }
        }
    }

    if matches!(mode, Mode::Uninstall) && current_euid() != 0 {
        match reexec_with_sudo(&mode) {
            Ok(code) => return code,
            Err(err) => {
                eprintln!("[updates-manager] {err}");
                return ExitCode::from(1);
            }
        }
    }

    let result = match mode {
        Mode::Install => install_stage(),
        Mode::Uninstall => uninstall_stage(),
        Mode::Status => status_stage(),
    };

    match result {
        Ok(()) => ExitCode::SUCCESS,
        Err(err) => {
            eprintln!("[updates-manager] {err}");
            ExitCode::from(1)
        }
    }
}
