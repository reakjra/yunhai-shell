use std::ffi::CString;

#[derive(Default, Clone)]
pub struct Mount {
    pub device: String,
    pub mount_point: String,
    pub total: f64,
    pub used: f64,
    pub usage: f64,
}

fn usage_for(path: &str) -> Option<(f64, f64)> {
    let c_path = CString::new(path).ok()?;
    let mut stat: libc::statvfs = unsafe { std::mem::zeroed() };
    if unsafe { libc::statvfs(c_path.as_ptr(), &mut stat) } != 0 {
        return None;
    }
    let block = stat.f_frsize as f64;
    let total = stat.f_blocks as f64 * block;
    if total <= 0.0 {
        return None;
    }
    let free = stat.f_bfree as f64 * block;
    Some((total, total - free))
}

pub fn mounts() -> Vec<Mount> {
    let Ok(text) = std::fs::read_to_string("/proc/mounts") else {
        return Vec::new();
    };
    let mut seen: Vec<String> = Vec::new();
    let mut out = Vec::new();
    for line in text.lines() {
        let mut parts = line.split_whitespace();
        let (Some(device), Some(mount_point)) = (parts.next(), parts.next()) else {
            continue;
        };
        if !device.starts_with("/dev/") || seen.iter().any(|d| d == device) {
            continue;
        }
        let mount_point = mount_point.replace("\\040", " ");
        let Some((total, used)) = usage_for(&mount_point) else {
            continue;
        };
        seen.push(device.to_string());
        out.push(Mount {
            device: device.trim_start_matches("/dev/").to_string(),
            mount_point,
            total,
            used,
            usage: if total > 0.0 { used / total } else { 0.0 },
        });
    }
    out
}
