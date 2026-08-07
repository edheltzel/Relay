# Permissions and security

Relay turns messages and schedules into agent runs. That is useful precisely
because the backend can access local tools and data, so configuration is a
security boundary rather than a convenience setting.

## Trust model

An accepted sender is an operator of the configured backend. They may be able
to read files, edit repositories, run commands, call MCP servers, or use local
credentials, depending on the selected agent's settings.

Keep these allowlists narrow:

- `imessage.self_handles` and `imessage.allow_from`
- `telegram.allow_user_ids` and `telegram.allow_chat_ids`
- `slack.allow_user_ids`

Use stable numeric Telegram IDs. Usernames are mutable and are not accepted as
security identities. Treat a lost phone, shared messaging account, or
compromised allowed sender as access to the assistant.
Slack allowlists use stable member IDs, never mutable display names.

## Agent permissions

Relay does not pass sandbox, approval-policy, permission-mode, or tool-list
overrides for chats. The selected agent's own configuration is the permission
source for chat requests.

This makes Relay behave like the agent you already configured, but it also means
every agent-approved capability may be one accepted message away. Review the
agent's tools, MCP servers, filesystem access, shell access, and unattended
approval behavior before running Relay as a service. Pi has no native filesystem
sandbox or interactive permission prompt, so its configured tools deserve
particular care.

Relay rejects old `permission_profile`, `permission_profiles`, and raw backend
permission fields with a migration error. Remove those keys and configure the
selected agent instead.

## Job permissions

Jobs must complete without an interactive approval channel. Relay therefore runs
Codex jobs with full filesystem and network access and no approval prompts, and
runs Claude jobs in `bypassPermissions` mode. Pi already has no native
filesystem sandbox or interactive permission prompt. Evaluators remain
read-only with tools disabled.

This makes job bodies equivalent to unattended code execution as the Relay
service user. The assistant repository is the default work directory. An
explicit work directory must exist. Relay rejects overlap with runtime state and
a loaded config stored outside the assistant repository. Keep allowed senders
and job definitions trusted, and run the service with only the OS permissions
its jobs require.

Do not place secrets in a job body. Make them available through the backend or
service environment using the narrowest policy that works.

## Files to protect

| Path | Contains |
| --- | --- |
| `config.toml` | allowlists, routes, paths, and possibly credentials |
| `<assistant_root>/` | Git-versioned identity, context, evals, jobs, and optional project skills |
| `$RELAY_HOME/relay.db` | conversation history, approvals, job runs, channel cursors, and backend session IDs |
| `$RELAY_HOME/state.json` | retained legacy state; imported once on upgrade and then kept only as a recovery copy |
| `$RELAY_HOME/state.json.slack-inbox.db` | accepted Slack events awaiting processing |
| `$RELAY_HOME/audit.jsonl` | metadata, errors, handles, and optional content |

Keep them on local durable storage with permissions restricted to the service
user. Keep the assistant directory in its own private Git repository. Never
put real config secrets, state, audit logs, or databases in
that repository. An explicit `assistant_root` config stored inside it cannot
contain inline Telegram, Slack, or OpenAI credentials; use the matching environment
variable or move the config outside. When `voice.openai_api_key` is configured,
`relay doctor` requires the config file to be private on Unix:

```sh
chmod 600 ~/.relay/config.toml
```

## Network exposure

Relay opens no inbound server port. iMessage reads local state. Telegram uses
outbound HTTPS long polling and Slack uses an authenticated outbound Socket
Mode WebSocket. Neither needs a webhook.
This reduces exposure, but it does not make an allowed message harmless.

## Durable questions

Bounded `ask_user` questions are stored before delivery, survive restart,
expire, and can be consumed once. Mismatched, duplicate, ambiguous, cancelled,
and expired answers do not reach an agent. Writing a job file does not use this
mechanism; the selected agent's filesystem permissions control access to jobs
in the assistant repository. Activating an enabled schedule does use it: each
new or changed revision is proposed as a durable review question to the bound
allowlisted conversation and stays inactive until that exact revision is
approved. See [jobs and schedules](jobs.md#schedule-a-job).

## Audit log

Relay writes structured JSONL events to `audit_log_path`. By default events
include metadata such as row ID, channel, thread, backend, decision, target,
error, and character counts. Message and reply content are omitted unless
`audit_log_content = true`.

The redacted log is still sensitive because it can contain handles, thread
IDs, file paths, and backend errors. Protect and rotate it like a service log.

## Deployment checklist

- allow only identities you control
- configure the selected agent for unattended use
- run `relay doctor` as the service user
- keep agent credentials out of TOML and all credentials out of logs
- protect config credentials with mode `0600` on Unix
- use absolute config paths in service files
- keep Relay state and job work directories separate
- review agent-authored job changes in the assistant repository
- review the audit log after routing or agent permission changes
