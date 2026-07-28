//! Small helpers shared across modules.

use reqwest::{Certificate, Client, ClientBuilder};
use std::path::Path;
use webpki_root_certs::TLS_SERVER_ROOT_CERTS;

/// Expands a leading `~` or `~/` to `$HOME`. Other paths pass through.
pub(crate) fn expand_home(path: &str) -> String {
    if path == "~" || path.starts_with("~/") {
        if let Some(home) = std::env::var_os("HOME") {
            return format!("{}{}", home.to_string_lossy(), &path[1..]);
        }
    }
    path.to_string()
}

/// Milliseconds since the Unix epoch, saturating at `i64::MAX`.
pub(crate) fn now_ms() -> i64 {
    std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .map(|duration| duration.as_millis().min(i64::MAX as u128) as i64)
        .unwrap_or_default()
}

/// Returns the trimmed session id, or `None` when it is empty.
pub(crate) fn non_empty_session_id(id: &str) -> Option<&str> {
    let trimmed = id.trim();
    (!trimmed.is_empty()).then_some(trimmed)
}

/// Whether two metadata snapshots refer to the same underlying file. Used to
/// detect a file being swapped between inspection and open.
#[cfg(unix)]
pub(crate) fn same_file(expected: &std::fs::Metadata, opened: &std::fs::Metadata) -> bool {
    use std::os::unix::fs::MetadataExt;
    expected.dev() == opened.dev() && expected.ino() == opened.ino()
}

#[cfg(not(unix))]
pub(crate) fn same_file(expected: &std::fs::Metadata, opened: &std::fs::Metadata) -> bool {
    expected.len() == opened.len()
        && expected.modified().ok() == opened.modified().ok()
        && opened.is_file()
}

/// Restricts a Relay-owned path to owner-only access (0o700 directories,
/// 0o600 files). A no-op on non-Unix platforms.
#[cfg(unix)]
pub(crate) fn restrict_permissions(path: &Path, directory: bool) -> std::io::Result<()> {
    use std::os::unix::fs::PermissionsExt;
    let mode = if directory { 0o700 } else { 0o600 };
    std::fs::set_permissions(path, std::fs::Permissions::from_mode(mode))
}

#[cfg(not(unix))]
pub(crate) fn restrict_permissions(_path: &Path, _directory: bool) -> std::io::Result<()> {
    Ok(())
}

/// Builds an HTTP client with Relay's fixed Mozilla root set.
pub(crate) fn reqwest_client_builder() -> ClientBuilder {
    let roots = TLS_SERVER_ROOT_CERTS.iter().map(|cert| {
        Certificate::from_der(cert.as_ref()).expect("compiled WebPKI root certificate is valid")
    });
    Client::builder().tls_certs_only(roots)
}

/// Builds an HTTP client with Relay's fixed Mozilla root set.
pub(crate) fn reqwest_client() -> Client {
    reqwest_client_builder()
        .build()
        .expect("build Relay HTTP client")
}
