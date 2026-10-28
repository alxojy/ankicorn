//! A full upload from collection A and a full download into a fresh collection B, through the
//! bridge's `run_method`, against rslib's own sync server on localhost. No AnkiWeb traffic: the
//! account is the invented `testuser`.
//!
//! `full_upload_or_download` reopens the collection itself, so B must be usable afterwards
//! without another `open_collection`.

use std::path::Path;
use std::slice;

use anki::backend::Backend;
use anki::sync::http_server::{SimpleServer, SyncServerConfig};
use anki_proto::collection::OpenCollectionRequest;
use anki_proto::notes::{AddNoteRequest, AddNoteResponse, Note};
use anki_proto::notetypes::NotetypeNames;
use anki_proto::search::{SearchRequest, SearchResponse};
use anki_proto::sync::{
    sync_collection_response::ChangesRequired, FullUploadOrDownloadRequest, SyncAuth,
    SyncCollectionRequest, SyncCollectionResponse, SyncLoginRequest,
};
use prost::Message;
use rslib_bridge::{close_backend, free_bytes, open_backend, run_method, ByteBuf};

const SYNC: u32 = 1;
const SYNC_LOGIN: u32 = 3;
const SYNC_COLLECTION: u32 = 5;
const FULL_UPLOAD_OR_DOWNLOAD: u32 = 6;
const COLLECTION: u32 = 3;
const OPEN_COLLECTION: u32 = 0;
const NOTETYPES: u32 = 23;
const GET_NOTETYPE_NAMES: u32 = 8;
const NOTES: u32 = 25;
const ADD_NOTE: u32 = 1;
const SEARCH: u32 = 29;
const SEARCH_NOTES: u32 = 2;
const EMPTY: ByteBuf = ByteBuf {
    ptr: std::ptr::null_mut(),
    len: 0,
    cap: 0,
};

struct Bridge(*mut Backend);

impl Bridge {
    fn new() -> Bridge {
        let init = anki_proto::backend::BackendInit {
            preferred_langs: vec!["en".into()],
            locale_folder_path: String::new(),
            server: false,
        }
        .encode_to_vec();
        // SAFETY: pointer and length come from a live Vec.
        let handle = unsafe { open_backend(init.as_ptr(), init.len()) };
        assert!(!handle.is_null());
        Bridge(handle)
    }

    fn call<M: Message, R: Message + Default>(&self, service: u32, method: u32, input: &M) -> R {
        let input = input.encode_to_vec();
        let mut out = EMPTY;
        // SAFETY: handle is live, input is a live Vec, out is a valid local.
        let ok = unsafe {
            run_method(
                self.0,
                service,
                method,
                input.as_ptr(),
                input.len(),
                &mut out,
            )
        };
        let bytes = if out.ptr.is_null() {
            Vec::new()
        } else {
            // SAFETY: out was filled by run_method.
            unsafe { slice::from_raw_parts(out.ptr, out.len) }.to_vec()
        };
        // SAFETY: out came from run_method and is freed once.
        unsafe { free_bytes(out) };
        if !ok {
            let err = anki_proto::backend::BackendError::decode(bytes.as_slice()).unwrap();
            panic!("service {service} method {method}: {}", err.message);
        }
        R::decode(bytes.as_slice()).unwrap()
    }

    fn open_collection(&self, dir: &Path) {
        let _: anki_proto::generic::Empty = self.call(
            COLLECTION,
            OPEN_COLLECTION,
            &OpenCollectionRequest {
                collection_path: dir.join("collection.anki2").display().to_string(),
                media_folder_path: dir.join("collection.media").display().to_string(),
                media_db_path: dir.join("collection.media.db2").display().to_string(),
            },
        );
    }

    fn note_count(&self, query: &str) -> usize {
        let response: SearchResponse = self.call(
            SEARCH,
            SEARCH_NOTES,
            &SearchRequest {
                search: query.into(),
                order: None,
            },
        );
        response.ids.len()
    }
}

impl Drop for Bridge {
    fn drop(&mut self) {
        // SAFETY: the handle came from open_backend and is closed once.
        unsafe { close_backend(self.0) };
    }
}

fn start_server(base: &Path) -> String {
    std::env::set_var("SYNC_USER1", "testuser:testpass");
    let config = SyncServerConfig {
        host: "127.0.0.1".parse().unwrap(),
        port: 0,
        base_folder: base.to_path_buf(),
        ip_header: anki::sync::http_server::default_ip_header(),
    };
    let (tx, rx) = std::sync::mpsc::channel();
    std::thread::spawn(move || {
        let runtime = tokio::runtime::Runtime::new().unwrap();
        runtime.block_on(async {
            let (addr, server) = SimpleServer::make_server(config).await.unwrap();
            tx.send(addr).unwrap();
            let _ = server.await;
        });
    });
    format!("http://{}/", rx.recv().unwrap())
}

#[test]
fn full_upload_then_full_download_leaves_the_collection_usable() {
    let dir = tempfile::tempdir().unwrap();
    let endpoint = start_server(&dir.path().join("server"));
    let (a_dir, b_dir) = (dir.path().join("a"), dir.path().join("b"));
    std::fs::create_dir_all(&a_dir).unwrap();
    std::fs::create_dir_all(&b_dir).unwrap();

    // Collection A: one note, then log in and upload.
    let a = Bridge::new();
    a.open_collection(&a_dir);
    let names: NotetypeNames = a.call(
        NOTETYPES,
        GET_NOTETYPE_NAMES,
        &anki_proto::generic::Empty {},
    );
    let basic = names.entries.iter().find(|e| e.name == "Basic").unwrap().id;
    let _: AddNoteResponse = a.call(
        NOTES,
        ADD_NOTE,
        &AddNoteRequest {
            note: Some(Note {
                notetype_id: basic,
                fields: vec!["ni hao".into(), "hello".into()],
                ..Default::default()
            }),
            deck_id: 1,
        },
    );
    let auth: SyncAuth = a.call(
        SYNC,
        SYNC_LOGIN,
        &SyncLoginRequest {
            username: "testuser".into(),
            password: "testpass".into(),
            endpoint: Some(endpoint.clone()),
        },
    );
    let auth = SyncAuth {
        endpoint: Some(endpoint),
        ..auth
    };
    let check: SyncCollectionResponse = a.call(
        SYNC,
        SYNC_COLLECTION,
        &SyncCollectionRequest {
            auth: Some(auth.clone()),
            sync_media: false,
        },
    );
    assert_ne!(check.required, ChangesRequired::NoChanges as i32);
    let _: anki_proto::generic::Empty = a.call(
        SYNC,
        FULL_UPLOAD_OR_DOWNLOAD,
        &FullUploadOrDownloadRequest {
            auth: Some(auth.clone()),
            upload: true,
            server_usn: None,
        },
    );
    assert_eq!(a.note_count("ni hao"), 1, "A is usable after its upload");

    // Collection B: fresh and empty. Download, then use it without opening it again.
    let b = Bridge::new();
    b.open_collection(&b_dir);
    assert_eq!(b.note_count("ni hao"), 0);
    let _: anki_proto::generic::Empty = b.call(
        SYNC,
        FULL_UPLOAD_OR_DOWNLOAD,
        &FullUploadOrDownloadRequest {
            auth: Some(auth),
            upload: false,
            server_usn: None,
        },
    );
    assert_eq!(b.note_count("ni hao"), 1, "the note arrived in B");
    assert_eq!(b.note_count("*"), 1);
}
