# Running relay as a Service

This guide covers running `relay` continuously under a process manager.

For v1, the iMessage channel is macOS-only because it reads
`~/Library/Messages/chat.db` and sends replies with `osascript`. Use the
`launchd` setup for daily iMessage use. The `systemd` example is useful only for
environments where the configured channel and credentials are available on
Linux.

## Before Installing a Service

Build or install `relay`, then run doctor from the same user account that will
own the service:

```sh
mkdir -p ~/.config/relay ~/.relay
relay doctor --config /Users/YOU/.config/relay/config.json
```

Use absolute paths in service files. The service user needs:

- access to the configured `config.json`
- write access to `state_path`
- write access to `sessions_dir`
- read access to `assistant_dir`
- access to `claude` or `codex` on `PATH`
- backend login, tokens, settings, MCP config, and project credentials
- for iMessage on macOS, Full Disk Access and `osascript`

`state_path` stores the last completed channel row. `sessions_dir` stores
per-thread backend work directories, and `state.json` stores backend session
ids. Keep both paths on durable storage. Restarting the service resumes after
the last completed row and reuses existing backend sessions when the backend for
that thread has not changed.

## macOS launchd

Create the log directory:

```sh
mkdir -p ~/Library/Logs
```

Create `~/Library/LaunchAgents/com.edheltzel.relay.plist`. You can start from
[`examples/launchd/com.edheltzel.relay.plist`](../examples/launchd/com.edheltzel.relay.plist)
and replace `YOU` with your macOS user name:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.edheltzel.relay</string>

  <key>ProgramArguments</key>
  <array>
    <string>/Users/YOU/.local/bin/relay</string>
    <string>--config</string>
    <string>/Users/YOU/.config/relay/config.json</string>
  </array>

  <key>WorkingDirectory</key>
  <string>/Users/YOU/.relay</string>

  <key>EnvironmentVariables</key>
  <dict>
    <key>PATH</key>
    <string>/Users/YOU/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin</string>
  </dict>

  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>

  <key>StandardOutPath</key>
  <string>/Users/YOU/Library/Logs/relay.out.log</string>
  <key>StandardErrorPath</key>
  <string>/Users/YOU/Library/Logs/relay.err.log</string>
</dict>
</plist>
```

Load and inspect it:

```sh
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.edheltzel.relay.plist
launchctl enable gui/$(id -u)/com.edheltzel.relay
launchctl kickstart -k gui/$(id -u)/com.edheltzel.relay
launchctl print gui/$(id -u)/com.edheltzel.relay
tail -f ~/Library/Logs/relay.err.log ~/Library/Logs/relay.out.log
```

After changing the plist:

```sh
launchctl bootout gui/$(id -u)/com.edheltzel.relay
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.edheltzel.relay.plist
launchctl kickstart -k gui/$(id -u)/com.edheltzel.relay
```

## Linux systemd

Use this only when your configured channel can run on Linux. The v1 iMessage
channel still requires macOS.

Create the service directories:

```sh
mkdir -p ~/.config/relay ~/.config/systemd/user ~/.relay
```

Create `~/.config/systemd/user/relay.service`. You can start from
[`examples/systemd/relay.service`](../examples/systemd/relay.service):

```ini
[Unit]
Description=relay personal assistant gateway
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=%h/.local/bin/relay --config %h/.config/relay/config.json
WorkingDirectory=%h/.relay
Restart=on-failure
RestartSec=10
Environment=PATH=%h/.local/bin:/usr/local/bin:/usr/bin:/bin

[Install]
WantedBy=default.target
```

Load and inspect it:

```sh
systemctl --user daemon-reload
systemctl --user enable --now relay.service
systemctl --user status relay.service
journalctl --user -u relay.service -f
```

For a user service that survives logout, enable lingering:

```sh
loginctl enable-linger "$USER"
```

## Restart Behavior

`relay` only advances `last_row_id` after a message is ignored or completed. If
the process stops during an in-flight backend run, that message can be retried
after restart. This avoids silently losing accepted messages, but it can repeat
backend work or send a duplicate reply if the backend finished and the process
stopped before state was saved.

Ignored messages, completed rows, and setup failures advance the cursor. Rows
newer than an in-flight row do not push the cursor past it until the earlier row
is completed.

## Security Notes

Managed services run without a person watching the terminal. An allowed sender
can instruct the configured backend to use its tools, subject to your backend
settings. Keep `allow_from` narrow, use the least-powerful backend permissions
that still work, and consider Claude Code `claude_tools`,
`claude_allowed_tools`, and `claude_disallowed_tools` when running headlessly.

Store config files, state files, backend credentials, and logs with permissions
appropriate for the service user. Logs may contain prompts, backend errors, file
paths, or message text.
