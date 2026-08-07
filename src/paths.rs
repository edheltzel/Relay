//! Resolution and ownership of Relay-managed runtime paths.

use std::ffi::OsStr;
use std::path::{Path, PathBuf};

use anyhow::{bail, Context, Result};

use crate::util::expand_home;

pub const RELAY_HOME_ENV: &str = "RELAY_HOME";

#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct RelayPaths {
    pub root: PathBuf,
    pub config: PathBuf,
    pub database: PathBuf,
    pub state: PathBuf,
    pub audit: PathBuf,
    pub jobs_run: PathBuf,
    pub inbox: PathBuf,
    pub cache: PathBuf,
}

impl RelayPaths {
    pub fn discover() -> Result<Self> {
        Self::resolve(
            std::env::var_os(RELAY_HOME_ENV).as_deref(),
            std::env::var_os("HOME").as_deref(),
        )
    }

    pub fn from_root(root: PathBuf) -> Result<Self> {
        if root.as_os_str().is_empty() {
            bail!("Relay home cannot be empty");
        }
        if !root.is_absolute() {
            bail!("Relay home must be an absolute path: {}", root.display());
        }
        Ok(Self {
            config: root.join("config.toml"),
            database: root.join("relay.db"),
            state: root.join("state.json"),
            audit: root.join("audit.jsonl"),
            jobs_run: root.join("run"),
            inbox: slack_inbox_for_state(&root.join("state.json")),
            cache: root.join("cache"),
            root,
        })
    }

    pub fn with_overrides(
        mut self,
        state: Option<&str>,
        database: Option<&str>,
        audit: Option<&str>,
        jobs_run: Option<&str>,
    ) -> Result<Self> {
        if let Some(value) = state {
            self.state = configured_path("state_path", value)?;
            self.inbox = slack_inbox_for_state(&self.state);
        }
        if let Some(value) = database {
            self.database = configured_path("database_path", value)?;
        }
        if let Some(value) = audit {
            self.audit = configured_path("audit_log_path", value)?;
        }
        if let Some(value) = jobs_run {
            self.jobs_run = configured_path("jobs_run_dir", value)?;
        }
        Ok(self)
    }

    fn resolve(relay_home: Option<&OsStr>, home: Option<&OsStr>) -> Result<Self> {
        let root = match relay_home {
            Some(value) => {
                if value.is_empty() {
                    bail!("{RELAY_HOME_ENV} cannot be empty");
                }
                PathBuf::from(value)
            }
            None => {
                let home = home
                    .filter(|value| !value.is_empty())
                    .context("HOME is not set; set RELAY_HOME to an absolute runtime directory")?;
                Path::new(home).join(".relay")
            }
        };
        Self::from_root(root).with_context(|| format!("resolve {RELAY_HOME_ENV}"))
    }
}

fn configured_path(label: &str, value: &str) -> Result<PathBuf> {
    if value.trim().is_empty() {
        bail!("{label} cannot be empty");
    }
    let expanded = expand_home(value);
    if expanded.starts_with('~') {
        bail!("cannot expand {label} {value:?}; set HOME or use an absolute path");
    }
    Ok(PathBuf::from(expanded))
}

fn slack_inbox_for_state(state: &Path) -> PathBuf {
    let mut path = state.as_os_str().to_os_string();
    path.push(".slack-inbox.db");
    PathBuf::from(path)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn default_home_derives_every_runtime_path() {
        let paths = RelayPaths::resolve(None, Some(OsStr::new("/Users/example"))).unwrap();

        assert_eq!(paths.root, Path::new("/Users/example/.relay"));
        assert_eq!(paths.config, paths.root.join("config.toml"));
        assert_eq!(paths.database, paths.root.join("relay.db"));
        assert_eq!(paths.state, paths.root.join("state.json"));
        assert_eq!(paths.audit, paths.root.join("audit.jsonl"));
        assert_eq!(paths.jobs_run, paths.root.join("run"));
        assert_eq!(paths.inbox, paths.root.join("state.json.slack-inbox.db"));
        assert_eq!(paths.cache, paths.root.join("cache"));
    }

    #[test]
    fn relay_home_relocates_every_runtime_path() {
        let paths = RelayPaths::resolve(
            Some(OsStr::new("/srv/relay/alice")),
            Some(OsStr::new("/ignored")),
        )
        .unwrap();

        for path in [
            &paths.config,
            &paths.database,
            &paths.state,
            &paths.audit,
            &paths.jobs_run,
            &paths.inbox,
            &paths.cache,
        ] {
            assert!(path.starts_with(&paths.root), "{}", path.display());
        }
        assert_eq!(paths.root, Path::new("/srv/relay/alice"));
    }

    #[test]
    fn explicit_legacy_paths_override_only_their_derived_defaults() {
        let paths = RelayPaths::from_root(PathBuf::from("/srv/relay"))
            .unwrap()
            .with_overrides(
                Some("/legacy/state.json"),
                Some("/legacy/history.db"),
                Some("/legacy/audit.jsonl"),
                Some("/legacy/run"),
            )
            .unwrap();

        assert_eq!(paths.root, Path::new("/srv/relay"));
        assert_eq!(paths.config, Path::new("/srv/relay/config.toml"));
        assert_eq!(paths.state, Path::new("/legacy/state.json"));
        assert_eq!(paths.inbox, Path::new("/legacy/state.json.slack-inbox.db"));
        assert_eq!(paths.database, Path::new("/legacy/history.db"));
        assert_eq!(paths.audit, Path::new("/legacy/audit.jsonl"));
        assert_eq!(paths.jobs_run, Path::new("/legacy/run"));
        assert_eq!(paths.cache, Path::new("/srv/relay/cache"));
    }

    #[test]
    fn missing_home_requires_an_explicit_relay_home() {
        let error = RelayPaths::resolve(None, None).unwrap_err();

        assert!(error.to_string().contains("HOME is not set"));
        assert!(error.to_string().contains("RELAY_HOME"));
    }

    #[test]
    fn two_relay_homes_are_fully_isolated() {
        let first = RelayPaths::from_root(PathBuf::from("/srv/relay/first")).unwrap();
        let second = RelayPaths::from_root(PathBuf::from("/srv/relay/second")).unwrap();

        for first_path in [
            &first.config,
            &first.database,
            &first.state,
            &first.audit,
            &first.jobs_run,
            &first.inbox,
            &first.cache,
        ] {
            assert!(!first_path.starts_with(&second.root));
        }
        for second_path in [
            &second.config,
            &second.database,
            &second.state,
            &second.audit,
            &second.jobs_run,
            &second.inbox,
            &second.cache,
        ] {
            assert!(!second_path.starts_with(&first.root));
        }
    }
}
