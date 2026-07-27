# Relay v0.9.0

- Trust project-local Pi resources for unattended jobs only when the canonical
  working directory is exactly `assistant_root`; external work directories and
  evaluators run with `--no-approve`.
- Create and repair runtime state and audit files with owner-only permissions,
  preserve atomic state replacement, and escape control characters in
  `relay job list` without obscuring printable diagnostics.
- Render Slack replies as `mrkdwn` before bounded chunking, preserving links,
  code, styles, quote prefixes, and escape entities across message boundaries.
- Keep oversized-link fallbacks readable without splitting Slack escape
  entities, closing an edge case still present in upstream v0.9.0.

**Full changelog:** https://github.com/edheltzel/relay/compare/v0.8.2...v0.9.0
