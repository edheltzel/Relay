# CLI reference

Relay has one gateway command, one diagnostic command, and a small set of job
commands. All commands accept `--config <path>` anywhere in the argument list.
The default is `~/.relay/config.toml`.

| Command | Purpose |
| --- | --- |
| `relay help`, `relay --help` | Print command and option help without loading config or changing files |
| `relay version`, `relay --version`, `relay -V` | Print the installed Relay version without starting the gateway |
| `relay init [path]` | Create and Git-initialize the one assistant repository; defaults to `./assistant` |
| `relay` | Start the configured channel gateway and scheduler |
| `relay doctor` | Validate config, paths, channel requirements, and required backend binaries |
| `relay reload`, `relay restart` | Restart the managed gateway to load updated config |
| `relay job validate` | Validate every installed job; exits non-zero if any are invalid |
| `relay job list` | List valid and invalid jobs with backend or error |
| `relay job show <name>` | Print the parsed installed job |
| `relay job run <name>` | Claim and run one job in the CLI process |
| `relay job runs [<name>]` | Print run and delivery history, optionally for one job |

Examples:

```sh
relay init ~/Code/assistant
relay help
relay version
relay doctor
relay
relay reload
relay job validate
relay job run repo-review
relay job runs repo-review
```

Unknown commands and missing values fail with the accepted command forms. The
CLI does not currently provide shell completion or separate help pages for
subcommands. A `--help` flag anywhere in the argument list prints the global
help shown by `relay --help`.

`relay reload` and its `relay restart` alias target the service definitions documented by Relay:
`com.edheltzel.relay` under launchd on macOS and the `relay.service` user unit
under systemd on Linux. The service definition controls its config path,
environment, and executable; `--config` does not override the service definition
for this command. Run `relay doctor` separately when you want to validate those
settings from the current shell.

`relay init` accepts an empty target, the selected config by itself, or a
complete existing assistant layout. It refuses unrelated and partial non-empty
directories, never overwrites an existing assistant file, persists one
canonical `assistant_root`, and initializes Git when needed.

## Commands sent in chat

These messages are handled by the gateway before backend dispatch:

| Message | Effect |
| --- | --- |
| `/clear`, `/new`, `/reset` | Start a fresh backend session for that conversation |
| `/stop` | Stop the active request; already queued messages continue in order |
| `/help` | Return the available chat commands |

Starting a fresh session preserves canonical history. Relay can seed the new
backend session with bounded recent turns from the exact channel-qualified
conversation.
