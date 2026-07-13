# CLI reference

Relay has one gateway command, one diagnostic command, and a small set of job
commands. All commands accept `--config <path>` anywhere in the argument list.
The default is `config.toml` in the current directory.

| Command | Purpose |
| --- | --- |
| `relay` | Start the configured channel gateway and scheduler |
| `relay doctor` | Validate config, paths, channel requirements, and required backend binaries |
| `relay job validate` | Validate every installed job; exits non-zero if any are invalid |
| `relay job list` | List valid and invalid jobs with backend or error |
| `relay job show <name>` | Print the parsed installed job |
| `relay job run <name>` | Claim and run one job in the CLI process |
| `relay job runs [<name>]` | Print run and delivery history, optionally for one job |

Examples:

```sh
relay doctor --config ~/.config/relay/config.toml
relay --config ~/.config/relay/config.toml
relay job validate --config ~/.config/relay/config.toml
relay --config ~/.config/relay/config.toml job run repo-review
relay job runs repo-review --config ~/.config/relay/config.toml
```

Unknown commands and missing values fail with the accepted command forms. The
CLI does not currently provide shell completion or a generated `--help` page.

## Commands sent in chat

These messages are handled by the gateway before backend dispatch:

| Message | Effect |
| --- | --- |
| `/clear`, `/new`, `/reset` | Start a fresh backend session for that conversation |
| `/help` | Return the available chat commands |

Starting a fresh session preserves canonical history. Relay can seed the new
backend session with bounded recent turns from the exact channel-qualified
conversation.
