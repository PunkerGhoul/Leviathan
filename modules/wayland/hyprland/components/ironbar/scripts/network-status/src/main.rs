use std::collections::{HashMap, HashSet};
use std::fs;
use std::process::Command;
use std::thread;
use std::time::Duration;

fn main() {
    let args: Vec<String> = std::env::args().collect();

    if args.len() < 2 {
        eprintln!("Usage: network-status [connected|icon|known|available|speed|slot <known|available> <index>|ssid <known|available> <index>]");
        return;
    }

    match args[1].as_str() {
        "connected" => show_connected(),
        "icon" => show_icon(),
        "known" => show_known_networks(),
        "available" => show_available_networks(),
        "speed" => show_live_speed(),
        "slot" => show_slot(&args),
        "ssid" => show_ssid_for_slot(&args),
        _ => {}
    }
}

fn show_connected() {
    let ssid = get_ssid();
    let signal = get_signal();
    let (down, up) = get_stats();

    if ssid.is_empty() {
        println!("Not connected");
        return;
    }

    println!("{} {}", signal_icon(signal), ssid);
    println!("Down: {} MB | Up: {} MB | Quality: {}%", down, up, signal);
}

fn show_icon() {
    print!("{}", signal_icon(get_signal()));
}

fn signal_icon(signal: i32) -> &'static str {
    match signal {
            75..=100 => "󰤟",
            50..=74 => "󰤢",
            25..=49 => "󰤥",
            _ => "󰤨",
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

fn get_stats() -> (String, String) {
    let iface = get_active_interface();
    if iface.is_empty() {
        return ("0".to_string(), "0".to_string());
    }

    let rx_path = format!("/sys/class/net/{}/statistics/rx_bytes", iface);
    let tx_path = format!("/sys/class/net/{}/statistics/tx_bytes", iface);

    let rx_mb = match fs::read_to_string(&rx_path) {
        Ok(content) => {
            let bytes: u64 = content.trim().parse().unwrap_or(0);
            format!("{:.1}", bytes as f64 / 1024.0 / 1024.0)
        }
        Err(_) => "0".to_string(),
    };

    let tx_mb = match fs::read_to_string(&tx_path) {
        Ok(content) => {
            let bytes: u64 = content.trim().parse().unwrap_or(0);
            format!("{:.1}", bytes as f64 / 1024.0 / 1024.0)
        }
        Err(_) => "0".to_string(),
    };

    (rx_mb, tx_mb)
}

fn read_bytes(path: &str) -> Option<u64> {
    fs::read_to_string(path).ok()?.trim().parse().ok()
}

fn show_live_speed() {
    let iface = get_active_interface();
    if iface.is_empty() {
        println!("N/A");
        return;
    }

    let rx_path = format!("/sys/class/net/{}/statistics/rx_bytes", iface);
    let tx_path = format!("/sys/class/net/{}/statistics/tx_bytes", iface);

    let rx1 = read_bytes(&rx_path).unwrap_or(0);
    let tx1 = read_bytes(&tx_path).unwrap_or(0);

    thread::sleep(Duration::from_millis(500));

    let rx2 = read_bytes(&rx_path).unwrap_or(0);
    let tx2 = read_bytes(&tx_path).unwrap_or(0);

    let rx_speed = (rx2.saturating_sub(rx1) as f64 / 1024.0 / 1024.0) * 2.0;
    let tx_speed = (tx2.saturating_sub(tx1) as f64 / 1024.0 / 1024.0) * 2.0;

    println!("Down: {:.2} MB/s | Up: {:.2} MB/s", rx_speed, tx_speed);
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
    let mut networks: Vec<(String, i32)> = get_available_networks().into_iter().collect();
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
        sorted_known_networks_in_range()
    } else {
        sorted_available_networks()
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
    for (ssid, signal) in sorted_known_networks_in_range().iter().take(10) {
        println!("{} {} ({}%)", signal_icon(*signal), ssid, signal);
    }
}

fn show_available_networks() {
    for (ssid, signal) in sorted_available_networks().iter().take(15) {
        println!("{} {} ({}%)", signal_icon(*signal), ssid, signal);
    }
}
