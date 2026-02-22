# AgentPulse - Implementation Plan (Corrected)

## Context

A macOS 15+ menu bar app that monitors Claude Code and Codex agent activity in real-time AND lets you approve/deny agent tool calls directly from the dropdown panel.

**Location**: `~/Projects/AgentPulse/`
**Build**: XcodeGen → Xcode project → xcodebuild
**Target**: macOS 15.0+, SwiftUI, Swift 6
**Sandbox**: Disabled (needs `~/` filesystem access)

---

## Architecture Overview

```
┌──────────────────────────────────────────────────────────┐
│  Claude Code                                              │
│  ┌─────────────────┐    PreToolUse Hook                  │
│  │ Tool Execution   │───→ approval-bridge.sh             │
│  └─────────────────┘         │                           │
└──────────────────────────────│───────────────────────────┘
                               │ writes JSON
                               ▼
                    ~/.agentpulse/pending/{uuid}.json
                               │
                               │ FSEvents
                               ▼
┌──────────────────────────────────────────────────────────┐
│  AgentPulse (Menu Bar App)                               │
│  ┌─────────────────┐  ┌──────────────────┐              │
│  │ ApprovalService  │  │ FSEventWatcher   │              │
│  │ polls pending/   │  │ recursive watch  │              │
│  └────────┬────────┘  └────────┬─────────┘              │
│           │                     │                        │
│           ▼                     ▼                        │
│  ┌─────────────────────────────────────┐                │
│  │     AgentPulseViewModel             │                │
│  │  agents, tasks, files, approvals    │                │
│  └────────────────┬────────────────────┘                │
│                   ▼                                      │
│  ┌─────────────────────────────────────┐                │
│  │  MenuBarDropdownView (SwiftUI)      │                │
│  │  Approvals → Agents → Tasks → Files │                │
│  └─────────────────────────────────────┘                │
└──────────────────────────────────────────────────────────┘
                               │
                    User clicks Approve/Deny
                               │
                               ▼
                    ~/.agentpulse/responses/{uuid}.json
                               │
                               │ bridge script reads
                               ▼
                    exit 0 with hookSpecificOutput JSON
```

---

## Approval Hook Mechanism

Claude Code's **PreToolUse hook** fires BEFORE any tool executes.

**Input** (stdin JSON):
```json
{
  "session_id": "abc123",
  "transcript_path": "/path/to/transcript.jsonl",
  "hook_event_name": "PreToolUse",
  "tool_name": "Bash",
  "tool_input": { "command": "npm test" },
  "tool_use_id": "toolu_01ABC..."
}
```

**Output** (stdout JSON — always exit 0):
```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow",
    "permissionDecisionReason": "Approved via AgentPulse"
  }
}
```

For deny:
```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "Blocked via AgentPulse"
  }
}
```

**Decision values**: `"allow"`, `"deny"`, `"ask"` (NOT the deprecated `"approve"`/`"block"`)
**Exit codes**: 0 for all decisions (hook outputs JSON). Exit 2 = hard error (stderr fed as error to Claude).

**Hook config format** in `~/.claude/settings.json`:
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "~/.agentpulse/hooks/approval-bridge.sh",
            "timeout": 120
          }
        ]
      }
    ]
  }
}
```

**Flow**: hook writes pending request → polls for response → AgentPulse shows card → user clicks → app writes response → hook reads, outputs `hookSpecificOutput` JSON, exits 0

---

## Data Sources

### Claude Code (`~/.claude/`)
| Path | Data | Notes |
|------|------|-------|
| `teams/{team}/config.json` | Members: name, agentId, agentType, model, cwd, joinedAt | Primary agent source |
| `teams/{team}/inboxes/*.json` | Team message events | Agent communication |
| `projects/**/*.jsonl` | `queue-operation`, `agent_progress`, `file-history-snapshot` events | **Primary task & file source** |
| `history.jsonl` | User inputs per session (display, timestamp ms, project, sessionId) | Recent activity |
| `stats-cache.json` | dailyActivity, modelUsage, totalSessions, totalMessages | Aggregate stats |
| `settings.json` | Hooks config (existing `Stop` hook must be preserved) | Hook installation target |

**IMPORTANT**: `~/.claude/tasks/` only contains `.lock` and `.highwatermark` files — NOT task JSON. Task lifecycle data lives in project JSONL files as `queue-operation` events with stringified task content.

**Project JSONL event types**:
- `queue-operation` (operation: "enqueue"/"dequeue") — contains task_id, description, task_type
- `agent_progress` — contains agentId, prompt, parentToolUseID
- `file-history-snapshot` — contains messageId, trackedFileBackups, timestamp

### Codex (`~/.codex/`)
| Path | Data | Notes |
|------|------|-------|
| `.codex-global-state.json` | Active workspace roots, agent-mode, thread titles | Large JSON (~45K) |
| `history.jsonl` | Session history (session_id, ts in seconds, text) | Recent activity |
| `config.toml` | model, personality, per-project trust, features | Section-aware parser needed |

**Codex config.toml actual structure**:
```toml
model = "gpt-5.3-codex"
model_reasoning_effort = "high"
personality = "pragmatic"

[projects."/Users/.../project-path"]
trust_level = "untrusted"

[notice.model_migrations]
"gpt-5.2" = "gpt-5.2-codex"

[features]
steer = true
```

### AgentPulse (`~/.agentpulse/`)
| Path | Data |
|------|------|
| `pending/{uuid}.json` | Approval requests from bridge script |
| `responses/{uuid}.json` | User decisions written by app |
| `hooks/approval-bridge.sh` | The installed bridge script |
| `.installed` | First-launch marker |

---

## Project Structure (29 files)

```
AgentPulse/
├── project.yml                              # XcodeGen spec
├── Info.plist                               # LSUIElement = YES
├── AgentPulse.entitlements                  # No sandbox
├── hooks/
│   └── approval-bridge.sh                   # PreToolUse hook bridge
├── AgentPulse/
│   ├── AgentPulseApp.swift                  # @main with MenuBarExtra (.window)
│   ├── Models/
│   │   ├── AnyCodable.swift                 # Type-erased JSON wrapper
│   │   ├── ClaudeModels.swift               # TeamConfig, TeamMember, Stats, Settings
│   │   ├── CodexModels.swift                # GlobalState, HistoryEntry, Config
│   │   ├── ApprovalModels.swift             # ApprovalRequest, ApprovalResponse
│   │   └── UnifiedModels.swift              # UnifiedAgent, UnifiedTask, FileActivity, Stats
│   ├── Services/
│   │   ├── JSONLParser.swift                # JSONL tail parser
│   │   ├── ClaudeDataService.swift          # Reads ~/.claude/ (teams, project JSONL, stats)
│   │   ├── CodexDataService.swift           # Reads ~/.codex/ (state, history, config)
│   │   ├── FileWatcherService.swift         # FSEvents recursive watching
│   │   ├── ApprovalService.swift            # Polls pending/, writes responses/
│   │   └── HookInstaller.swift              # Safe merge into settings.json
│   ├── ViewModels/
│   │   └── AgentPulseViewModel.swift        # Central state aggregation
│   └── Views/
│       ├── MenuBarDropdownView.swift        # Top-level container (400pt)
│       ├── ApprovalsSection.swift           # Approval cards at top
│       ├── OrbitalAgentsSection.swift       # 2x2 agent grid
│       ├── TaskProgressSection.swift        # Segmented progress + task list
│       ├── FileActivitySection.swift        # Heat-dot file stream
│       ├── StatsBarView.swift               # Bottom stats bar
│       └── Components/
│           ├── ApprovalCardView.swift       # Single approval card
│           ├── OrbitalRingView.swift        # Circular progress ring
│           ├── SegmentedProgressBar.swift   # Per-task segments
│           ├── TaskRowView.swift            # Task row with status icon
│           ├── FileRowView.swift            # File row with heat dot
│           └── PulsingOrbIcon.swift         # Menu bar icon + badge
```

---

## Implementation Steps

### Step 1: Prerequisites
- `brew install xcodegen` (currently not installed)
- Create `~/.agentpulse/{pending,responses,hooks}` directories

### Step 2: Project Scaffold (3 files)
- **project.yml**: XcodeGen spec targeting macOS 15.0, no sandbox, Swift 6, preBuildScript copies hook
- **Info.plist**: LSUIElement=YES, bundle metadata
- **AgentPulse.entitlements**: `com.apple.security.app-sandbox` = false

### Step 3: Hook Bridge Script (1 file)
- **hooks/approval-bridge.sh**:
  - Reads full hook JSON from stdin (includes `session_id`, `tool_name`, `tool_input`, `tool_use_id`)
  - Generates UUID via `uuidgen`
  - Writes `~/.agentpulse/pending/{uuid}.json`
  - Polls `~/.agentpulse/responses/{uuid}.json` every 0.5s with 115s timeout
  - On response: outputs `hookSpecificOutput` JSON with `permissionDecision: "allow"` or `"deny"`, exits 0
  - **On timeout: DENY by default** (safe fallback — outputs `permissionDecision: "deny"` with reason "Timed out waiting for AgentPulse response")
  - Cleans up pending file on exit

### Step 4: Data Models (5 files)
- **AnyCodable.swift**: Enum with string/int/double/bool/null/array/dictionary cases, Codable conformance
- **ClaudeModels.swift**:
  - `ClaudeTeamConfig` (name, description, members[], createdAt, leadAgentId)
  - `ClaudeTeamMember` (agentId, name, agentType, model, cwd, joinedAt)
  - `ClaudeHistoryEntry` (display, timestamp, project, sessionId)
  - `ClaudeStatsCache` (version, dailyActivity[], modelUsage, totalSessions, totalMessages)
  - `ClaudeDailyActivity` (date, messageCount, sessionCount, toolCallCount)
  - `ClaudeSettings`, `ClaudeHookGroup`, `ClaudeHook`
  - `ClaudeQueueOperation` (type, operation, timestamp, sessionId, content: stringified JSON with task_id, description, task_type)
  - `ClaudeAgentProgress` (type, agentId, prompt, timestamp)
  - `ClaudeFileSnapshot` (type, messageId, snapshot: { trackedFileBackups, timestamp })
- **CodexModels.swift**: `CodexGlobalState`, `CodexHistoryEntry` (session_id, ts in seconds, text), `CodexConfig`
- **ApprovalModels.swift**:
  - `ApprovalRequest` (id, tool_name, tool_input, session_id, tool_use_id, timestamp, source)
  - Computed: `displayType`, `displayDetail`, `elapsedSeconds`
  - `ApprovalResponse` with `hookSpecificOutput` structure: `{ hookEventName, permissionDecision, permissionDecisionReason }`
  - Factories: `.allow()` and `.deny(reason:)`
- **UnifiedModels.swift**: `UnifiedAgent` (with `AgentAccentColor`), `UnifiedTask`, `UnifiedFileActivity` (with `HeatLevel`), `AggregateStats`, `Color(hex:)` extension

### Step 5: Services (6 files)
- **JSONLParser.swift**: `parse(_:from:maxLines:)` - reads last N lines, decodes each, skips failures. Also `parseAll<T>(_:from:)` for scanning full files for specific event types.

- **ClaudeDataService.swift**:
  - `loadTeams()` — scans `~/.claude/teams/*/config.json`
  - `loadAllAgents()` — extracts members from team configs
  - `loadTasks()` — scans `~/.claude/projects/**/*.jsonl` for `queue-operation` events, parses stringified content field to extract task_id, description, task_type. Deduplicates by task_id, latest operation wins.
  - `loadRecentHistory()` — parses `~/.claude/history.jsonl`
  - `loadStats()` — reads `~/.claude/stats-cache.json`
  - `loadFileActivity()` — scans project JSONL files for `file-history-snapshot` events. Cross-references with `~/.claude/file-history/{session}/` directory entries for recency (mtime of hash@version files). Falls back to JSONL timestamps if files not found.
  - `loadSettings()` — reads `~/.claude/settings.json`

- **CodexDataService.swift**:
  - `loadGlobalState()` — reads `.codex-global-state.json`
  - `loadRecentHistory()` — parses `history.jsonl` (timestamps in seconds)
  - `loadConfig()` — **section-aware line-by-line TOML parser** (not regex). Tracks current section via `[section]` headers, handles quoted keys in section headers like `[projects."/path/to/project"]`, parses `key = "value"` and `key = true/false` pairs. Extracts: model, personality, project trust levels, features.
  - `buildCodexAgent()` — constructs UnifiedAgent from global state + config

- **FileWatcherService.swift**:
  - Uses **`FSEventStreamCreate`** (CoreServices FSEvents API) for recursive directory watching
  - Watches: `~/.claude/teams`, `~/.claude/projects`, `~/.claude/file-history`, `~/.codex`, `~/.agentpulse/pending`
  - Latency: 1.0s coalescing
  - Flags: `kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagUseCFTypes`
  - Fires `onChange` callback with affected paths for targeted refresh
  - Properly manages stream lifecycle (schedule on RunLoop, start, invalidate on deinit)

- **ApprovalService.swift**: Polls `~/.agentpulse/pending/` every 0.5s. `approve(_:)` and `deny(_:reason:)` write response JSON to `~/.agentpulse/responses/{id}.json` with `.atomic` write option. Cleans up stale pending requests older than 2 minutes.

- **HookInstaller.swift**:
  - `isHookInstalled()` — checks if PreToolUse entry with our command exists
  - `installHook()` — reads settings.json, parses existing hooks, **merges** PreToolUse entry (preserving existing Stop hook and any other hooks), writes back with prettyPrinted
  - `uninstallHook()` — removes only our PreToolUse entry
  - Copies `approval-bridge.sh` to `~/.agentpulse/hooks/` and makes executable

### Step 6: ViewModel (1 file)
- **AgentPulseViewModel.swift**: `@MainActor ObservableObject`.
  - Starts FSEvents watcher + approval polling + 3s refresh timer
  - Aggregates agents (Claude teams + Codex), tasks, file activity, stats, pending approvals
  - Computed: `taskCompletionFraction`, `sortedTasks`, `pendingApprovalCount`
  - First-launch flow: checks `.installed` marker, shows banner, calls `HookInstaller.installHook()`
  - **After hook install: sets `showRestartNotice = true`** to display "Restart active Claude Code sessions to enable approval flow" message

### Step 7: Views (13 files)
Design follows the HTML mockup with **accessibility corrections**:
- **Minimum 11pt text** throughout (no 8-10px sizes from mockup)
- **`@Environment(\.accessibilityReduceMotion)`** — disable pulsing/breathing animations when set
- **Semantic `Button` elements** for all interactive targets
- **`focusable()` and keyboard navigation** support

View files:
- **AgentPulseApp.swift**: `MenuBarExtra` with `.window` style, `PulsingOrbIcon` as label
- **PulsingOrbIcon.swift**: Amber radial gradient circle with `scaleEffect` breathing animation (respects reduce-motion), coral notification badge with count
- **MenuBarDropdownView.swift**: 400pt wide, header with LIVE indicator, scrollable content (max 560pt), conditional sections, stats bar, quit footer. First-launch banner with "Install Hook" button. Restart-notice banner (dismissible).
- **ApprovalsSection.swift**: "AWAITING APPROVAL" label with coral count badge, list of `ApprovalCardView`
- **ApprovalCardView.swift**: Coral left-edge stripe, agent name + source tag + elapsed time, tool type label, monospace detail box, Approve (mint) / Deny (neutral→coral) buttons
- **OrbitalAgentsSection.swift**: 2-column `LazyVGrid` of `OrbitalRingView`
- **OrbitalRingView.swift**: 44pt `Circle().trim()` progress ring with accent color glow, center percentage text, agent name + source tag + current task + model
- **TaskProgressSection.swift**: Fraction display (5/8), status count dots (pulsing amber for running), `SegmentedProgressBar`, list of `TaskRowView` (max 5)
- **SegmentedProgressBar.swift**: `HStack` of rounded rectangles, mint=done, amber=running (pulsing), subtle=pending
- **TaskRowView.swift**: Status icons — spinning ring for running, dashed circle for pending, mint checkmark for done. Task name + owner.
- **FileActivitySection.swift**: List of `FileRowView` (max 5)
- **FileRowView.swift**: Heat dot (amber/coral/ghost), monospace path with dimmed directory prefix, elapsed time
- **StatsBarView.swift**: 4-column bar with numbers (Active amber, Messages, Tool Calls, Success mint), hairline dividers, dark background

### Step 8: Build & Run
```bash
cd ~/Projects/AgentPulse
brew install xcodegen  # prerequisite
xcodegen generate
xcodebuild -project AgentPulse.xcodeproj -scheme AgentPulse -configuration Debug build
open "$(xcodebuild -project AgentPulse.xcodeproj -scheme AgentPulse -configuration Debug \
  -showBuildSettings | grep -m1 BUILT_PRODUCTS_DIR | awk '{print $3}')/AgentPulse.app"
```

### Step 9: First-Launch Flow
1. App creates `~/.agentpulse/{pending,responses,hooks}/`
2. Shows "Welcome to AgentPulse" banner with "Install Hook" button
3. User clicks → `HookInstaller.installHook()` merges PreToolUse into `~/.claude/settings.json`
4. Creates `~/.agentpulse/.installed` marker
5. **Shows "Restart active Claude Code sessions" notice** (dismissible)
6. Banner disappears, app is ready

---

## Build Order (dependency-aware)

1. project.yml, Info.plist, AgentPulse.entitlements
2. AnyCodable.swift (no deps)
3. ClaudeModels, CodexModels, ApprovalModels, UnifiedModels
4. JSONLParser
5. ClaudeDataService, CodexDataService
6. FileWatcherService, ApprovalService, HookInstaller
7. AgentPulseViewModel
8. PulsingOrbIcon (needed by App entry)
9. AgentPulseApp.swift
10. StatsBarView, FileRowView, FileActivitySection (simplest views)
11. TaskRowView, SegmentedProgressBar, TaskProgressSection
12. OrbitalRingView, OrbitalAgentsSection
13. ApprovalCardView, ApprovalsSection
14. MenuBarDropdownView (assembles everything)
15. hooks/approval-bridge.sh

---

## Verification

1. `xcodegen generate` succeeds without errors
2. `xcodebuild` compiles all 29 files without errors
3. App appears in menu bar with amber pulsing orb, no dock icon
4. Clicking orb shows dropdown panel matching the mockup design
5. With no Claude Code running: sections show empty gracefully
6. First-launch banner appears, "Install Hook" adds PreToolUse to settings.json without destroying existing hooks
7. Restart notice appears after hook install
8. Start a Claude Code session → agents and tasks appear in dropdown
9. Claude Code requests tool approval → approval card appears with badge on orb
10. Click "Approve" → tool proceeds (hookSpecificOutput with permissionDecision: "allow"), card disappears
11. Click "Deny" → tool is blocked (permissionDecision: "deny"), card disappears
12. Bridge script times out → **denies by default** (safe fallback)
13. File activity updates as Claude Code edits files
14. Stats bar shows today's message/tool call counts
15. Quit button terminates cleanly
