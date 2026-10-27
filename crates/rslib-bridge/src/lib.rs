//! C ABI over Anki's `rslib`. Four functions: `open_backend`, `run_method`, `free_bytes` and
//! `close_backend`. The bridge never interprets request or response bytes.

use std::panic::{catch_unwind, AssertUnwindSafe};
use std::ptr;
use std::slice;

use anki::backend::{init_backend, Backend};
use anki_proto::backend::{backend_error::Kind, BackendError};
use prost::Message;

/// A byte buffer owned by the bridge: the raw parts of a `Vec<u8>`.
#[repr(C)]
pub struct ByteBuf {
    pub ptr: *mut u8,
    pub len: usize,
    pub cap: usize,
}

impl ByteBuf {
    fn from_vec(mut bytes: Vec<u8>) -> ByteBuf {
        let buf = ByteBuf {
            ptr: bytes.as_mut_ptr(),
            len: bytes.len(),
            cap: bytes.capacity(),
        };
        std::mem::forget(bytes);
        buf
    }
}

/// A caller-supplied pointer and length as a slice; null with length 0 is the empty slice.
///
/// # Safety
/// `ptr` must be valid for reads of `len` bytes for the returned lifetime when non-null.
unsafe fn bytes_in<'a>(ptr: *const u8, len: usize) -> Option<&'a [u8]> {
    if ptr.is_null() {
        return (len == 0).then_some(&[]);
    }
    // SAFETY: guaranteed by the caller.
    Some(unsafe { slice::from_raw_parts(ptr, len) })
}

fn encoded_error(message: String) -> Vec<u8> {
    BackendError {
        message,
        kind: Kind::InvalidInput as i32,
        help_page: None,
        context: String::new(),
        backtrace: String::new(),
    }
    .encode_to_vec()
}

/// Creates a backend from protobuf `BackendInit` bytes. Returns null if they do not decode.
///
/// # Safety
/// `init_ptr` must be null or valid for reads of `init_len` bytes.
#[no_mangle]
pub unsafe extern "C" fn open_backend(init_ptr: *const u8, init_len: usize) -> *mut Backend {
    // SAFETY: forwarded from this function's contract.
    let Some(init) = (unsafe { bytes_in(init_ptr, init_len) }) else {
        return ptr::null_mut();
    };
    match catch_unwind(|| init_backend(init)) {
        Ok(Ok(backend)) => Box::into_raw(Box::new(backend)),
        _ => ptr::null_mut(),
    }
}

/// Calls a backend service method. Returns true with the protobuf response in `*out`, or false
/// with an encoded `BackendError` in `*out`. Free `*out` with `free_bytes` either way.
///
/// # Safety
/// `handle` must come from `open_backend` and not be closed; `in_ptr` must be null or valid for
/// reads of `in_len` bytes; `out` must be valid for writes.
#[no_mangle]
pub unsafe extern "C" fn run_method(
    handle: *const Backend,
    service: u32,
    method: u32,
    in_ptr: *const u8,
    in_len: usize,
    out: *mut ByteBuf,
) -> bool {
    if out.is_null() {
        return false;
    }
    // SAFETY: a non-null handle is a live `Backend` per this function's contract.
    let backend = unsafe { handle.as_ref() };
    // SAFETY: forwarded from this function's contract.
    let input = unsafe { bytes_in(in_ptr, in_len) };
    let result = match (backend, input) {
        (Some(backend), Some(input)) => catch_unwind(AssertUnwindSafe(|| {
            backend.run_service_method(service, method, input)
        }))
        .unwrap_or_else(|_| Err(encoded_error("panic in rslib".into()))),
        _ => Err(encoded_error("null handle or invalid input".into())),
    };
    let (ok, bytes) = match result {
        Ok(bytes) => (true, bytes),
        Err(bytes) => (false, bytes),
    };
    // SAFETY: `out` is non-null and valid for writes per this function's contract.
    unsafe { out.write(ByteBuf::from_vec(bytes)) };
    ok
}

/// Frees a buffer returned by `run_method`. Empty or null buffers are accepted.
///
/// # Safety
/// `buf` must be exactly as returned by `run_method` and not freed before.
#[no_mangle]
pub unsafe extern "C" fn free_bytes(buf: ByteBuf) {
    if buf.ptr.is_null() || buf.cap == 0 {
        return;
    }
    // SAFETY: the parts came from a `Vec<u8>` in `ByteBuf::from_vec` and are freed once.
    drop(unsafe { Vec::from_raw_parts(buf.ptr, buf.len, buf.cap) });
}

/// Drops a backend created by `open_backend`. Null does nothing.
///
/// # Safety
/// `handle` must be null or come from `open_backend`, and not be closed before.
#[no_mangle]
pub unsafe extern "C" fn close_backend(handle: *mut Backend) {
    if !handle.is_null() {
        // SAFETY: the pointer came from `Box::into_raw` in `open_backend` and is dropped once.
        drop(unsafe { Box::from_raw(handle) });
    }
}

#[cfg(test)]
mod tests {
    use anki_proto::generic::String as ProtoString;
    use anki_proto::i18n::format_timespan_request::Context;
    use anki_proto::i18n::FormatTimespanRequest;

    use super::*;

    const EMPTY: ByteBuf = ByteBuf {
        ptr: ptr::null_mut(),
        len: 0,
        cap: 0,
    };

    /// `BackendI18nService` is service index 35 in rslib at tag 26.09.3 (odd indices are the
    /// backend variants of each service); `TranslateString` is method 0, `FormatTimespan` is 1.
    /// Neither needs an open collection.
    const I18N_SERVICE: u32 = 35;
    const TRANSLATE_STRING: u32 = 0;
    const FORMAT_TIMESPAN: u32 = 1;

    fn open() -> *mut Backend {
        let init = anki_proto::backend::BackendInit {
            preferred_langs: vec!["en".into()],
            locale_folder_path: String::new(),
            server: false,
        }
        .encode_to_vec();
        // SAFETY: pointer and length come from a live Vec.
        unsafe { open_backend(init.as_ptr(), init.len()) }
    }

    fn call(handle: *const Backend, service: u32, method: u32, input: &[u8]) -> (bool, Vec<u8>) {
        let mut out = EMPTY;
        // SAFETY: handle is live, input is a live slice, out is a valid local.
        let ok = unsafe {
            run_method(
                handle,
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
        (ok, bytes)
    }

    #[test]
    fn open_with_valid_init_returns_handle_and_close_drops_it() {
        let handle = open();
        assert!(!handle.is_null());
        // SAFETY: handle came from open_backend.
        unsafe { close_backend(handle) };
    }

    #[test]
    fn open_with_invalid_init_returns_null() {
        let bad = [0xff_u8, 0xff, 0xff, 0xff];
        // SAFETY: pointer and length come from a live array.
        assert!(unsafe { open_backend(bad.as_ptr(), bad.len()) }.is_null());
    }

    #[test]
    fn open_with_null_pointer_and_nonzero_length_returns_null() {
        // SAFETY: a null pointer is rejected before any read.
        assert!(unsafe { open_backend(ptr::null(), 4) }.is_null());
    }

    #[test]
    fn close_null_handle_does_nothing() {
        // SAFETY: null is explicitly allowed.
        unsafe { close_backend(ptr::null_mut()) };
    }

    #[test]
    fn run_method_success_returns_protobuf_response() {
        let handle = open();
        let input = FormatTimespanRequest {
            seconds: 120.0,
            context: Context::Precise as i32,
        }
        .encode_to_vec();
        let (ok, bytes) = call(handle, I18N_SERVICE, FORMAT_TIMESPAN, &input);
        assert!(ok);
        let text = ProtoString::decode(bytes.as_slice()).unwrap().val;
        assert!(text.contains("minute"), "unexpected text: {text}");
        // SAFETY: handle came from open_backend.
        unsafe { close_backend(handle) };
    }

    #[test]
    fn run_method_engine_error_decodes_as_backend_error() {
        let handle = open();
        // Not a valid TranslateStringRequest, so the engine returns a protobuf decode error.
        let (ok, bytes) = call(handle, I18N_SERVICE, TRANSLATE_STRING, &[0xff, 0xff, 0xff]);
        assert!(!ok);
        let err = BackendError::decode(bytes.as_slice()).unwrap();
        assert!(!err.message.is_empty());
        // SAFETY: handle came from open_backend.
        unsafe { close_backend(handle) };
    }

    #[test]
    fn run_method_unknown_service_and_method_return_encoded_errors() {
        let handle = open();
        for (service, method) in [(9999, 0), (I18N_SERVICE, 9999)] {
            let (ok, bytes) = call(handle, service, method, &[]);
            assert!(!ok, "service {service} method {method}");
            assert!(BackendError::decode(bytes.as_slice()).is_ok());
        }
        // SAFETY: handle came from open_backend.
        unsafe { close_backend(handle) };
    }

    #[test]
    fn run_method_with_null_handle_returns_encoded_error() {
        let (ok, bytes) = call(ptr::null(), I18N_SERVICE, FORMAT_TIMESPAN, &[]);
        assert!(!ok);
        assert!(BackendError::decode(bytes.as_slice()).is_ok());
    }

    #[test]
    fn free_empty_and_null_buffers_is_accepted() {
        // SAFETY: empty buffers own no memory.
        unsafe {
            free_bytes(EMPTY);
            free_bytes(ByteBuf::from_vec(Vec::new()));
        }
    }
}
