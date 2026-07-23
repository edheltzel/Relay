---
title: "Standardize Relay identity with a clean cutover"
date: 2026-07-23
type: refactor
execution: code
status: active
artifact_contract: ce-unified-plan/v1
artifact_readiness: implementation-ready
brainstorm_required: false
product_contract_source: ce-plan-bootstrap
risk_level: high
review_policy: standard
autonomy: standard
original-request:
  - "Create an in-depth, line-by-line plan to standardize the project's Relay identity without grep/ripgrep replacement discovery."
  - "Use multiple agents, preserve existing case conventions, and change only project identity—not product behavior."
  - "Use a clean cutover and replace com.edheltzel.relay with com.edheltzel.relay."
---

# Standardize Relay identity with a clean cutover

## Goal Capsule

Establish the current, private, standalone repository and every active project-owned identity surface as **Relay** without changing gateway, scheduling, delivery, security, or agent-runtime behavior. The cutover includes the Rust package and binary, CLI copy, runtime paths, service identifiers, release assets, installer, tests, documentation, GitHub repository metadata, retirement of the ineligible Pages configuration, and the local checkout directory.

This is deliberately a **clean cutover**. Relay will not ship a `relay` command alias, read `~/.push`, discover `relay.db`, recognize the old launchd/systemd identifiers, emit duplicate release assets, or add deprecated compatibility code.

## Audit Baseline

Seven read-only agents divided the repository into disjoint ledgers and read all **81 tracked files / 31,089 lines** sequentially to each file's deterministic EOF. They did not use grep, ripgrep, AST search, CodeGraph, or project-wide replacement discovery. Every candidate was classified by context as a project identity, a project-owned path/service/package token, or a generic/historical use that must remain unchanged.

The result is **59 tracked files to modify or rename** and **22 tracked files to preserve unchanged**. The untracked `.codegraph/` index is excluded because it is generated local tooling state, not repository content.

### Changed-file coverage ledger

| Area | Audited files and EOF lines |
|---|---|
| Root/package | `.gitignore` (22), `CONTRIBUTING.md` (19), `Cargo.lock` (2022), `Cargo.toml` (35), `README.md` (147), `RELEASE_NOTES.md` (9), `SECURITY.md` (20), `mkdocs.yml` (99) |
| GitHub/automation | `.github/ISSUE_TEMPLATE/bug_report.yml` (46), `.github/ISSUE_TEMPLATE/config.yml` (5), `.github/ISSUE_TEMPLATE/feature_request.yml` (25), `.github/workflows/ci.yml` (74), `.github/workflows/pages.yml` (46), `.github/workflows/release.yml` (114), `.github/workflows/security.yml` (36) |
| Product/design docs | `docs/architecture.md` (422), `docs/contributing.md` (72), `docs/core-system/design.md` (262), `docs/designing-an-assistant.md` (224), `docs/index.md` (190), `docs/jobs/design.md` (348), `docs/prd.md` (212), `docs/strategy.md` (166), `docs/stylesheets/extra.css` (669) |
| Operator/channel docs | `docs/channels/imessage.md` (110), `docs/configuration.md` (300), `docs/getting-started.md` (184), `docs/jobs.md` (208), `docs/reference/cli.md` (64), `docs/security.md` (116), `docs/services.md` (243), `docs/slack.md` (103), `docs/telegram.md` (154) |
| Distribution/services | `examples/launchd/com.edheltzel.relay.plist` (35), `examples/systemd/relay.service` (16), `install.sh` (116) |
| Core source | `src/assistant.rs` (867), `src/channel.rs` (1017), `src/config.rs` (1041), `src/doctor.rs` (871), `src/main.rs` (1256), `src/soul.rs` (116), `src/util.rs` (56) |
| Runtime/source fixtures | `src/claude.rs` (550), `src/codex.rs` (680), `src/pi.rs` (565), `src/gateway/tests.rs` (2903), `src/gateway/worker.rs` (948), `src/history.rs` (1490), `src/imessage/sender.rs` (138), `src/jobs.rs` (4018), `src/markdown.rs` (255), `src/rehydration.rs` (170), `src/restart.rs` (202), `src/store.rs` (420), `src/test_support.rs` (206) |
| Integration tests | `tests/init_cli.rs` (409), `tests/install.sh` (147), `tests/manual_job_crash.rs` (330) |

### No-change coverage ledger

These files were read to EOF and contain no project-identity surface requiring a rename. They remain byte-for-byte unchanged unless implementation reveals a direct coupling missed by the recorded audit:

- `.github/dependabot.yml` (19), `.github/pull_request_template.md` (19)
- `CODE_OF_CONDUCT.md` (26), `LICENSE` (17), `assistant/SOUL.example.md` (8), `config.toml.example` (31), `requirements-docs.txt` (2)
- `examples/assistant/SOUL.md` (15), `examples/assistant/jobs/daily-inbox-triage.md` (106), `scripts/check-release-version.sh` (35)
- `src/agent.rs` (296), `src/approval.rs` (270), `src/audit.rs` (384), `src/gateway/mod.rs` (1168)
- `src/imessage/attributed_body.rs` (100), `src/imessage/mod.rs` (7), `src/imessage/poller.rs` (238), `src/slack.rs` (1072), `src/telegram.rs` (1082), `src/voice.rs` (458)
- `tests/docs.rs` (126), `tests/release-version.sh` (19)

## Product Contract

### Problem

The project identity is embedded across coupled layers. Renaming only prose or only the binary would leave broken release archives, missing Cargo test binaries, stale configuration paths, invalid service restarts, dead documentation links, mismatched CSS hooks, and CI/security workflows targeting a deleted `main` branch. The repository must move as one identity-preserving cutover.

### Actors and outcomes

- **Operators** install and invoke `relay`, store private runtime data under `~/.relay`, and manage `com.edheltzel.relay` or `relay.service`.
- **Users** see Relay in help/version output, delivery markers, errors, documentation, and examples.
- **Contributors** clone `edheltzel/relay`, build a Cargo package/binary named `relay`, and run unchanged quality checks.
- **Release automation** produces only `relay-v<version>-<target>.tar.gz` archives containing a `relay` executable.
- **Maintainers** retain the original `edheltzel/relay` repository only as a fetch-only upstream and preserve historical Git/release records.

### Requirements

- **R1 — Canonical identity:** Project-owned identity consistently uses `Relay`/`relay`/`RELAY` according to existing case and separator conventions.
- **R2 — Executable/package:** Cargo package and binary names become `relay`; CLI usage, version output, tests, installer, and release packaging agree.
- **R3 — Runtime paths:** Defaults move from `~/.relay/...` to `~/.relay/...`; the default database becomes `relay.db`.
- **R4 — Services:** launchd uses `com.edheltzel.relay`; systemd uses `relay.service`; filenames, runtime constants, examples, tests, logs, and docs agree.
- **R5 — Clean cutover:** No alias, fallback, dual-read, data migration code, compatibility shim, duplicate asset, deprecated path, or old service recognition is added.
- **R6 — Repository/docs:** Active URLs use `edheltzel/relay`; branch-bound URLs and workflow filters use `master`; private-repository documentation remains available in the tracked `docs/` tree and passes the strict local/CI build.
- **R7 — Distribution:** Installer diagnostics, temp files, archive discovery, staged installs, release asset names, and checksums use Relay identity.
- **R8 — Semantic preservation:** Generic Rust APIs (`.push`, `.push_str`), GitHub's `push:` event, ordinary English verbs, external push-notification terminology, and adversarial fixtures remain unchanged.
- **R9 — Exhaustive verification:** Every tracked file is read sequentially to EOF again after implementation, and every surviving old-name token is explicitly justified without grep/ripgrep discovery.

### Acceptance examples

- **AE1:** `relay --version` prints `relay <current-version>`; no legacy project alias is installed or advertised.
- **AE2:** A first run with a clean isolated home resolves `~/.relay/config.toml`, `~/.relay/state.json`, `~/.relay/relay.db`, `~/.relay/audit.jsonl`, and `~/.relay/run`.
- **AE3:** `relay restart` targets `com.edheltzel.relay` on launchd and `relay.service` on systemd.
- **AE4:** A release build emits `relay-v<version>-<target>.tar.gz` with a `relay` binary, and `install.sh` installs it as `~/.local/bin/relay`.
- **AE5:** Documentation builds strictly; active repository/install/example links target `edheltzel/relay` on `master`; CSS appearance is unchanged after synchronized selector renames.
- **AE6:** GitHub reports private standalone repository `edheltzel/relay`, default branch `master`, `origin` pointing to the private repository, no stale public homepage, and fetch-only `upstream` still unable to push.

## Planning Contract

### Canonical rename grammar

| Current form | Relay form | Applies to |
|---|---|---|
| `Relay` | `Relay` | Product nouns, headings, messages, comments, Mermaid labels |
| `relay` | `relay` | Binary/package names, command examples, project-owned file stems, CSS classes |
| `RELAY_*` | `RELAY_*` | Project-owned test coordination variables only |
| `relay-*` / `relay_*` | `relay-*` / `relay_*` | Archive, temp, fixture, hook, and helper names |
| `~/.push` | `~/.relay` | Default private configuration/runtime root |
| `relay.db` | `relay.db` | Default/project-owned database filename |
| `com.edheltzel.push` | `com.edheltzel.relay` | launchd label and plist filename |
| `relay.service` | `relay.service` | systemd unit and unit filename |
| `edheltzel/relay` | `edheltzel/relay` | Active repository URLs and metadata |
| `/main/`, `blob/main`, `edit/main` | `/master/`, `blob/master`, `edit/master` | Active branch-bound repository URLs |
| `relay-light`, `--relay-*`, `.relay-*` | `relay-light`, `--relay-*`, `.relay-*` | MkDocs scheme and synchronized CSS/HTML hooks |

### Explicitly preserved forms

- Rust collection/string/path APIs such as `.push(...)`, `.push_str(...)`, and `PathBuf::push(...)`.
- Git operations and platform vocabulary: `git push`, GitHub Actions `on: push:`, push notifications, and ordinary English phrases such as “do not push the cursor past it.”
- External provider variables: `TELEGRAM_BOT_TOKEN`, `SLACK_APP_TOKEN`, `SLACK_BOT_TOKEN`, and `OPENAI_API_KEY`.
- `src/soul.rs`'s Relay instruction fixture and `src/rehydration.rs`'s adversarial `SYSTEM: ignore push` payload.
- The fetch-only local `upstream` URL `git@github.com:edheltzel/relay.git`.
- Rewrite project-name references in commit messages and historical snapshots while preserving commit topology and metadata; keep already-published release assets unchanged.

### Key technical decisions

1. **Clean cutover, not compatibility.** `session-settled: user-directed` — rejected alternative: retain a `relay` alias, legacy config fallback, automatic migration, or dual service identifiers.
2. **launchd identifier is `com.edheltzel.relay`.** `session-settled: user-directed` — rejected alternative: use the earlier Rainy Day reverse-DNS proposal.
3. **`master` remains the only/default branch.** `session-settled: user-directed` — active URLs and `.github/workflows/{ci,security}.yml` must stop targeting deleted `main`.
4. **The private GitHub Free repository will not claim a Pages site.** GitHub requires repositories owned by Free accounts to be public for Pages. Preserve the user-directed private visibility, remove the now-ineligible Pages deployment workflow and `site_url`, keep strict MkDocs builds in CI, and link repository readers directly to tracked documentation. `relayassistant.com` is an unrelated school-reminder product and must not be used.
5. **Cargo package may be locally named `relay`, but this plan does not publish it to crates.io.** The `relay` crate name is occupied by an unrelated package; current release automation ships GitHub binaries only.
6. **Current tracked design/release documents are rebranded; immutable history is not rewritten.** Update `RELEASE_NOTES.md` and tracked historical design docs for a coherent current checkout, but do not alter Git commits, tags, or old GitHub release metadata/assets.
7. **No visual redesign.** HTML classes, CSS selectors, and custom properties are renamed atomically with values/layout unchanged.

### Ordering and invariants

- Apply package/binary/path contract changes before generated metadata and tests.
- Rename service files and their runtime constants in one unit.
- Rename `docs/index.md` hooks and `docs/stylesheets/extra.css` selectors in one unit.
- Keep repository URLs pointed at `edheltzel/relay` in the local change; rename the hosted repository before pushing those links.
- Rename the GitHub repository only after local build/test/docs verification, then update `origin`, push, and verify CI/security on `master`.
- Rename the local checkout directory last, after all in-repository commands complete.

## Implementation Units

### U1 — Package, CLI, configuration, and bootstrap identity

**Goal:** Establish the single `relay` executable/package and the `.relay` runtime contract at the source of truth.

**Files:**

- `.gitignore:8`
- `Cargo.toml:2,7,10`; regenerate `Cargo.lock` package entry near current line 799
- `src/main.rs:1,34-40,52,68,89-93,127-132,454-455,585,751,790`
- `src/assistant.rs:1,32,40,46,48,135,147,200,205-207,490,556,586,619,666,697,716,731,745,764`
- `src/config.rs:130,146,163,174,182-183,412,428,865,872,878,881,884,887,923`
- `src/doctor.rs:1,102,350,427,777,858`
- `src/soul.rs:6,11` (preserve the stale-instruction fixture at line 78)
- `src/util.rs:44`
- `tests/init_cli.rs:14,27,46,56,72,94,123-124,134,151,154,184,192-194,204,208,263,284,286,328,346,359-360,370,378,393,406`
- `tests/manual_job_crash.rs:13,17,36,88,92,100,123,127,135-136,145,170,190,219,232`

**Approach:**

1. Rename Cargo `[package].name` and `[[bin]].name` to `relay`, and change repository metadata to `https://github.com/edheltzel/relay`.
2. Regenerate rather than hand-maintain the corresponding lockfile package entry.
3. Change CLI banner, usage, version output, init/doctor guidance, default config path, default state/audit/run/database paths, and project-owned temp/config filenames.
4. Standardize test harness references on `CARGO_BIN_EXE_relay` and the private `relay_command` helper at every call site.
5. Preserve unrelated config schema, backend variables, permissions, secret handling, and all ordinary Rust `.push` calls.

**Unit checks:** `cargo metadata --locked --no-deps`; `cargo test --locked --test init_cli`; `cargo test --locked --test manual_job_crash`; smoke `cargo run --locked -- --version` and `cargo run --locked -- --help`.

### U2 — Runtime messages, markers, state artifacts, and source fixtures

**Goal:** Remove the old project identity from runtime-facing copy and project-owned test/state artifacts without changing execution logic.

**Files and audited candidates:**

- `src/channel.rs:15,763,959,1013-1014` — reply marker and fixture stem
- `src/claude.rs:232,243` — `relay-session`
- `src/codex.rs:44` — Relay temp-output stem
- `src/pi.rs:38` — session-recovery message
- `src/gateway/tests.rs:156,183,189,328,593,597,1259,1317,1541`
- `src/gateway/worker.rs:21,189-190,543`
- `src/history.rs:18` — history truncation marker
- `src/imessage/sender.rs:72` — cancellation fixture stem
- `src/jobs.rs:1943,3506-3509,3795` — truncation marker and `RELAY_TEST_CLAIM_*`
- `src/markdown.rs:189,192` — update the active repository-link fixture to Relay; it is not immutable history
- `src/rehydration.rs:10,143` — truncation marker; preserve the adversarial lowercase payload at lines 117/123
- `src/store.rs:226` and `src/test_support.rs:97,106,112` — project-owned fixture/database stems

**Approach:** Rename only identity-bearing strings, constants, private test variables, and fixture names. Do not modify message transport, scheduling, session reconstruction, database schema, retry behavior, or provider APIs.

**Unit checks:** Run focused Rust tests for channel, gateway, history, jobs, markdown, rehydration, and store modules, followed by `cargo test --locked` in final verification.

### U3 — Services, restart behavior, installer, and release artifacts

**Goal:** Make install/restart/release paths agree on Relay and only Relay.

**Files:**

- Rename `examples/launchd/com.edheltzel.relay.plist` to `examples/launchd/com.edheltzel.relay.plist`; update lines 7, 11, 13, 17, 31, 33.
- Rename `examples/systemd/relay.service` to `examples/systemd/relay.service`; update lines 2, 8, 9, 13.
- `src/restart.rs:6-7,97,105,132,147`
- `install.sh:4,9,23,37,58,63,68-71,74,79,85,93,95,99,109,112,115`
- `.github/workflows/release.yml:69,72` and downstream package-derived archive/checksum paths
- `tests/install.sh:12,14,17,21,23,57,88,100,102,105,107,109-110,115,123,129,134,138-139,146`

**Approach:** Unload and remove any installed `com.edheltzel.push`/`relay.service` unit before installing the Relay unit, then rename service labels/files, binary/config/log/env paths, installer diagnostics and temp artifacts, release package stems, archive contents, checksum fixtures, and restart assertions. Produce no old-name service file, symlink, or duplicate release archive.

**Unit checks:** `plutil -lint examples/launchd/com.edheltzel.relay.plist`; `bash tests/install.sh`; inspect a locally generated release archive to prove it contains `relay` and no `relay` binary; prove only the Relay service identifier is loaded/enabled.

### U4 — Root documentation, issue intake, docs shell, and active links

**Goal:** Present one coherent Relay brand across repository entry points and MkDocs without changing content structure or visual design.

**Files and key candidates:**

- `.github/ISSUE_TEMPLATE/bug_report.yml:10,14-15`
- `.github/ISSUE_TEMPLATE/config.yml:4`
- `.github/ISSUE_TEMPLATE/feature_request.yml:17`
- `CONTRIBUTING.md:3`
- `README.md:3,10-11,20,24,30,36,46,56,58,60-62,84,87,93,98,100,113,116-117,122,129-130,134,140`
- `RELEASE_NOTES.md:1,9`
- `SECURITY.md:5,12,19`
- `mkdocs.yml:1,3-6,32,55,97,99`
- `docs/index.md:7-181`, including install URL line 22 and every `relay-*` HTML hook
- `docs/stylesheets/extra.css:1-669`, renaming every `--relay-*` custom property and `.relay-*` selector atomically
- `docs/contributing.md:3-4,63` and repository clone/documentation workflow text

**Approach:**

1. Replace active repo/security/install/docs URLs with `edheltzel/relay` and branch-bound segments with `master`.
2. Remove the obsolete/unrelated `https://relayassistant.com/` target: use repository-relative `docs/index.md` links in README, remove `site_url` from MkDocs, and keep repository metadata free of a homepage until a real Relay site exists.
3. Rename Mermaid node identifiers/labels when they denote the product.
4. Rename MkDocs scheme `relay-light` to `relay-light` and all matching CSS/HTML hooks without changing CSS values or layout.
5. Keep conduct, license, and contribution mechanics unchanged.

**Unit checks:** `mkdocs build --strict`; inspect the rendered home page and navigation; verify all renamed HTML hooks still match a CSS selector.

### U5 — Architecture, strategy, PRD, and design records

**Goal:** Rebrand current tracked design material while preserving every technical claim and historical decision.

**Files:**

- `docs/architecture.md:1-422`
- `docs/core-system/design.md:13-262`
- `docs/designing-an-assistant.md:5,42-55,127,150`
- `docs/jobs/design.md:11-348`
- `docs/prd.md:1-212`
- `docs/strategy.md:1-166`

**Approach:** Replace product nouns, CLI commands, `.push`/`relay.db` paths, diagram node IDs/labels, release/repository URLs, and project-owned example filenames. Do not rewrite requirements, decisions, roadmap scope, or system behavior. Current tracked historical documents become Relay documents; immutable Git history remains the historical record of the old name.

**Unit checks:** Read each modified document from line 1 to its new EOF, validate Mermaid syntax through the strict MkDocs build, and confirm only identity tokens changed.

### U6 — Operator, CLI, service, job, and channel guides

**Goal:** Keep every operational instruction executable after the clean cutover.

**Files and audited ranges:**

- `docs/channels/imessage.md:3,10,14,30,55,57,76,80-83,97`
- `docs/configuration.md:3,7-8,17,22-24,28,44-45,50-60,88,178-181,241-256,291-292`
- `docs/getting-started.md:3-5,14,17-21,38,43,54-61,66,69-76,85,103,113,147-167`
- `docs/jobs.md:3-15,55-57,87-90,104-111,143-152,170-181,185-207`
- `docs/reference/cli.md:3-64`
- `docs/security.md:3-5,23-48,62-83,95-111`
- `docs/services.md:1-237`
- `docs/slack.md:3-99`
- `docs/telegram.md:3-146`

**Approach:** Rename commands, config/runtime/database paths, service identifiers, log/env paths, repo/example links, and product prose. Change branch-bound links and the `testing main` instruction to `master`. Preserve bare generic `state.json`, provider terminology, and ordinary phrases at `docs/channels/imessage.md:80` and `docs/services.md:227` where “push” is a verb.

**Unit checks:** Execute or parse every command/path example that can run locally; cross-check CLI reference output against `relay --help`; build docs strictly.

### U7 — Branch, GitHub, remote, and checkout cutover

**Goal:** Make the hosted repository and local workspace agree with the tracked Relay identity without weakening privacy or upstream safeguards.

**Tracked files:**

- `.github/workflows/ci.yml:5` — `main` to `master`
- Remove `.github/workflows/pages.yml`; the private repository is owned by a GitHub Free account and is not eligible for Pages without changing the user-directed visibility.
- `.github/workflows/security.yml:5` — `main` to `master`
- `docs/contributing.md:63` — replace the stale Pages/`main` statement with strict documentation CI on `master`
- Branch-bound links already touched in `README.md:24,84`, `mkdocs.yml:6`, `docs/index.md:22`, `docs/getting-started.md:43,54`, `docs/jobs.md:151`, `docs/services.md:59,140`

**External operations, after local verification:**

1. Confirm private standalone GitHub repository `edheltzel/relay` without using GitHub's fork operation.
2. Keep default branch `master`; confirm no `main` branch is created.
3. Clear the obsolete `https://relayassistant.com/` repository homepage; retain existing description, private visibility, issues/wiki policy, and merge settings.
4. Update local `origin` fetch/push URL to `git@github.com:edheltzel/relay.git`.
5. Preserve `upstream` fetch URL `git@github.com:edheltzel/relay.git` and push URL `DISABLED`; preserve `remote.pushDefault=origin` and branch-specific push routing.
6. Push `master` and verify CI/security on `master`; confirm the removed Pages workflow does not run.
7. Rename local checkout directory `/Users/ed/Developer/Atlas/Relay` to `/Users/ed/Developer/Atlas/Relay` last; reopen tools/indexes from the new path.

**Unit checks:** GitHub API reports `fork: false`, `private: true`, `default_branch: master`, repository full name `edheltzel/relay`, and no stale homepage; `git fetch --prune upstream` succeeds; `git push --dry-run upstream master` still fails against `DISABLED`; `origin/master` resolves to the expected commit; CI and security workflows run from `master`.

### U8 — Exhaustive post-change audit and verification

**Goal:** Prove the cutover is complete and behavior-preserving, not merely compilable.

**Approach:**

1. Regenerate the tracked-file list and deterministic EOF ledger from the final tree, including this plan and accounting for every file added, removed, or renamed during implementation.
2. Partition every file in that regenerated ledger into disjoint agent assignments; do not freeze the proof to the baseline count of 81.
3. Read every final tracked file sequentially from line 1 through its final EOF. Do not use grep, ripgrep, Git grep, AST search, CodeGraph, or repository-wide replacement output as proof.
4. For each surviving `Relay`/`relay`/`RELAY`, classify it against the explicit preserve list. Any unclassified project-identity survivor reopens its implementation unit.
5. For every baseline no-change file still present, confirm it remained unrelated to the rename after coupled files moved.
6. Review the final diff file by file for accidental prose, behavior, color, schema, permissions, or workflow changes.

## Verification Contract

### Required local quality checks

Run the repository's existing CI contract exactly:

```sh
pip install --requirement requirements-docs.txt
mkdocs build --strict
bash tests/install.sh
bash tests/release-version.sh
cargo fmt --all --check
cargo clippy --locked --all-targets -- -D warnings
cargo build --locked
cargo test --locked
```

Also run the release-path build and metadata checks:

```sh
cargo metadata --locked --no-deps
cargo build --locked --release
plutil -lint examples/launchd/com.edheltzel.relay.plist
```

### Required smoke scenarios

1. **CLI identity:** Built debug and release binaries report `relay`, show only `relay` commands, and contain no advertised `relay` alias.
2. **Clean home:** With an isolated `HOME`, `relay init` creates/targets `.relay` paths and `relay doctor` reports the same paths.
3. **State/history:** A focused job/history/gateway scenario writes `relay.db`, uses Relay truncation/reply markers, and preserves the same database schema and delivery behavior.
4. **Installer:** Fixture install succeeds on supported test paths, preserves an existing `relay` binary on failure/interruption, and leaves no `.relay.install.*` temp files.
5. **Services:** launchd plist parses; restart tests target `com.edheltzel.relay`; systemd expectations target `relay.service`.
6. **Docs/UI:** MkDocs strict build succeeds, the home page styling is visually unchanged, and active links resolve to Relay/master or tracked repository documentation.
7. **Hosted cutover:** GitHub CI/security workflows complete on `master`, the obsolete homepage is cleared, the Pages workflow is absent, and remote safeguards remain intact.

### Failure conditions

The cutover is not complete if any of the following is true:

- A project-owned current surface still advertises Relay, `relay`, `.push`, `relay.db`, the old service label, or `relay.service` without an explicit preserve classification.
- a legacy project alias works or is packaged.
- Runtime code reads or migrates an old path/service implicitly.
- A workflow or active link still targets deleted branch `main`.
- CSS/HTML hook renames change the docs appearance or leave unmatched selectors.
- Existing tests were weakened, deleted, or rewritten to stop asserting the renamed contract.
- GitHub repository rename changes privacy, standalone status, default branch, or fetch-only upstream safeguards.

## Risks and Mitigations

| Risk | Consequence | Mitigation |
|---|---|---|
| Clean path cutover ignores existing `~/.push` data | Existing conversations/state/configuration appear absent | Before deploying Relay on a machine with real data, stop the old service and make an operator-controlled backup/copy of `config.toml`, `state.json`, `audit.jsonl`, and `relay.db` renamed to `relay.db`; rewrite project-owned paths inside the copied config to `.relay`, copy only deliberate run artifacts and no stale locks, verify the copied data, and do not add runtime fallback code. |
| Old service remains installed | Duplicate daemons can race on the same channels/store | Make old-unit unload/disable/removal a required U3 step before installing Relay, then verify exactly one Relay process and no old unit. |
| Package/binary names diverge | Cargo tests or installer cannot find executable | Change Cargo metadata, `CARGO_BIN_EXE_*`, release workflow, installer, and tests in coupled units. |
| Docs CSS hooks diverge | Broken visual design despite successful docs build | Rename markup and CSS atomically; visually smoke-test the built site. |
| Repository links publish before hosted rename | Short-lived 404s | Rename the hosted repository immediately before pushing the already-verified local changes, then validate canonical repository links. |
| `relay` crate/CLI names collide externally | Future package-manager publishing conflict | This cutover ships GitHub binaries only; do not claim crates.io/Homebrew ownership. Revisit distribution naming separately if added later. |
| Deleted `main` remains in automation | CI/security stop running | Update both retained workflow filters plus every audited branch-bound URL/instruction to `master`; remove the ineligible Pages workflow. |
| Private GitHub Free repository cannot publish Pages | A planned docs URL would never deploy | Preserve private visibility, remove Pages/site metadata, keep strict MkDocs builds in CI, and use tracked repository docs until hosting is chosen separately. |

## Out of Scope

- Rewriting Git commits, commit messages, tags, authors, or existing GitHub release metadata/assets.
- Renaming or modifying the original `edheltzel/relay` upstream repository.
- Adding a compatibility alias, automatic migration, legacy fallback, deprecation warning, or duplicate release artifact.
- Changing database schema, message/channel protocols, agent backends, scheduling, retries, permissions, or security behavior.
- Acquiring a domain, publishing to crates.io/Homebrew, or resolving third-party products named Relay.
- Redesigning docs, changing colors/layout, or rewriting strategy/product content beyond identity-bearing tokens.

## Definition of Done

- [ ] All 59 changed tracked files are updated as specified, including both service-file renames.
- [ ] All 22 no-change tracked files are revalidated and remain unrelated/unchanged.
- [ ] The only package and executable identity is `relay`.
- [ ] Default runtime paths are under `~/.relay`, with `relay.db` as the project-owned database filename.
- [ ] launchd/systemd identifiers are `com.edheltzel.relay` and `relay.service` everywhere.
- [ ] Installer and release automation produce/install only Relay-named assets.
- [ ] Current docs, code comments, messages, tests, diagrams, and active links use Relay/master/current owner consistently.
- [ ] Generic/historical survivors are limited to the explicit preserve list and recorded by the post-change line audit.
- [ ] Existing CI commands, release build, smoke scenarios, strict docs build, and service parsing pass.
- [ ] GitHub is private standalone `edheltzel/relay`, default branch `master`, obsolete homepage cleared, ineligible Pages workflow removed, and `upstream` remains fetch-only.
- [ ] Local checkout is reopened at `/Users/ed/Developer/Atlas/Relay`.

## References

- Repository baseline: `README.md`, `Cargo.toml`, `.github/workflows/{ci,pages,release,security}.yml` (the Pages workflow is audited for removal)
- Line audit evidence: seven disjoint agent ledgers covering 81 tracked files / 31,089 lines
- Existing GitHub repository: `https://github.com/edheltzel/relay`
- Original upstream: `https://github.com/edheltzel/relay`
- GitHub Pages eligibility: `https://docs.github.com/en/pages/getting-started-with-github-pages/creating-a-github-pages-site`
- Name-collision evidence: `https://docs.rs/crate/relay/latest` and `https://relayassistant.com/`
