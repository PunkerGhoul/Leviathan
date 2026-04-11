use std::collections::HashMap;

const REQUIRED_KEYS: [&str; 17] = [
    "STATUS",
    "CAPACITY",
    "PROFILE",
    "VOLTAGE",
    "CYCLES",
    "RATE",
    "TIME_REMAINING",
    "AC_STATE",
    "CPU_TEMP",
    "GPU_TEMP",
    "FANS",
    "THERMAL_ZONES",
    "THERMAL_STATE",
    "AUTO_TARGET",
    "AUTO_SOURCE",
    "START_THRESHOLD",
    "STOP_THRESHOLD",
];

pub fn normalize(raw: &str) -> HashMap<String, String> {
    let mut out = HashMap::new();

    for line in raw.lines() {
        let Some(idx) = line.find('=') else {
            continue;
        };
        let key = line[..idx].trim();
        let value = line[idx + 1..].trim();
        if !key.is_empty() {
            out.insert(String::from(key), String::from(value));
        }
    }

    for key in REQUIRED_KEYS {
        out.entry(String::from(key)).or_insert_with(|| String::from("N/A"));
    }

    out.entry(String::from("BACKEND"))
        .or_insert_with(|| String::from("ppd:off | sysfs:off"));

    out
}
