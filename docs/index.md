---
title: Relay documentation
hide:
  - toc
---

<div class="relay-hero" markdown>

<span class="relay-kicker">Lightweight · Open source · Runs on your machine</span>

# Build your own 24/7 AI chief of staff.

Relay turns Claude Code, Codex, or Pi into an always-on personal assistant.
Message it from iMessage, Telegram, or Slack, give it recurring jobs, and let it
handle work in the background.

<p class="relay-actions">
  <a class="md-button md-button--primary" href="getting-started/">Set up your assistant</a>
  <a class="md-button" href="#what-can-it-do">What it can do&nbsp; ↓</a>
</p>

<p class="relay-install">tmp="$(mktemp)" &amp;&amp; (trap 'rm -f "$tmp"' 0; gh api -H "Accept: application/vnd.github.raw+json" 'repos/edheltzel/relay/contents/install.sh?ref=master' &gt;"$tmp" &amp;&amp; sh "$tmp")</p>

<ul class="relay-signals">
  <li><strong>One small binary</strong>No new agent runtime</li>
  <li><strong>Always available</strong>Handles messages and scheduled jobs</li>
  <li><strong>You stay in control</strong>Relay state stays on your machine</li>
</ul>

</div>

<section class="relay-demo" markdown>

<div class="relay-section-heading" markdown>

<span class="relay-section-label">Background work</span>

## Give it a task. Get the answer in chat.

Send a message from your phone. Relay runs your coding agent on your machine and
sends the result back when the work is done.

</div>

<div class="relay-chat" markdown="0">
<div class="relay-chat-bar"><span>Telegram</span><span><i></i> Relay is online</span></div>
<div class="relay-chat-body">
<div class="relay-chat-message relay-chat-message--user"><span>You · 18:12</span><p>Every weekday at 8am, run my morning brief and send me the three things that need my attention.</p></div>
<div class="relay-chat-status"><span>Relay → Codex</span><span>Draft ready for approval</span></div>
<div class="relay-chat-message relay-chat-message--assistant"><span>Relay · 18:14</span><p>I drafted your morning brief for weekdays at 8am. Approve it to start the schedule.</p></div>
</div>
<div class="relay-chat-footer"><span>Delivered in chat</span><span>Conversation saved</span></div>
</div>

</section>

<section class="relay-outcomes" id="what-can-it-do" markdown>

<span class="relay-section-label">What it does</span>

## A personal assistant that keeps working when you step away.

<div class="relay-use-cases" markdown="0">
  <article>
    <span>01</span>
    <h3>Handle background work</h3>
    <p>Ask it to inspect a repository, research a question, or prepare an update. You do not need to keep a terminal open.</p>
  </article>
  <article>
    <span>02</span>
    <h3>Run your daily routines</h3>
    <p>Schedule a morning brief, weekly review, or any other Markdown job and receive the result automatically in chat.</p>
  </article>
  <article>
    <span>03</span>
    <h3>Remember the context</h3>
    <p>Keep conversation history and assistant context between messages instead of explaining the same work again.</p>
  </article>
  <article>
    <span>04</span>
    <h3>Use your existing tools</h3>
    <p>Keep the MCP servers, skills, and integrations already configured in Claude Code, Codex, or Pi. Chats also preserve your configured permissions.</p>
  </article>
</div>

</section>

<section class="relay-model" markdown>

<span class="relay-section-label">How it works</span>

## One lightweight bridge. Your agent does the work.

<div class="relay-steps" markdown="0">
  <div><span>01</span><strong>Message your assistant</strong><p>Use iMessage, Telegram, or Slack from wherever you are.</p></div>
  <div><span>02</span><strong>Relay starts the work</strong><p>It restores the conversation and runs your chosen coding agent in the background.</p></div>
  <div><span>03</span><strong>Get the result</strong><p>Relay saves the response and sends it back to the same chat.</p></div>
</div>

Relay does not replace your coding agent. It handles chat, history, schedules,
approvals, and delivery. Claude Code, Codex, or Pi keeps control of models,
tools, skills, and authentication. Chats preserve configured agent permissions;
Codex and Claude jobs bypass interactive permissions so scheduled work can
finish without an operator.

[See the full architecture](architecture.md){ .relay-inline-link }

</section>

<section class="relay-paths" markdown>

<span class="relay-section-label">Get started</span>

## Build your AI chief of staff

<div class="grid cards" markdown>

-   :material-rocket-launch-outline:{ .lg .middle } **Run Relay for the first time**

    ---

    Install the binary, connect one channel, configure a backend, and validate
    the setup.

    [:octicons-arrow-right-24: Quickstart](getting-started.md)

-   :material-message-processing-outline:{ .lg .middle } **Connect your chat**

    ---

    Set up private [iMessage](channels/imessage.md), [Telegram](telegram.md), or
    [Slack](slack.md) conversations with narrow sender allowlists.

    [:octicons-arrow-right-24: Configure channels](configuration.md#channels)

-   :material-account-cog-outline:{ .lg .middle } **Design your assistant**

    ---

    Shape identity, durable context, reusable skills, jobs, and evaluation
    criteria without duplicating instructions or committing secrets.

    [:octicons-arrow-right-24: Design the repository](designing-an-assistant.md)

-   :material-calendar-clock:{ .lg .middle } **Automate recurring work**

    ---

    Write Markdown runbooks, run them manually, or add cron triggers and send
    stored results to your primary chat.

    [:octicons-arrow-right-24: Jobs and schedules](jobs.md)

-   :material-server-security:{ .lg .middle } **Operate it continuously**

    ---

    Choose permissions, inspect local state, and run Relay under `launchd` or
    `systemd`.

    [:octicons-arrow-right-24: Operations guide](services.md)

</div>

</section>

<section class="relay-doc-map" markdown>

<span class="relay-section-label">Documentation</span>

## Find what you need

| If you need to… | Read… |
| --- | --- |
| install and run one working channel | [Quickstart](getting-started.md) |
| design identity, context, skills, and jobs | [Designing an assistant](designing-an-assistant.md) |
| understand every TOML setting | [Configuration](configuration.md) |
| add recurring or manual work | [Jobs and schedules](jobs.md) |
| choose backend permissions safely | [Permissions and security](security.md) |
| keep Relay online after logout or reboot | [Run as a service](services.md) |
| inspect commands and outputs | [CLI reference](reference/cli.md) |
| understand or extend the code | [Architecture](architecture.md) and [contributing](contributing.md) |

!!! note "Canonical source"

    These pages are generated directly from the Markdown in the repository's
    `docs/` directory. If the site and source ever disagree, update the
    Markdown source and rebuild the site.

</section>
