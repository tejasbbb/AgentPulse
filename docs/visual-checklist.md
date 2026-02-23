# AgentPulse Visual QA Checklist (Blocking)

## Capture Setup
- Screenshot state must be deterministic via `AGENTPULSE_SNAPSHOT_STATE` with values:
`empty`, `active`, `approval`.
- Dynamic values are frozen in snapshot mode:
clock text, elapsed labels, animation intensity.
- Use fixed capture profile:
width `400pt`, same display scale, same macOS appearance mode.

## Artifacts
- Baseline images:
`/Users/tejasbhardwaj/Desktop/AgentPulse/docs/visual-baseline/mockup-active.png`
`/Users/tejasbhardwaj/Desktop/AgentPulse/docs/visual-baseline/mockup-approval.png`
`/Users/tejasbhardwaj/Desktop/AgentPulse/docs/visual-baseline/mockup-empty.png`
- Current images:
`/Users/tejasbhardwaj/Desktop/AgentPulse/docs/visual-current/app-active.png`
`/Users/tejasbhardwaj/Desktop/AgentPulse/docs/visual-current/app-approval.png`
`/Users/tejasbhardwaj/Desktop/AgentPulse/docs/visual-current/app-empty.png`

## Comparison Rules
1. Layout parity:
section order/presence, panel width, section paddings, max-height scroll behavior.
2. Component parity:
approval card stripe and badge, orbital rings, segmented task bar, heat dots, stats bar.
3. Typography parity:
display/body/mono roles, no text below readable threshold.
4. Color parity:
amber/mint/coral/slate-blue must match semantic usage.
5. Motion/accessibility parity:
reduced-motion behavior must preserve state clarity.
6. Interaction parity:
keyboard focusability and button semantics.

## Acceptance Threshold
- All checklist categories pass.
- No critical visual regressions in `empty`, `active`, or `approval` state.
- At most 3 minor deviations, each documented in:
`/Users/tejasbhardwaj/Desktop/AgentPulse/docs/visual-notes.md`.
