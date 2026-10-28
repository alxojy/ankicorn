//! The engine must have a TLS backend, or every AnkiWeb request fails as a "network error".
//!
//! Without a TLS feature reqwest's connector refuses `https://` URLs ("scheme is not http"); with one it
//! gets as far as connecting. A closed local port keeps this off the network.

#[tokio::test]
async fn engine_http_client_supports_https() {
    let err = reqwest::Client::new()
        .get("https://127.0.0.1:1/")
        .send()
        .await
        .expect_err("nothing listens on port 1");
    assert!(
        !format!("{err:?}").contains("scheme is not http"),
        "https was rejected before connecting, so reqwest has no TLS backend: {err:?}"
    );
    assert!(err.is_connect(), "expected a connection error: {err}");
}
