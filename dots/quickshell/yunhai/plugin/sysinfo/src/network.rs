use std::time::Instant;

#[derive(Default, Clone)]
pub struct Sample {
    pub down_rate: f64,
    pub up_rate: f64,
    pub down_total: f64,
    pub up_total: f64,
}

pub struct Reader {
    last: Option<(u64, u64, Instant)>,
}

impl Default for Reader {
    fn default() -> Self {
        Self { last: None }
    }
}

fn is_virtual(name: &str) -> bool {
    name == "lo"
        || name.starts_with("veth")
        || name.starts_with("docker")
        || name.starts_with("br-")
        || name.starts_with("virbr")
}

fn totals() -> Option<(u64, u64)> {
    let text = std::fs::read_to_string("/proc/net/dev").ok()?;
    let mut rx = 0u64;
    let mut tx = 0u64;
    for line in text.lines().skip(2) {
        let (name, rest) = line.split_once(':')?;
        let name = name.trim();
        if is_virtual(name) {
            continue;
        }
        let fields: Vec<&str> = rest.split_whitespace().collect();
        if fields.len() < 9 {
            continue;
        }
        rx += fields[0].parse::<u64>().unwrap_or(0);
        tx += fields[8].parse::<u64>().unwrap_or(0);
    }
    Some((rx, tx))
}

impl Reader {
    pub fn sample(&mut self) -> Sample {
        let Some((rx, tx)) = totals() else {
            return Sample::default();
        };
        let now = Instant::now();
        let mut out = Sample {
            down_rate: 0.0,
            up_rate: 0.0,
            down_total: rx as f64,
            up_total: tx as f64,
        };
        if let Some((prev_rx, prev_tx, prev_at)) = self.last {
            let dt = now.duration_since(prev_at).as_secs_f64();
            if dt > 0.0 {
                out.down_rate = rx.saturating_sub(prev_rx) as f64 / dt;
                out.up_rate = tx.saturating_sub(prev_tx) as f64 / dt;
            }
        }
        self.last = Some((rx, tx, now));
        out
    }
}
