use serde_json::Value;
use std::collections::HashSet;
use std::env;
use std::fs::{self, File};
use std::io::Read;
use std::path::PathBuf;

use bsp_to_glb::MountedModelResolver;
use bsp_to_glb::studiomodel::{StudioModelInput, export_studio_model};

fn find_model_paths(value: &Value, paths: &mut HashSet<String>) {
    match value {
        Value::Object(map) => {
            for (k, v) in map {
                if k == "modelPath" {
                    if let Value::String(s) = v {
                        paths.insert(s.clone());
                    }
                }
                find_model_paths(v, paths);
            }
        }
        Value::Array(arr) => {
            for item in arr {
                find_model_paths(item, paths);
            }
        }
        _ => {}
    }
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let args: Vec<String> = env::args().collect();

    if args.len() < 4 {
        eprintln!(
            "Usage: {} <map.glb> <output_dir> <mount_path> [mount_path...] [--limit N]",
            args[0]
        );
        std::process::exit(1);
    }

    let map_glb_path = &args[1];
    let output_dir = PathBuf::from(&args[2]);

    let mut mounts = Vec::new();
    let mut limit: Option<usize> = None;
    let mut i = 3;

    while i < args.len() {
        if args[i] == "--limit" {
            if i + 1 >= args.len() {
                eprintln!("Error: --limit requires a value.");
                std::process::exit(1);
            }

            match args[i + 1].parse::<usize>() {
                Ok(value) => {
                    limit = Some(value);
                    i += 2;
                }
                Err(_) => {
                    eprintln!(
                        "Error: Invalid value for --limit. Expected a non-negative integer, got '{}'.",
                        args[i + 1]
                    );
                    std::process::exit(1);
                }
            }
        } else {
            mounts.push(args[i].clone());
            i += 1;
        }
    }

    if mounts.is_empty() {
        eprintln!("Error: At least one mount path is required.");
        std::process::exit(1);
    }

    let mut file = File::open(map_glb_path)?;

    let mut header = [0u8; 12];
    file.read_exact(&mut header)?;

    if &header[0..4] != b"glTF" {
        return Err("Input file is not a valid GLB".into());
    }

    let mut chunk_header = [0u8; 8];
    file.read_exact(&mut chunk_header)?;

    let chunk_len = u32::from_le_bytes(chunk_header[0..4].try_into().unwrap()) as usize;

    let chunk_type = &chunk_header[4..8];

    if chunk_type != b"JSON" {
        return Err("First GLB chunk is not JSON".into());
    }

    let mut json_data = vec![0u8; chunk_len];
    file.read_exact(&mut json_data)?;

    let root: Value = serde_json::from_slice(&json_data)?;

    let mut unique_paths = HashSet::new();
    find_model_paths(&root, &mut unique_paths);

    let mut sorted_paths: Vec<String> = unique_paths.into_iter().collect();
    sorted_paths.sort();

    let total_unique_paths = sorted_paths.len();

    if let Some(limit_value) = limit {
        sorted_paths.truncate(limit_value);
    }

    let selected_paths_count = sorted_paths.len();

    let mut resolver = MountedModelResolver::default();

    for mount in &mounts {
        let path = PathBuf::from(mount);

        if path.is_file() && path.extension().is_some_and(|e| e == "vpk") {
            resolver.mount_vpk(path)?;
        } else {
            resolver.mount_directory(path)?;
        }
    }

    let mut exported_count = 0usize;
    let mut skipped_count = 0usize;
    let mut failed_count = 0usize;
    let mut unresolved_count = 0usize;

    for model_path in &sorted_paths {
        let resolved = match resolver.resolve(model_path) {
            Ok(value) => value,
            Err(_) => {
                unresolved_count += 1;
                continue;
            }
        };

        let glb_out = output_dir.join(model_path).with_extension("glb");
        let manifest_out = output_dir.join(model_path).with_extension("json");

        let mut skip = false;

        if glb_out.exists() && manifest_out.exists() {
            if let Ok(manifest_data) = fs::read_to_string(&manifest_out) {
                if let Ok(manifest_json) = serde_json::from_str::<Value>(&manifest_data) {
                    if let Some(hash) = manifest_json
                        .get("packageContentHash")
                        .and_then(|h| h.as_str())
                    {
                        if hash == resolved.package_content_hash {
                            skip = true;
                        } else {
                            println!(
                                "WARN: Hash mismatch for {}, overwriting\n  Old: {}\n  New: {}",
                                model_path, hash, resolved.package_content_hash
                            );
                        }
                    }
                }
            }
        }

        if skip {
            skipped_count += 1;
            continue;
        }

        if let Some(parent) = glb_out.parent() {
            if let Err(e) = fs::create_dir_all(parent) {
                eprintln!("Failed to create directory for {}: {}", model_path, e);
                failed_count += 1;
                continue;
            }
        }

        let input = StudioModelInput {
            source_path: &resolved.source_path,
            mdl: &resolved.mdl,
            vvd: &resolved.vvd,
            vtx: &resolved.vtx,
            ani: resolved.ani.as_deref(),
            phy: resolved.phy.as_deref(),
            skin: 0,
        };

        let mut export = match export_studio_model(&input) {
            Ok(value) => value,
            Err(e) => {
                eprintln!("Failed to export {}: {:?}", model_path, e);
                failed_count += 1;
                continue;
            }
        };

        export.manifest.package_content_hash = resolved.package_content_hash.clone();

        if let Err(e) = fs::write(&glb_out, &export.glb) {
            eprintln!("Failed to write GLB for {}: {}", model_path, e);
            failed_count += 1;
            continue;
        }

        let manifest_json = match serde_json::to_string_pretty(&export.manifest) {
            Ok(value) => value,
            Err(e) => {
                eprintln!("Failed to serialize manifest for {}: {}", model_path, e);
                failed_count += 1;
                continue;
            }
        };

        if let Err(e) = fs::write(&manifest_out, manifest_json) {
            eprintln!("Failed to write manifest for {}: {}", model_path, e);
            failed_count += 1;
            continue;
        }

        exported_count += 1;
    }

    println!("--- Batch Export Summary ---");
    println!("Total Unique Paths : {}", total_unique_paths);
    println!("Selected for Run   : {}", selected_paths_count);
    println!("Exported           : {}", exported_count);
    println!("Skipped (Match)    : {}", skipped_count);
    println!("Failed Exports     : {}", failed_count);
    println!("Unresolved/Missing : {}", unresolved_count);

    Ok(())
}
