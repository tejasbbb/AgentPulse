<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://github.com/user-attachments/assets/placeholder-dark">
    <img width="80" alt="AgentPulse" src="https://github.com/user-attachments/assets/placeholder-light">
  </picture>
</p>

<h1 align="center">AgentPulse</h1>

<p align="center">
  <strong>A macOS menu bar control center for your AI coding agents.</strong>
  <br />
  Monitor Claude Code &amp; Codex activity in real-time.<br />
  Approve or deny tool calls without leaving your flow.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/macOS-15.0+-1c1a17?style=flat-square&labelColor=2c2a27&color=e8a84c" />
  <img src="https://img.shields.io/badge/Swift-6-1c1a17?style=flat-square&labelColor=2c2a27&color=e07a5f" />
  <img src="https://img.shields.io/badge/SwiftUI-MenuBarExtra-1c1a17?style=flat-square&labelColor=2c2a27&color=7ecba1" />
  <img src="https://img.shields.io/badge/license-MIT-1c1a17?style=flat-square&labelColor=2c2a27&color=8b9fc7" />
</p>

<br />

<p align="center">
  <img src="mockup-preview.png" alt="AgentPulse dropdown panel" width="400" />
</p>

---

## The Problem

You're running Claude Code with a team of agents. Or Codex is refactoring your backend. Either way, you're deep in another task when one of them needs permission to run `rm -rf node_modules` or edit a critical file.

**Today**: Switch to the terminal. Find the right pane. Read the prompt. Type `y`. Lose your context.

**With AgentPulse**: A card slides into your menu bar. You glance, click Approve, and you're back in 2 seconds.

---

## What It Does

AgentPulse lives in your macOS menu bar as a pulsing amber orb. Click it, and a dropdown panel shows you everything your AI agents are doing:

### Approve & Deny from the Menu Bar

A bridge hook intercepts Claude Code's `PreToolUse` events. Pending tool calls appear as cards with full context --- the command, the file, the diff. Approve or deny with a click. The agent continues (or doesn't) without you ever opening a terminal.

### Live Agent Monitoring

See every active agent across Claude Code teams and Codex workspaces. Each agent gets an orbital progress ring showing task completion, current activity, and which model it's running.

### Task Progress

A segmented progress bar and task list pulled from Claude Code's project JSONL streams. Running tasks pulse amber. Completed ones go mint. You see the whole picture at a glance.

### File Activity Stream

A heat-mapped feed of recently modified files. Hot files glow amber. Older edits fade to ghost. You always know what's being touched.

### Session Stats

Today's aggregate numbers --- active agents, messages exchanged, tool calls made, success rate --- displayed in the bottom stats bar.

---

## Architecture

```
Claude Code                        AgentPulse
┌──────────┐                      ┌──────────────┐
│ PreToolUse│─── bridge.sh ──────>│ ApprovalService│
│   Hook    │    writes pending/   │ polls pending/ │
└──────────┘                      └──────┬───────┘
                                         │
     ~/.claude/teams/config.json ──>     │
     ~/.claude/projects/**/*.jsonl ──>   ▼
     ~/.claude/stats-cache.json ──> ┌──────────────┐
     ~/.codex/config.toml ────────> │   ViewModel   │
     ~/.codex/global-state.json ──> └──────┬───────┘
                                          │
                                          ▼
                                   ┌──────────────┐
                                   │ MenuBarExtra  │
                                   │  (SwiftUI)    │
                                   └──────────────┘
                                          │
     User clicks Approve ────────────────>│
                                          ▼
                             ~/.agentpulse/responses/
                                          │
     bridge.sh reads response ──── exit 0 with
                                   hookSpecificOutput
```

The hook bridge script uses Claude Code's `hookSpecificOutput` format:

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow",
    "permissionDecisionReason": "Approved via AgentPulse"
  }
}
```

If AgentPulse doesn't respond within the timeout, the bridge **denies by default** --- no silent auto-approves.

---

## Data Sources

| Source | What AgentPulse Reads |
|--------|----------------------|
| `~/.claude/teams/*/config.json` | Active agents, models, working directories |
| `~/.claude/projects/**/*.jsonl` | Task lifecycle (`queue-operation`), agent progress, file snapshots |
| `~/.claude/stats-cache.json` | Daily message counts, tool calls, session stats |
| `~/.claude/settings.json` | Hook installation target (merges, never overwrites) |
| `~/.codex/.codex-global-state.json` | Active workspaces, agent mode |
| `~/.codex/config.toml` | Model selection, project trust levels |
| `~/.agentpulse/pending/*.json` | Incoming approval requests from the bridge |

File watching uses **FSEvents** (recursive) --- not `DispatchSource` --- so nested directory changes are never missed.

---

## Getting Started

### Prerequisites

- macOS 15.0+
- Xcode 16.2+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)

```bash
brew install xcodegen
```

### Build

```bash
git clone https://github.com/tejasbbb/AgentPulse.git
cd AgentPulse
xcodegen generate
xcodebuild -project AgentPulse.xcodeproj -scheme AgentPulse -configuration Debug build
```

### Run

```bash
open "$(xcodebuild -project AgentPulse.xcodeproj -scheme AgentPulse \
  -configuration Debug -showBuildSettings \
  | grep -m1 BUILT_PRODUCTS_DIR | awk '{print $3}')/AgentPulse.app"
```

### First Launch

1. AgentPulse creates `~/.agentpulse/` with `pending/`, `responses/`, and `hooks/` directories
2. A welcome banner appears --- click **Install Hook** to add the `PreToolUse` hook to `~/.claude/settings.json`
3. Restart any active Claude Code sessions to pick up the new hook
4. Start using Claude Code normally --- approval cards will appear when tools need permission

---

## Design

The UI follows a warm, dark aesthetic built around four accent colors:

| Color | Hex | Usage |
|-------|-----|-------|
| **Amber** | `#e8a84c` | Active/running states, primary accent |
| **Mint** | `#7ecba1` | Completed/success states, approve actions |
| **Coral** | `#e07a5f` | Approval urgency, deny actions, attention |
| **Slate Blue** | `#8b9fc7` | Codex source indicators |

Typography uses **Instrument Serif** for display numbers, **DM Sans** for body text, and **JetBrains Mono** for code and paths.

The mockup is in [`mockup.html`](mockup.html) --- open it in a browser to see the full design.

---

## Project Structure

```
AgentPulse/
├── project.yml                    # XcodeGen spec
├── Info.plist                     # LSUIElement (no dock icon)
├── hooks/
│   └── approval-bridge.sh         # PreToolUse hook bridge
└── AgentPulse/
    ├── AgentPulseApp.swift         # @main entry point
    ├── Models/                     # Data types for Claude, Codex, approvals
    ├── Services/                   # File watching, data parsing, hook install
    ├── ViewModels/                 # Central state aggregation
    └── Views/                      # SwiftUI views and components
```

See [`IMPLEMENTATION_PLAN.md`](IMPLEMENTATION_PLAN.md) for the full 29-file breakdown and build order.

---

## Status

**Pre-implementation** --- the corrected plan and design mockup are complete. Implementation is next.

---

## License

MIT
