use std::{
    collections::{HashMap, HashSet},
    fs,
    io::{Read, Seek, SeekFrom},
    path::{Path, PathBuf},
    sync::Mutex,
};

use sha2::{Digest, Sha256};

use crate::studiomodel::STUDIO_MODEL_PACKAGE_VERSION;

pub const SOURCE_MODEL_MOUNT_PLAN_VERSION: u32 = 1;

const VPK_SIGNATURE: u32 = 0x55aa_1234;
const VPK_EMBEDDED_ARCHIVE_INDEX: u16 = 0x7fff;

const DEFAULT_MAX_MDL_BYTES: usize = 64 * 1024 * 1024;
const DEFAULT_MAX_VVD_BYTES: usize = 256 * 1024 * 1024;
const DEFAULT_MAX_VTX_BYTES: usize = 256 * 1024 * 1024;
const DEFAULT_MAX_PHY_BYTES: usize = 64 * 1024 * 1024;
const DEFAULT_MAX_ANI_BYTES: usize = 256 * 1024 * 1024;
const DEFAULT_MAX_MODEL_BYTES: usize = 512 * 1024 * 1024;

#[derive(Debug, Clone, Copy)]
pub struct SourceModelResolverLimits {
    pub max_mdl_bytes: usize,
    pub max_vvd_bytes: usize,
    pub max_vtx_bytes: usize,
    pub max_phy_bytes: usize,
    pub max_ani_bytes: usize,
    pub max_model_bytes: usize,
}

impl Default for SourceModelResolverLimits {
    fn default() -> Self {
        Self {
            max_mdl_bytes: DEFAULT_MAX_MDL_BYTES,
            max_vvd_bytes: DEFAULT_MAX_VVD_BYTES,
            max_vtx_bytes: DEFAULT_MAX_VTX_BYTES,
            max_phy_bytes: DEFAULT_MAX_PHY_BYTES,
            max_ani_bytes: DEFAULT_MAX_ANI_BYTES,
            max_model_bytes: DEFAULT_MAX_MODEL_BYTES,
        }
    }
}

#[derive(Debug, Clone)]
pub struct ResolvedStudioModel {
    pub source_path: String,
    pub mdl: Vec<u8>,
    pub vvd: Vec<u8>,
    pub vtx: Vec<u8>,
    pub ani: Option<Vec<u8>>,
    pub phy: Option<Vec<u8>>,
    pub vtx_path: String,
    pub package_content_hash: String,
}

#[derive(Debug, Clone)]
struct IndexedAsset {
    source: IndexedSource,
    length: usize,
}

#[derive(Debug, Clone)]
enum IndexedSource {
    Directory(PathBuf),
    Vpk {
        path: PathBuf,
        offset: u64,
        length: usize,
        preload: Vec<u8>,
        crc: u32,
    },
}

#[derive(Debug)]
struct ResolverState {
    requests: usize,
}

pub struct MountedModelResolver {
    assets: HashMap<String, IndexedAsset>,
    limits: SourceModelResolverLimits,
    state: Mutex<ResolverState>,
}

impl MountedModelResolver {
    pub fn new(limits: SourceModelResolverLimits) -> Self {
        Self {
            assets: HashMap::new(),
            limits,
            state: Mutex::new(ResolverState { requests: 0 }),
        }
    }

    pub fn limits(&self) -> SourceModelResolverLimits {
        self.limits
    }

    pub fn asset_count(&self) -> usize {
        self.assets.len()
    }

    pub fn mount_directory(&mut self, root: impl AsRef<Path>) -> Result<usize, String> {
        let root = root.as_ref();
        let models = root.join("models");

        if !models.is_dir() {
            return Err(format!(
                "model mount does not contain a models directory: {}",
                models.display()
            ));
        }

        let mut discovered = Vec::new();
        collect_directory_assets(&models, &models, &mut discovered)?;

        self.insert_mount_assets(discovered)
    }

    pub fn mount_vpk(&mut self, path: impl AsRef<Path>) -> Result<usize, String> {
        let path = path.as_ref();
        let data = fs::read(path)
            .map_err(|error| format!("failed to read VPK {}: {error}", path.display()))?;

        let entries = parse_vpk(&data, path)?;

        let mut discovered = Vec::new();

        for entry in entries {
            if !is_model_resource(&entry.path) {
                continue;
            }

            discovered.push((
                entry.path,
                IndexedAsset {
                    source: IndexedSource::Vpk {
                        path: entry.archive_path,
                        offset: entry.offset,
                        length: entry.length,
                        preload: entry.preload,
                        crc: entry.crc,
                    },
                    length: entry.length + entry.preload_len,
                },
            ));
        }

        self.insert_mount_assets(discovered)
    }

    pub fn resolve(&self, source_path: &str) -> Result<ResolvedStudioModel, String> {
        let source_path = normalize_model_request_path(source_path)?;

        if !source_path.ends_with(".mdl") {
            return Err(format!("model path must end with .mdl: {source_path}"));
        }

        {
            let mut state = self
                .state
                .lock()
                .map_err(|_| "model resolver state lock poisoned".to_string())?;
            state.requests = state.requests.saturating_add(1);
        }

        let mdl = self.read_required(&source_path, self.limits.max_mdl_bytes)?;

        let stem = source_path
            .strip_suffix(".mdl")
            .ok_or_else(|| "invalid model path".to_string())?;

        let vvd_path = format!("{stem}.vvd");

        let vtx_candidates = [
            format!("{stem}.dx90.vtx"),
            format!("{stem}.dx80.vtx"),
            format!("{stem}.sw.vtx"),
        ];

        let vvd = self.read_required(&vvd_path, self.limits.max_vvd_bytes)?;

        let mut selected_vtx = None;
        let mut vtx = None;

        for candidate in vtx_candidates {
            if self.assets.contains_key(&candidate) {
                let bytes = self.read_required(&candidate, self.limits.max_vtx_bytes)?;
                selected_vtx = Some(candidate);
                vtx = Some(bytes);
                break;
            }
        }

        let vtx_path = selected_vtx.ok_or_else(|| {
            format!(
                "no supported VTX companion found for {source_path} \
                 (tried .dx90.vtx, .dx80.vtx, .sw.vtx)"
            )
        })?;

        let phy_path = format!("{stem}.phy");
        let ani_path = format!("{stem}.ani");

        let phy = self.read_optional(&phy_path, self.limits.max_phy_bytes)?;
        let ani = self.read_optional(&ani_path, self.limits.max_ani_bytes)?;

        let vtx = vtx.expect("VTX selected immediately before assignment");

        let total = mdl
            .len()
            .saturating_add(vvd.len())
            .saturating_add(vtx.len())
            .saturating_add(phy.as_ref().map_or(0, Vec::len))
            .saturating_add(ani.as_ref().map_or(0, Vec::len));

        if total > self.limits.max_model_bytes {
            return Err(format!(
                "resolved model exceeds total byte limit: {} > {}",
                total, self.limits.max_model_bytes
            ));
        }

        let package_content_hash = hash_model_package(
            &source_path,
            0,
            &mdl,
            &vvd,
            &vtx,
            ani.as_deref(),
            phy.as_deref(),
        );

        Ok(ResolvedStudioModel {
            source_path,
            mdl,
            vvd,
            vtx,
            ani,
            phy,
            vtx_path,
            package_content_hash,
        })
    }

    fn insert_mount_assets(
        &mut self,
        discovered: Vec<(String, IndexedAsset)>,
    ) -> Result<usize, String> {
        let mut seen = HashSet::new();

        for (path, _) in &discovered {
            if !seen.insert(path.clone()) {
                return Err(format!("duplicate model resource in mount: {path}"));
            }
        }

        let mut inserted = 0;

        for (path, asset) in discovered {
            // First mounted asset wins, matching the existing material
            // resolver's mount semantics.
            if self.assets.contains_key(&path) {
                continue;
            }

            self.assets.insert(path, asset);
            inserted += 1;
        }

        Ok(inserted)
    }

    fn read_required(&self, path: &str, limit: usize) -> Result<Vec<u8>, String> {
        self.read(path)?
            .ok_or_else(|| format!("required model asset not found: {path}"))
            .and_then(|bytes| {
                if bytes.len() > limit {
                    Err(format!(
                        "model asset exceeds byte limit: {path} ({} > {})",
                        bytes.len(),
                        limit
                    ))
                } else {
                    Ok(bytes)
                }
            })
    }

    fn read_optional(&self, path: &str, limit: usize) -> Result<Option<Vec<u8>>, String> {
        let Some(bytes) = self.read(path)? else {
            return Ok(None);
        };

        if bytes.len() > limit {
            return Err(format!(
                "model asset exceeds byte limit: {path} ({} > {})",
                bytes.len(),
                limit
            ));
        }

        Ok(Some(bytes))
    }

    fn read(&self, path: &str) -> Result<Option<Vec<u8>>, String> {
        let Some(asset) = self.assets.get(path) else {
            return Ok(None);
        };

        match &asset.source {
            IndexedSource::Directory(path) => {
                let bytes = fs::read(path)
                    .map_err(|error| format!("failed to read {}: {error}", path.display()))?;

                if bytes.len() != asset.length {
                    return Err(format!(
                        "model asset size changed after indexing: {}",
                        path.display()
                    ));
                }

                Ok(Some(bytes))
            }
            IndexedSource::Vpk {
                path,
                offset,
                length,
                preload,
                crc,
            } => {
                let mut file = fs::File::open(path)
                    .map_err(|error| format!("failed to open VPK {}: {error}", path.display()))?;

                let file_len = file
                    .metadata()
                    .map_err(|error| format!("failed to stat VPK {}: {error}", path.display()))?
                    .len();

                let end = offset
                    .checked_add(*length as u64)
                    .ok_or_else(|| "VPK asset range overflow".to_string())?;

                if end > file_len {
                    return Err(format!(
                        "VPK asset range exceeds archive: {}",
                        path.display()
                    ));
                }

                file.seek(SeekFrom::Start(*offset))
                    .map_err(|error| format!("failed to seek VPK {}: {error}", path.display()))?;

                let mut payload = vec![0u8; *length];
                file.read_exact(&mut payload)
                    .map_err(|error| format!("failed to read VPK {}: {error}", path.display()))?;

                let mut bytes = Vec::with_capacity(preload.len() + *length);
                bytes.extend_from_slice(preload);
                bytes.extend_from_slice(&payload);

                let actual_crc = crc32fast::hash(&bytes);
                if actual_crc != *crc {
                    return Err(format!(
                        "VPK CRC mismatch for indexed model asset: expected {:08x}, got {:08x}",
                        crc, actual_crc
                    ));
                }

                Ok(Some(bytes))
            }
        }
    }
}

fn collect_directory_assets(
    root: &Path,
    current: &Path,
    output: &mut Vec<(String, IndexedAsset)>,
) -> Result<(), String> {
    let entries = fs::read_dir(current)
        .map_err(|error| format!("failed to read {}: {error}", current.display()))?;

    for entry in entries {
        let entry =
            entry.map_err(|error| format!("failed to enumerate {}: {error}", current.display()))?;

        let path = entry.path();
        let file_type = entry
            .file_type()
            .map_err(|error| format!("failed to inspect {}: {error}", path.display()))?;

        if file_type.is_dir() {
            collect_directory_assets(root, &path, output)?;
            continue;
        }

        if !file_type.is_file() {
            continue;
        }

        let relative = path
            .strip_prefix(root)
            .map_err(|_| format!("failed to relativize {}", path.display()))?;

        let normalized = normalize_model_resource_path(&relative.to_string_lossy())?;

        if !is_model_resource(&normalized) {
            continue;
        }

        let metadata = fs::metadata(&path)
            .map_err(|error| format!("failed to stat {}: {error}", path.display()))?;

        let length = usize::try_from(metadata.len())
            .map_err(|_| format!("file too large for platform usize: {}", path.display()))?;

        output.push((
            normalized,
            IndexedAsset {
                source: IndexedSource::Directory(path),
                length,
            },
        ));
    }

    Ok(())
}

#[derive(Debug)]
struct VpkEntry {
    path: String,
    crc: u32,
    preload: Vec<u8>,
    preload_len: usize,
    archive_path: PathBuf,
    offset: u64,
    length: usize,
}

fn parse_vpk(data: &[u8], path: &Path) -> Result<Vec<VpkEntry>, String> {
    if data.len() < 12 {
        return Err(format!("VPK is too small: {}", path.display()));
    }

    let signature = read_u32(data, 0)?;
    if signature != VPK_SIGNATURE {
        return Err(format!("invalid VPK signature: {}", path.display()));
    }

    let version = read_u32(data, 4)?;
    let tree_size = read_u32(data, 8)? as usize;

    let (tree_offset, embedded_base) = match version {
        1 => (12usize, 12usize),
        2 => {
            if data.len() < 28 {
                return Err(format!("VPK v2 header is truncated: {}", path.display()));
            }

            (28usize, 28usize)
        }
        _ => {
            return Err(format!(
                "unsupported VPK version {version}: {}",
                path.display()
            ));
        }
    };

    let tree_end = tree_offset
        .checked_add(tree_size)
        .ok_or_else(|| "VPK tree range overflow".to_string())?;

    if tree_end > data.len() {
        return Err(format!("VPK tree exceeds archive: {}", path.display()));
    }

    let tree = &data[tree_offset..tree_end];
    let mut cursor = 0usize;
    let mut entries = Vec::new();

    loop {
        let extension = read_vpk_string(tree, &mut cursor)?;
        if extension.is_empty() {
            break;
        }

        loop {
            let directory = read_vpk_string(tree, &mut cursor)?;
            if directory.is_empty() {
                break;
            }

            loop {
                let name = read_vpk_string(tree, &mut cursor)?;
                if name.is_empty() {
                    break;
                }

                if cursor + 18 > tree.len() {
                    return Err(format!("truncated VPK entry in {}", path.display()));
                }

                let crc = read_u32(tree, cursor)?;
                let preload_length = read_u16(tree, cursor + 4)? as usize;
                let archive_index = read_u16(tree, cursor + 6)?;
                let entry_offset = read_u32(tree, cursor + 8)? as u64;
                let entry_length = read_u32(tree, cursor + 12)? as usize;
                let terminator = read_u16(tree, cursor + 16)?;

                cursor += 18;

                if terminator != 0xffff {
                    return Err(format!(
                        "invalid VPK entry terminator in {}",
                        path.display()
                    ));
                }

                if cursor + preload_length > tree.len() {
                    return Err(format!("VPK preload exceeds tree in {}", path.display()));
                }

                let preload = tree[cursor..cursor + preload_length].to_vec();
                cursor += preload_length;

                let directory = if directory == " " {
                    String::new()
                } else {
                    directory.to_string()
                };

                let resource_path = if directory.is_empty() {
                    format!("{name}.{extension}")
                } else {
                    format!("{directory}/{name}.{extension}")
                };

                let (archive_path, archive_offset) = if archive_index == VPK_EMBEDDED_ARCHIVE_INDEX
                {
                    (path.to_path_buf(), embedded_base as u64 + entry_offset)
                } else {
                    let file_stem = path
                        .file_stem()
                        .and_then(|value| value.to_str())
                        .ok_or_else(|| format!("invalid VPK filename: {}", path.display()))?;

                    let stem = file_stem.strip_suffix("_dir").unwrap_or(file_stem);

                    let archive_path = path
                        .parent()
                        .unwrap_or_else(|| Path::new("."))
                        .join(format!("{stem}_{archive_index:03}.vpk"));

                    (archive_path, entry_offset)
                };

                entries.push(VpkEntry {
                    path: normalize_model_resource_path(&resource_path)?,
                    crc,
                    preload_len: preload_length,
                    preload,
                    archive_path,
                    offset: archive_offset,
                    length: entry_length,
                });
            }
        }
    }

    Ok(entries)
}

fn read_vpk_string<'a>(data: &'a [u8], cursor: &mut usize) -> Result<&'a str, String> {
    let start = *cursor;

    while *cursor < data.len() && data[*cursor] != 0 {
        *cursor += 1;
    }

    if *cursor >= data.len() {
        return Err("unterminated VPK tree string".to_string());
    }

    let value = std::str::from_utf8(&data[start..*cursor])
        .map_err(|_| "VPK tree contains invalid UTF-8".to_string())?;

    *cursor += 1;
    Ok(value)
}

fn read_u16(data: &[u8], offset: usize) -> Result<u16, String> {
    let bytes = data
        .get(offset..offset + 2)
        .ok_or_else(|| "unexpected end of binary data".to_string())?;

    Ok(u16::from_le_bytes([bytes[0], bytes[1]]))
}

fn read_u32(data: &[u8], offset: usize) -> Result<u32, String> {
    let bytes = data
        .get(offset..offset + 4)
        .ok_or_else(|| "unexpected end of binary data".to_string())?;

    Ok(u32::from_le_bytes([bytes[0], bytes[1], bytes[2], bytes[3]]))
}

fn is_model_resource(path: &str) -> bool {
    [
        ".mdl",
        ".vvd",
        ".dx90.vtx",
        ".dx80.vtx",
        ".sw.vtx",
        ".phy",
        ".ani",
    ]
    .iter()
    .any(|extension| path.ends_with(extension))
}

fn normalize_model_request_path(path: &str) -> Result<String, String> {
    let normalized = normalize_model_resource_path(path)?;

    if !normalized.starts_with("models/") {
        return Err(format!("model path must be under models/: {normalized}"));
    }

    Ok(normalized)
}

fn normalize_model_resource_path(path: &str) -> Result<String, String> {
    let path = path.replace('\\', "/");

    if path.is_empty()
        || path.starts_with('/')
        || path.contains(':')
        || path.split('/').any(|component| component == "..")
    {
        return Err(format!("invalid model resource path: {path}"));
    }

    let normalized = path
        .split('/')
        .filter(|component| !component.is_empty() && *component != ".")
        .collect::<Vec<_>>()
        .join("/");

    if normalized.is_empty() {
        return Err("empty model resource path".to_string());
    }

    Ok(normalized.to_ascii_lowercase())
}

fn hash_model_package(
    source_path: &str,
    skin: usize,
    mdl: &[u8],
    vvd: &[u8],
    vtx: &[u8],
    ani: Option<&[u8]>,
    phy: Option<&[u8]>,
) -> String {
    let mut hash = Sha256::new();
    hash.update(STUDIO_MODEL_PACKAGE_VERSION.to_le_bytes());
    hash.update(source_path.as_bytes());
    hash.update([0]);
    hash.update((skin as u64).to_le_bytes());

    for (role, bytes) in [
        (b"mdl".as_slice(), mdl),
        (b"vvd".as_slice(), vvd),
        (b"vtx".as_slice(), vtx),
    ] {
        hash.update(role);
        hash.update((bytes.len() as u64).to_le_bytes());
        hash.update(bytes);
    }

    for (role, bytes) in [(b"ani".as_slice(), ani), (b"phy".as_slice(), phy)] {
        hash.update(role);
        if let Some(bytes) = bytes {
            hash.update((bytes.len() as u64).to_le_bytes());
            hash.update(bytes);
        } else {
            hash.update(0_u64.to_le_bytes());
        }
    }

    format!("{:x}", hash.finalize())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn normalizes_model_paths() {
        assert_eq!(
            normalize_model_request_path("models\\Props\\Tree.MDL").unwrap(),
            "models/props/tree.mdl"
        );
    }

    #[test]
    fn rejects_model_paths_outside_models() {
        assert!(normalize_model_request_path("materials/foo.mdl").is_err());
        assert!(normalize_model_request_path("../models/foo.mdl").is_err());
        assert!(normalize_model_request_path("/models/foo.mdl").is_err());
    }

    #[test]
    fn identifies_model_resources() {
        assert!(is_model_resource("models/foo.mdl"));
        assert!(is_model_resource("models/foo.vvd"));
        assert!(is_model_resource("models/foo.dx90.vtx"));
        assert!(is_model_resource("models/foo.dx80.vtx"));
        assert!(is_model_resource("models/foo.sw.vtx"));
        assert!(is_model_resource("models/foo.phy"));
        assert!(is_model_resource("models/foo.ani"));
        assert!(!is_model_resource("materials/foo.vtf"));
    }

    #[test]
    fn model_hash_is_deterministic() {
        let a = hash_model_package("models/test.mdl", 0, b"mdl", b"vvd", b"vtx", None, None);
        let b = hash_model_package("models/test.mdl", 0, b"mdl", b"vvd", b"vtx", None, None);

        assert_eq!(a, b);
        assert_eq!(a.len(), 64);
    }

    #[test]
    fn first_mount_wins() {
        let mut resolver = MountedModelResolver::default();

        resolver.assets.insert(
            "models/foo.mdl".to_string(),
            IndexedAsset {
                source: IndexedSource::Directory(PathBuf::from("/first")),
                length: 1,
            },
        );

        resolver
            .insert_mount_assets(vec![(
                "models/foo.mdl".to_string(),
                IndexedAsset {
                    source: IndexedSource::Directory(PathBuf::from("/second")),
                    length: 2,
                },
            )])
            .unwrap();

        match &resolver.assets["models/foo.mdl"].source {
            IndexedSource::Directory(path) => assert_eq!(path, &PathBuf::from("/first")),
            _ => panic!("expected directory source"),
        }
    }

    #[test]
    fn duplicate_paths_inside_mount_are_rejected() {
        let mut resolver = MountedModelResolver::default();

        let result = resolver.insert_mount_assets(vec![
            (
                "models/foo.mdl".to_string(),
                IndexedAsset {
                    source: IndexedSource::Directory(PathBuf::from("/a")),
                    length: 1,
                },
            ),
            (
                "models/foo.mdl".to_string(),
                IndexedAsset {
                    source: IndexedSource::Directory(PathBuf::from("/b")),
                    length: 1,
                },
            ),
        ]);

        assert!(result.is_err());
    }
}

impl Default for MountedModelResolver {
    fn default() -> Self {
        Self::new(SourceModelResolverLimits::default())
    }
}
