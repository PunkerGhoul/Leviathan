use crate::normalizer;
use std::collections::hash_map::DefaultHasher;
use std::fs;
use std::hash::{Hash, Hasher};
use std::io;
use std::path::PathBuf;
use std::time::{SystemTime, UNIX_EPOCH};

pub struct Roller {
    output_path: PathBuf,
    version: u64,
    last_hash: u64,
}

impl Roller {
    pub fn new() -> Self {
        let output_path = runtime_dir().join("leviathan").join("battery.snapshot");
        Self {
            output_path,
            version: 0,
            last_hash: 0,
        }
    }

    pub fn apply_raw_snapshot(&mut self, raw: &str) -> io::Result<bool> {
        let normalized = normalizer::normalize(raw);
        let mut keys: Vec<String> = normalized.keys().cloned().collect();
        keys.sort();

        let mut payload_lines = Vec::new();
        for key in keys {
            if let Some(value) = normalized.get(&key) {
                payload_lines.push(format!("{}={}", key, value));
            }
        }

        let payload = payload_lines.join("\n");
        let hash = fast_hash(&payload);
        if hash == self.last_hash {
            return Ok(false);
        }

        self.last_hash = hash;
        self.version += 1;

        let updated_ms = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap_or_default()
            .as_millis();

        let mut final_blob = String::new();
        final_blob.push_str(&format!("SNAPSHOT_VERSION={}\n", self.version));
        final_blob.push_str(&format!("UPDATED_MS={}\n", updated_ms));
        final_blob.push_str(&payload);
        final_blob.push('\n');

        write_atomic(&self.output_path, &final_blob)?;
        Ok(true)
    }
}

fn write_atomic(path: &PathBuf, content: &str) -> io::Result<()> {
    if let Some(parent) = path.parent() {
        fs::create_dir_all(parent)?;
    }

    let tmp_path = path.with_extension("tmp");
    fs::write(&tmp_path, content)?;
    fs::rename(tmp_path, path)?;
    Ok(())
}

fn runtime_dir() -> PathBuf {
    if let Ok(dir) = std::env::var("XDG_RUNTIME_DIR") {
        return PathBuf::from(dir);
    }

    if let Ok(uid) = std::env::var("UID") {
        return PathBuf::from(format!("/run/user/{}", uid));
    }

    PathBuf::from("/tmp")
}

fn fast_hash(text: &str) -> u64 {
    let mut hasher = DefaultHasher::new();
    text.hash(&mut hasher);
    hasher.finish()
}
