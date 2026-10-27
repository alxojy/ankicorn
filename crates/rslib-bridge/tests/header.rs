//! The hand-written C header must declare exactly the functions the crate exports.

use std::collections::BTreeSet;

fn exported_functions() -> BTreeSet<String> {
    let src = include_str!("../src/lib.rs");
    let mut names = BTreeSet::new();
    let mut lines = src.lines().peekable();
    while let Some(line) = lines.next() {
        if line.trim() == "#[no_mangle]" {
            let decl = lines.peek().expect("declaration after #[no_mangle]");
            let after = decl.split(" fn ").nth(1).expect("an fn declaration");
            names.insert(after.split('(').next().unwrap().to_string());
        }
    }
    names
}

fn declared_functions() -> BTreeSet<String> {
    let header: String = include_str!("../rslib_bridge.h")
        .lines()
        .filter(|line| !line.trim_start().starts_with("//"))
        .collect::<Vec<_>>()
        .join("\n");
    let mut names = BTreeSet::new();
    for stmt in header.split(';') {
        // Function declarations have a parameter list and are not typedefs.
        let Some((head, _)) = stmt.split_once('(') else {
            continue;
        };
        if head.contains("typedef") || head.contains('{') {
            continue;
        }
        if let Some(name) = head.split_whitespace().last() {
            names.insert(name.trim_start_matches('*').to_string());
        }
    }
    names
}

#[test]
fn header_declares_exactly_the_exported_functions() {
    let exported = exported_functions();
    assert_eq!(
        exported,
        ["close_backend", "free_bytes", "open_backend", "run_method"]
            .map(String::from)
            .into_iter()
            .collect()
    );
    assert_eq!(declared_functions(), exported);
}

#[test]
fn exported_symbols_exist_in_the_library() {
    // Taking each address makes the linker prove the symbols are there.
    let _: [*const (); 4] = [
        rslib_bridge::open_backend as *const (),
        rslib_bridge::run_method as *const (),
        rslib_bridge::free_bytes as *const (),
        rslib_bridge::close_backend as *const (),
    ];
}
