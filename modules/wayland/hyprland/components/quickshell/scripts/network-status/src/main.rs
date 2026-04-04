use std::collections::{HashMap, HashSet};
use std::env;
use std::fs;
use std::path::PathBuf;
use std::process::Command;
use std::thread;
use std::time::Duration;

#[derive(Copy, Clone)]
enum CacheKind {
    Known,
    Available,
}

fn main() {
    let args: Vec<String> = std::env::args().collect();

    if args.len() < 2 {
        eprintln!("Usage: network-status [connected|icon|known|available|speed|scan-cache [force]|slot <known|available> <index>|ssid <known|available> <index>]");
        return;
    }

    match args[1].as_str() {
        "connected" => show_connected(),
        "icon" => show_icon(),
        "known" => show_known_networks(),
        "available" => show_available_networks(),
        "speed" => show_live_speed(),
        "scan-cache" => scan_cache(&args),
        "slot" => show_slot(&args),
        "ssid" => show_ssid_for_slot(&args),
        _ => {}
    }
}

fn cache_root() -> PathBuf {
    if let Ok(dir) = env::var("XDG_CACHE_HOME") {
        return PathBuf::from(dir).join("leviathan");
    }

    let home = env::var("HOME").unwrap_or_else(|_| String::from("/tmp"));
    PathBuf::from(home).join(".cache").join("leviathan")
}

fn cache_file(kind: CacheKind) -> PathBuf {
    let name = match kind {
        CacheKind::Known => "network-known-cache.tsv",
        CacheKind::Available => "network-available-cache.tsv",
    };

    cache_root().join(name)
}

fn format_entry(entry: &(String, i32)) -> String {
    format!("{} {} ({}%)", signal_icon(entry.1), entry.0, entry.1)
}

fn parse_cached_entries(text: &str) -> Vec<(String, i32)> {
    let mut out = Vec::new();

    for line in text.lines() {
        let mut parts = line.split('\t');
        let ssid = parts.next().unwrap_or("").trim().to_string();
        let signal = parts
            .next()
            .and_then(|v| v.parse::<i32>().ok())
            .unwrap_or(0);

        if !ssid.is_empty() {
            out.push((ssid, signal));
        }
    }

    out
}

fn cached_entries(kind: CacheKind) -> Vec<(String, i32)> {
    let path = cache_file(kind);

    if !path.exists() {
        let _ = update_cache(false);
    }

    let Ok(text) = fs::read_to_string(&path) else {
        return Vec::new();
    };

    parse_cached_entries(&text)
}

fn ssids_of(entries: &[(String, i32)]) -> Vec<String> {
    entries.iter().map(|(ssid, _)| ssid.clone()).collect()
}

fn write_cache_if_needed(kind: CacheKind, entries: &[(String, i32)], force: bool) -> bool {
    let root = cache_root();
    let _ = fs::create_dir_all(&root);

    let path = cache_file(kind);
    let old_entries = fs::read_to_string(&path)
        .ok()
        .map(|s| parse_cached_entries(&s))
        .unwrap_or_default();

    let old_ssids = ssids_of(&old_entries);
    let new_ssids = ssids_of(entries);

    if !force && old_ssids == new_ssids {
        return false;
    }

    let content = entries
        .iter()
        .map(|(ssid, signal)| format!("{}\t{}", ssid, signal))
        .collect::<Vec<_>>()
        .join("\n");

    let _ = fs::write(path, format!("{}\n", content));
    true
}

fn update_cache(force: bool) -> bool {
    let known = sorted_known_networks_in_range();
    let available = sorted_available_networks();

    let known_changed = write_cache_if_needed(CacheKind::Known, &known, force);
    let available_changed = write_cache_if_needed(CacheKind::Available, &available, force);

    known_changed || available_changed
}

fn scan_cache(args: &[String]) {
    let force = args.get(2).map(|v| v == "force").unwrap_or(false);
    let changed = update_cache(force);
    println!("{}", if changed { "changed" } else { "unchanged" });
}

fn show_connected() {
    let ssid = get_ssid();
    let signal = get_signal();
    let ip = get_ipv4();

    if ssid.is_empty() {
        println!("Not connected");
        return;
    }

    let ip_part = if ip.is_empty() { "No IP".to_string() } else { ip };
    println!("{} {} - {}", signal_icon(signal), ssid, ip_part);
    println!("Quality: {}%", signal);
}

fn show_icon() {
    print!("{}", signal_icon(get_signal()));
}

fn signal_icon(signal: i32) -> &'static str {
    match signal {
            75..=100 => "󰤨",
            50..=74 => "󰤥",
            25..=49 => "󰤢",
            _ => "󰤟",
    }
}

fn run_busctl(args: &[&str]) -> Option<String> {
    let output = Command::new("busctl")
        .arg("--system")
        .args(args)
        .output()
        .ok()?;

    if !output.status.success() {
        return None;
    }

    Some(String::from_utf8_lossy(&output.stdout).trim().to_string())
}

fn extract_quoted_strings(input: &str) -> Vec<String> {
    let mut out = Vec::new();
    let mut in_quote = false;
    let mut current = String::new();

    for ch in input.chars() {
        if ch == '"' {
            if in_quote {
                out.push(current.clone());
                current.clear();
            }
            in_quote = !in_quote;
            continue;
        }

        if in_quote {
            current.push(ch);
        }
    }

    out
}

fn parse_u32_property(output: &str) -> Option<u32> {
    output
        .split_whitespace()
        .nth(1)
        .and_then(|v| v.parse::<u32>().ok())
}

fn parse_u8_property(output: &str) -> Option<u8> {
    output
        .split_whitespace()
        .nth(1)
        .and_then(|v| v.parse::<u8>().ok())
}

fn parse_ssid_bytes(output: &str) -> String {
    let parts: Vec<&str> = output.split_whitespace().collect();
    if parts.len() < 3 || parts[0] != "ay" {
        return String::new();
    }

    let bytes: Vec<u8> = parts
        .iter()
        .skip(2)
        .filter_map(|b| b.parse::<u8>().ok())
        .collect();

    String::from_utf8_lossy(&bytes).trim().to_string()
}

fn nm_get_property(path: &str, iface: &str, property: &str) -> Option<String> {
    run_busctl(&[
        "get-property",
        "org.freedesktop.NetworkManager",
        path,
        iface,
        property,
    ])
}

fn nm_get_device_paths() -> Vec<String> {
    run_busctl(&[
        "call",
        "org.freedesktop.NetworkManager",
        "/org/freedesktop/NetworkManager",
        "org.freedesktop.NetworkManager",
        "GetDevices",
    ])
    .map(|s| extract_quoted_strings(&s))
    .unwrap_or_default()
}

fn get_wifi_device_path() -> Option<String> {
    for path in nm_get_device_paths() {
        let output = nm_get_property(&path, "org.freedesktop.NetworkManager.Device", "DeviceType")?;
        if parse_u32_property(&output) == Some(2) {
            return Some(path);
        }
    }

    None
}

fn get_active_interface() -> String {
    let wifi = match get_wifi_device_path() {
        Some(path) => path,
        None => return String::new(),
    };

    let output = match nm_get_property(&wifi, "org.freedesktop.NetworkManager.Device", "Interface") {
        Some(value) => value,
        None => return String::new(),
    };

    extract_quoted_strings(&output)
        .first()
        .cloned()
        .unwrap_or_default()
}

fn get_active_ap_path() -> Option<String> {
    let wifi = get_wifi_device_path()?;
    let output = nm_get_property(
        &wifi,
        "org.freedesktop.NetworkManager.Device.Wireless",
        "ActiveAccessPoint",
    )?;

    let path = extract_quoted_strings(&output).first()?.clone();
    if path == "/" {
        return None;
    }

    Some(path)
}

fn get_ssid() -> String {
    let ap = match get_active_ap_path() {
        Some(path) => path,
        None => return String::new(),
    };

    nm_get_property(&ap, "org.freedesktop.NetworkManager.AccessPoint", "Ssid")
        .map(|s| parse_ssid_bytes(&s))
        .unwrap_or_default()
}

fn get_signal() -> i32 {
    let ap = match get_active_ap_path() {
        Some(path) => path,
        None => return 0,
    };

    nm_get_property(&ap, "org.freedesktop.NetworkManager.AccessPoint", "Strength")
        .and_then(|s| parse_u8_property(&s))
        .map(|s| s as i32)
        .unwrap_or(0)
}

fn read_bytes(path: &str) -> Option<u64> {
    fs::read_to_string(path).ok()?.trim().parse().ok()
}

fn get_ipv4() -> String {
    let iface = get_active_interface();
    if iface.is_empty() {
        return String::new();
    }

    let output = Command::new("ip")
        .args(["-o", "-4", "addr", "show", "dev", &iface, "scope", "global"])
        .output();

    let Ok(output) = output else {
        return String::new();
    };

    if !output.status.success() {
        return String::new();
    }

    let text = String::from_utf8_lossy(&output.stdout);
    for line in text.lines() {
        let mut parts = line.split_whitespace();
        while let Some(part) = parts.next() {
            if part == "inet" {
                if let Some(cidr) = parts.next() {
                    return cidr.split('/').next().unwrap_or("").to_string();
                }
            }
        }
    }

    String::new()
}

fn show_live_speed() {
    let iface = get_active_interface();
    if iface.is_empty() {
        println!("Quality: 0% - ↑ 0.00 MB/s / ↓ 0.00 MB/s");
        return;
    }

    let signal = get_signal();

    let rx_path = format!("/sys/class/net/{}/statistics/rx_bytes", iface);
    let tx_path = format!("/sys/class/net/{}/statistics/tx_bytes", iface);

    let rx1 = read_bytes(&rx_path).unwrap_or(0);
    let tx1 = read_bytes(&tx_path).unwrap_or(0);

    thread::sleep(Duration::from_millis(500));

    let rx2 = read_bytes(&rx_path).unwrap_or(0);
    let tx2 = read_bytes(&tx_path).unwrap_or(0);

    let rx_speed = (rx2.saturating_sub(rx1) as f64 / 1024.0 / 1024.0) * 2.0;
    let tx_speed = (tx2.saturating_sub(tx1) as f64 / 1024.0 / 1024.0) * 2.0;

    println!("Quality: {}% - ↑ {:.2} MB/s / ↓ {:.2} MB/s", signal, tx_speed, rx_speed);
}

fn get_available_networks() -> HashMap<String, i32> {
    let mut networks = HashMap::new();
    let wifi = match get_wifi_device_path() {
        Some(path) => path,
        None => return networks,
    };

    let aps = run_busctl(&[
        "call",
        "org.freedesktop.NetworkManager",
        &wifi,
        "org.freedesktop.NetworkManager.Device.Wireless",
        "GetAllAccessPoints",
    ])
    .map(|s| extract_quoted_strings(&s))
    .unwrap_or_default();

    for ap in aps {
        let ssid = nm_get_property(&ap, "org.freedesktop.NetworkManager.AccessPoint", "Ssid")
            .map(|s| parse_ssid_bytes(&s))
            .unwrap_or_default();

        if ssid.is_empty() {
            continue;
        }

        let signal = nm_get_property(&ap, "org.freedesktop.NetworkManager.AccessPoint", "Strength")
            .and_then(|s| parse_u8_property(&s))
            .map(|s| s as i32)
            .unwrap_or(0);

        networks
            .entry(ssid)
            .and_modify(|s| *s = (*s).max(signal))
            .or_insert(signal);
    }

    networks
}

fn get_available_ssids() -> HashSet<String> {
    get_available_networks().into_keys().collect()
}

fn get_ssid_signal(ssid: &str) -> Option<i32> {
    get_available_networks().get(ssid).copied()
}

fn get_known_wifi_connections() -> Vec<String> {
    let mut known = Vec::new();
    let paths = run_busctl(&[
        "call",
        "org.freedesktop.NetworkManager",
        "/org/freedesktop/NetworkManager/Settings",
        "org.freedesktop.NetworkManager.Settings",
        "ListConnections",
    ])
    .map(|s| extract_quoted_strings(&s))
    .unwrap_or_default();

    for path in paths {
        let settings = run_busctl(&[
            "call",
            "org.freedesktop.NetworkManager",
            &path,
            "org.freedesktop.NetworkManager.Settings.Connection",
            "GetSettings",
        ]);

        let Some(settings) = settings else {
            continue;
        };

        let quoted = extract_quoted_strings(&settings);
        let mut id: Option<String> = None;
        let mut conn_type: Option<String> = None;

        for pair in quoted.windows(2) {
            if pair[0] == "id" && id.is_none() {
                id = Some(pair[1].clone());
            }
            if pair[0] == "type" && conn_type.is_none() {
                conn_type = Some(pair[1].clone());
            }
        }

        if conn_type.as_deref() == Some("802-11-wireless") {
            if let Some(name) = id {
                if !name.is_empty() {
                    known.push(name);
                }
            }
        }
    }

    known.sort();
    known.dedup();
    known
}

fn sorted_available_networks() -> Vec<(String, i32)> {
    let current_ssid = get_ssid();
    let known: HashSet<String> = get_known_wifi_connections().into_iter().collect();

    let mut networks: Vec<(String, i32)> = get_available_networks()
        .into_iter()
        .filter(|(ssid, _)| !ssid.is_empty())
        .filter(|(ssid, _)| *ssid != current_ssid)
        .filter(|(ssid, _)| !known.contains(ssid))
        .collect();

    networks.sort_by(|a, b| b.1.cmp(&a.1));
    networks
}

fn sorted_known_networks_in_range() -> Vec<(String, i32)> {
    let current_ssid = get_ssid();
    let available = get_available_ssids();
    let known = get_known_wifi_connections();

    let mut known_in_range = Vec::new();
    for ssid in known {
        if ssid != current_ssid && available.contains(&ssid) {
            if let Some(signal) = get_ssid_signal(&ssid) {
                known_in_range.push((ssid, signal));
            }
        }
    }

    known_in_range.sort_by(|a, b| b.1.cmp(&a.1));
    known_in_range
}

fn parse_slot_args(args: &[String]) -> Option<(&str, usize)> {
    if args.len() < 4 {
        return None;
    }

    let group = args[2].as_str();
    if group != "known" && group != "available" {
        return None;
    }

    let index = args[3].parse::<usize>().ok()?;
    Some((group, index))
}

fn slot_network(group: &str, index: usize) -> Option<(String, i32)> {
    let list = if group == "known" {
        cached_entries(CacheKind::Known)
    } else {
        cached_entries(CacheKind::Available)
    };

    list.get(index).cloned()
}

fn show_slot(args: &[String]) {
    let Some((group, index)) = parse_slot_args(args) else {
        println!("-");
        return;
    };

    if let Some((ssid, signal)) = slot_network(group, index) {
        println!("{} {} ({}%)", signal_icon(signal), ssid, signal);
    } else {
        println!("-");
    }
}

fn show_ssid_for_slot(args: &[String]) {
    let Some((group, index)) = parse_slot_args(args) else {
        return;
    };

    if let Some((ssid, _)) = slot_network(group, index) {
        println!("{}", ssid);
    }
}

fn show_known_networks() {
    for entry in cached_entries(CacheKind::Known).iter() {
        println!("{}", format_entry(entry));
    }
}

fn show_available_networks() {
    for entry in cached_entries(CacheKind::Available).iter() {
        println!("{}", format_entry(entry));
    }
}
