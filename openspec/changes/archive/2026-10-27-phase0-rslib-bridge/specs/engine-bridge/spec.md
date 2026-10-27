## ADDED Requirements

### Requirement: Pinned engine
The bridge SHALL be built from `rslib` at the Anki git tag `26.09.3`, vendored as a shallow submodule, and SHALL use Anki's own `Cargo.lock` so dependency versions match that tag.

#### Scenario: Submodule is pinned
- **WHEN** the repository is checked out with its submodules
- **THEN** `third_party/anki` is at the commit of tag `26.09.3`

#### Scenario: Build needs both translation submodules
- **WHEN** the build script runs and `ftl/core-repo` or `ftl/qt-repo` is missing
- **THEN** it initialises them shallowly before building, instead of failing inside `rslib`'s build script

### Requirement: Backend lifecycle
The bridge SHALL create a backend from protobuf `BackendInit` bytes through `open_backend` and SHALL release it through `close_backend`.

#### Scenario: Valid init
- **WHEN** `open_backend` is called with valid `BackendInit` bytes
- **THEN** it returns a non-null handle

#### Scenario: Invalid init
- **WHEN** `open_backend` is called with bytes that are not a valid `BackendInit`
- **THEN** it returns a null handle and does not crash

#### Scenario: Close
- **WHEN** `close_backend` is called with a handle from `open_backend`
- **THEN** the backend is dropped, and calling it with a null handle does nothing

### Requirement: Method calls
`run_method(handle, service, method, input_bytes)` SHALL forward to `rslib`'s `run_service_method` and return a success flag and an output byte buffer. The bridge SHALL NOT interpret request or response bytes.

#### Scenario: Success
- **WHEN** a valid service and method index is called with valid input
- **THEN** the flag is true and the buffer holds the protobuf response

#### Scenario: Engine error
- **WHEN** `rslib` returns an error
- **THEN** the flag is false and the buffer holds the encoded `BackendError` protobuf

#### Scenario: Unknown method
- **WHEN** an out-of-range service or method index is called
- **THEN** the flag is false and the buffer holds an encoded error, without a panic crossing the ABI

### Requirement: Buffer ownership
Every buffer returned by `run_method` SHALL be owned by the bridge and freed only through `free_bytes`.

#### Scenario: Free
- **WHEN** the caller passes a returned buffer back to `free_bytes`
- **THEN** the memory is released exactly once, and an empty or null buffer is accepted

### Requirement: iOS packaging
The build script SHALL produce an XCFramework containing a device slice (`aarch64-apple-ios`) and a simulator slice (`aarch64-apple-ios-sim`) of the bridge static library, plus its C header.

#### Scenario: Both slices
- **WHEN** `scripts/build-xcframework.sh` completes
- **THEN** the XCFramework exists with an `ios-arm64` slice and an `ios-arm64-simulator` slice, and `xcodebuild -create-xcframework` reported success

#### Scenario: Memory limit
- **WHEN** the script runs cargo
- **THEN** it passes `-j2` (or the value of an override variable) and does not run other builds in parallel
