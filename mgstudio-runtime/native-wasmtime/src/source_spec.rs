use anyhow::bail;

#[derive(Debug, Clone)]
pub struct DirSourceSpec {
    pub base: String,
}

pub fn parse_dir_source(spec: &str, default_base: &str) -> anyhow::Result<DirSourceSpec> {
    let raw = {
        let s = spec.trim();
        if s.is_empty() {
            default_base.to_string()
        } else {
            s.to_string()
        }
    };

    let base = raw.strip_prefix("dir:").unwrap_or(&raw).trim();
    if base.is_empty() {
        bail!("dir source base is empty");
    }

    Ok(DirSourceSpec {
        base: base.to_string(),
    })
}

/// Try to join `base` and a logical (engine-facing) relative path.
///
/// This mirrors the bring-up behavior of the MoonBit native runtime:
/// attempt a "safe join" and fall back to a naive join when validation fails.
pub fn join_dir_best_effort(base: &str, logical_path: &str) -> String {
    match normalize_logical_path(logical_path) {
        Ok(rel) => {
            let p = std::path::Path::new(base).join(rel);
            p.to_string_lossy().to_string()
        }
        Err(_) => {
            // Fallback for compatibility.
            let mut b = base.trim_end_matches('/').to_string();
            if !b.is_empty() {
                b.push('/');
            }
            b.push_str(logical_path.trim_start_matches('/'));
            b
        }
    }
}

fn normalize_logical_path(path: &str) -> anyhow::Result<String> {
    if path.is_empty() {
        bail!("empty path");
    }
    if path.starts_with('/') || path.starts_with('\\') {
        bail!("absolute path");
    }
    let mut parts = Vec::new();
    for seg in path.split('/') {
        if seg.is_empty() {
            continue;
        }
        if seg == "." || seg == ".." {
            bail!("path traversal segment");
        }
        if seg.contains('\\') || seg.contains(':') {
            bail!("invalid path segment");
        }
        parts.push(seg);
    }
    if parts.is_empty() {
        bail!("empty/invalid path");
    }
    Ok(parts.join("/"))
}

