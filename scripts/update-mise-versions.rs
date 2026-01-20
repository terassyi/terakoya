#!/usr/bin/env rust-script
//! Update .mise.toml with latest versions
//!
//! ```cargo
//! [dependencies]
//! toml = "0.8"
//! regex = "1"
//! ```

use regex::Regex;
use std::fs;

fn main() -> Result<(), Box<dyn std::error::Error>> {
    // Get file paths from command line arguments
    let mise_toml_path = std::env::args()
        .nth(1)
        .unwrap_or_else(|| ".mise.toml".to_string());

    let updates_input_path = std::env::args()
        .nth(2)
        .unwrap_or_else(|| "/tmp/mise_updates.toml".to_string());

    let output_path = std::env::args().nth(3);

    // Read current .mise.toml
    let mut content = fs::read_to_string(&mise_toml_path)?;

    // Read updates from TOML file
    let updates_content = fs::read_to_string(&updates_input_path)?;
    let updates_parsed: toml::Value = toml::from_str(&updates_content)?;

    // Apply updates from TOML
    if let Some(updates_table) = updates_parsed.get("updates").and_then(|v| v.as_table()) {
        for (tool_name, update_entry) in updates_table.iter() {
            if let Some(entry) = update_entry.as_table() {
                if let (Some(current), Some(latest)) = (
                    entry.get("current").and_then(|v| v.as_str()),
                    entry.get("latest").and_then(|v| v.as_str()),
                ) {
                    // Replace version in .mise.toml
                    let pattern = format!(
                        r#"^({}\s*=\s*)["\']([^"\']*)["\']"#,
                        regex::escape(tool_name)
                    );
                    let re = Regex::new(&pattern)?;
                    let replacement = format!(r#"${{1}}"{}""#, latest);
                    content = re.replace(&content, replacement.as_str()).to_string();

                    eprintln!("✓ Updated {}: {} → {}", tool_name, current, latest);
                }
            }
        }
    }

    // Write updated .mise.toml
    if let Some(path) = output_path {
        // Write to file
        fs::write(&path, &content)?;
        eprintln!("✓ Output: {}", path);
    } else if std::env::args().nth(1).is_some() && std::env::args().nth(2).is_some() {
        // If first two args are provided, update in-place
        fs::write(&mise_toml_path, &content)?;
        eprintln!("✓ Updated: {}", mise_toml_path);
    } else {
        // Output to stdout
        println!("{}", content);
    }

    Ok(())
}
