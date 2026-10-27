// C ABI of the Cornhub bridge over Anki's rslib. Licensed AGPL-3.0-or-later.
// Keep in sync with src/lib.rs (tests/header.rs checks the function names).
#ifndef RSLIB_BRIDGE_H
#define RSLIB_BRIDGE_H

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

// A byte buffer owned by the bridge. Release it only with free_bytes.
typedef struct ByteBuf {
    uint8_t *ptr;
    size_t len;
    size_t cap;
} ByteBuf;

// Creates a backend from protobuf BackendInit bytes. Returns NULL if they do not decode.
void *open_backend(const uint8_t *init_ptr, size_t init_len);

// Calls a backend service method. On success returns true and *out holds the protobuf response;
// on failure returns false and *out holds an encoded BackendError. *out must be freed with
// free_bytes either way.
bool run_method(const void *handle, uint32_t service, uint32_t method, const uint8_t *in_ptr,
                size_t in_len, ByteBuf *out);

// Frees a buffer returned by run_method. Empty or null buffers are accepted.
void free_bytes(ByteBuf buf);

// Drops a backend created by open_backend. NULL does nothing.
void close_backend(void *handle);

#ifdef __cplusplus
}
#endif

#endif
