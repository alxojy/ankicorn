//! The root `Cargo.lock` must stay pinned to Anki's own lock file at the vendored tag.
//!
//! Cargo prunes packages the bridge does not use, so the files cannot be byte-identical; instead
//! every package in ours must exist with the same version in Anki's.

use std::collections::BTreeSet;
use std::path::Path;

/// Packages of the `native-tls` backend. Anki's own build uses rustls, so its lock file lacks
/// these; Cargo resolved them for us. Everything else must still match Anki's lock.
const NATIVE_TLS: &[&str] = &[
    "native-tls",
    "openssl",
    "openssl-probe",
    "openssl-sys",
    "schannel",
    "security-framework",
    "security-framework-sys",
    "windows-link",
    "windows-sys",
];

fn packages(lock: &str) -> BTreeSet<(String, String)> {
    let mut set = BTreeSet::new();
    let mut name = None;
    for line in lock.lines() {
        if let Some(rest) = line.strip_prefix("name = ") {
            name = Some(rest.trim_matches('"').to_string());
        } else if let Some(rest) = line.strip_prefix("version = ") {
            if let Some(name) = name.take() {
                set.insert((name, rest.trim_matches('"').to_string()));
            }
        }
    }
    set
}

#[test]
fn root_lock_versions_match_anki_lock() {
    let root = Path::new(env!("CARGO_MANIFEST_DIR")).join("../..");
    let ours = std::fs::read_to_string(root.join("Cargo.lock")).unwrap();
    let anki = std::fs::read_to_string(root.join("third_party/anki/Cargo.lock"))
        .expect("run scripts/setup-engine.sh first");
    let anki = packages(&anki);
    let drifted: Vec<_> = packages(&ours)
        .into_iter()
        .filter(|(name, _)| name != "rslib-bridge")
        .filter(|(name, _)| !NATIVE_TLS.contains(&name.as_str()))
        .filter(|pkg| !anki.contains(pkg))
        .collect();
    assert!(drifted.is_empty(), "not in Anki's Cargo.lock: {drifted:?}");
}
