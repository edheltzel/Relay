# Quickstart

This guide gets one private chat working with one coding-agent backend. Start
with Telegram on macOS or Linux, or iMessage on macOS. Add multiple channels,
routes, and scheduled jobs after the basic path passes `relay doctor`.

## 1. Check the requirements

You need:

- Apple Silicon macOS or x86_64 Linux for the current prebuilt release
- macOS for iMessage, or macOS/Linux for Telegram
- Claude Code, Codex, or Pi installed, authenticated, and runnable by the same
  user that will run Relay
- `curl` and `tar` for the release installer

Relay uses the backend's existing login, settings, tools, MCP servers, skills,
and backend configuration. Each chat runs from a Relay-owned per-thread
directory under `sessions_dir`, not the shell directory that launched Relay.
Use absolute paths when you want the agent to inspect a repository elsewhere.
Confirm the selected command works before starting Relay:

=== "Codex"

    ```sh
    codex --version
    ```

=== "Claude Code"

    ```sh
    claude --version
    ```

=== "Pi"

    ```sh
    pi --version
    ```

## 2. Install Relay

On Apple Silicon macOS or x86_64 Linux, install the latest prebuilt release:

```sh
curl -fsSL https://raw.githubusercontent.com/edheltzel/relay/main/install.sh | sh
```

The binary goes to `~/.local/bin` by default. Add that directory to `PATH` if
your shell does not already include it. The installer recognizes Intel macOS
and ARM Linux, but it exits unless the latest GitHub release contains a matching
archive.

## Build from source

Use this path on other Rust-supported architectures or when testing `main`:

```sh
git clone https://github.com/edheltzel/relay.git
cd relay
cargo build --locked --release
install -m 755 target/release/relay ~/.local/bin/relay
```

## 3. Create your assistant repository

```sh
mkdir -p ~/.config/relay
relay init ~/Code/assistant --config ~/.config/relay/config.toml
```

Relay creates one Git-versioned repository containing `SOUL.md`, `AGENTS.md`,
`README.md`, `context/`, and an empty `jobs/`. It records the canonical root in
the selected config file. Edit `SOUL.md` to define identity and operating style,
then add durable user context under `context/`. Relay reads these files at run
time and never writes machine-specific paths into the repository.

## 4. Configure a channel

=== "Telegram"

    Create a bot with Telegram's `@BotFather`, send it one message, and find
    your stable numeric user ID. Then create `~/.config/relay/config.toml`:

    ```toml
    channel = "telegram"
    agent = "codex"
    assistant_root = "~/Code/assistant"

    [telegram]
    allow_user_ids = [123456789]
    ```

    Export the token in the same environment that starts Relay:

    ```sh
    export TELEGRAM_BOT_TOKEN='token-from-BotFather'
    ```

    Read the [Telegram guide](telegram.md) for token storage, allowlisting,
    topics, and first-run cursor behavior.

=== "iMessage"

    Give the terminal or service host Full Disk Access in macOS System
    Settings, then create `~/.config/relay/config.toml`:

    ```toml
    channel = "imessage"
    agent = "codex"
    assistant_root = "~/Code/assistant"

    [imessage]
    self_handles = ["you@icloud.com"]
    ```

    `self_handles` is for a private conversation with yourself. Use
    `allow_from` to accept one-to-one messages from another trusted handle.
    Read the [iMessage guide](channels/imessage.md) for database permissions
    and filtering behavior.

Replace `codex` with `claude` for Claude Code or `pi` for Pi. Pi must already
have a configured model provider or authenticated account for the service user.

If you replace the config file created by `relay init`, keep its
`assistant_root` setting. Running the same init command again is safe for a
complete assistant repository and restores the setting without overwriting
user files.

## 5. Validate and run

```sh
relay doctor --config ~/.config/relay/config.toml
relay --config ~/.config/relay/config.toml
```

Send a new message after the gateway starts. Telegram deliberately discards
the pending backlog on first run, so an older setup message will not execute.

Try:

> Summarize `/absolute/path/to/my-project/README.md`. Do not change anything.

Replace the example path with a file the service user can read. The default
`restricted` profile makes local filesystem and process access read-only, but
Codex MCP servers keep the capabilities from your Codex configuration. Broader
local access is an explicit configuration choice. Read
[permissions and security](security.md) before enabling writes or inheriting
backend permissions.

## 6. Keep it online

A foreground process stops when its terminal closes. Follow [run as a
service](services.md) to install Relay under `launchd` on macOS or `systemd` for
a Telegram-only Linux host.

## Next steps

- [Configure both channels and per-thread routes](configuration.md)
- [Create a manual or scheduled job](jobs.md)
- [Inspect every CLI command](reference/cli.md)
- [Understand durable state and recovery](architecture.md)
