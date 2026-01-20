#!/usr/bin/env rust-script
//! Check for mise tools updates
//!
//! ```cargo
//! [dependencies]
//! toml = "0.8"
//! regex = "1"
//! ```

use regex::Regex;
use std::fs;
use std::process::Command;

const SKIP_VERSIONS: &[&str] = &["lts", "latest", "stable"];
const UNSTABLE_SUFFIX: &[&str] = &["alpha", "beta", "rc", "a", "b", "dev", "pre", "post"];

fn is_stable_version(version: &str) -> bool {
    // Only allow digits, dots, and optional patch suffix (SemVer format)
    // Reject any version with unstable markers
    if UNSTABLE_SUFFIX
        .iter()
        .any(|&suffix| version.to_lowercase().contains(suffix))
    {
        return false;
    }
    // Must be valid SemVer format: X.Y.Z
    let semver_regex = Regex::new(r"^\d+\.\d+\.\d+$").ok();
    semver_regex.map_or(false, |re| re.is_match(version))
}

fn get_latest_stable<'a>(versions: &'a [&'a str]) -> Option<&'a str> {
    versions
        .iter()
        .rev()
        .find(|v| is_stable_version(v))
        .copied()
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    // Get .mise.toml path from command line argument, default to ".mise.toml"
    let mise_toml_path = std::env::args()
        .nth(1)
        .unwrap_or_else(|| ".mise.toml".to_string());

    // Get output file path from command line argument (optional)
    let output_path = std::env::args().nth(2);
    let content = fs::read_to_string(&mise_toml_path)?;
    let parsed: toml::Value = toml::from_str(&content)?;

    let tools = parsed
        .get("tools")
        .and_then(|v| v.as_table())
        .ok_or("No [tools] section found")?;

    let mut updates = Vec::new();

    for (tool_name, version_val) in tools {
        let current_version = match version_val {
            toml::Value::String(v) => v.as_str(),
            _ => continue,
        };

        // Skip excluded version strings
        if SKIP_VERSIONS.contains(&current_version) {
            continue;
        }

        // Get latest available version
        let output = Command::new("mise")
            .args(&["ls-remote", tool_name])
            .output()?;

        if !output.status.success() {
            eprintln!("✗ {}: failed to check", tool_name);
            continue;
        }

        let output_str = String::from_utf8(output.stdout)?;
        let versions: Vec<&str> = output_str.lines().filter(|line| !line.is_empty()).collect();

        let latest_version = get_latest_stable(&versions);

        if let Some(latest) = latest_version {
            if latest != current_version {
                updates.push((
                    tool_name.clone(),
                    current_version.to_string(),
                    latest.to_string(),
                ));
                eprintln!("✓ {}: {} → {}", tool_name, current_version, latest);
            }
        }
    }

    if !updates.is_empty() {
        // Create TOML output
        let mut output_toml = toml::map::Map::new();
        let mut updates_table = toml::map::Map::new();

        for (tool, current, latest) in &updates {
            let mut entry = toml::map::Map::new();
            entry.insert("current".to_string(), toml::Value::String(current.clone()));
            entry.insert("latest".to_string(), toml::Value::String(latest.clone()));
            updates_table.insert(tool.clone(), toml::Value::Table(entry));
        }

        output_toml.insert("updates".to_string(), toml::Value::Table(updates_table));
        let toml_str = toml::to_string_pretty(&output_toml)?;

        // Write output
        if let Some(path) = output_path {
            fs::write(&path, &toml_str)?;
            eprintln!("✓ Found {} update(s)", updates.len());
            eprintln!("  Output: {}", path);
        } else {
            println!("{}", toml_str);
        }

        // Write to GitHub output
        if let Ok(output) = std::env::var("GITHUB_OUTPUT") {
            fs::write(&output, "has_updates=true\n")?;
        }
    } else {
        eprintln!("No updates found");
        if let Ok(output) = std::env::var("GITHUB_OUTPUT") {
            fs::write(&output, "has_updates=false\n")?;
        }
    }
    Ok(())
}
