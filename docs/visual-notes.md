# Visual Notes

## Current Status
- Visual baseline and current artifacts are generated in repo.
- Deterministic state wiring exists via `AGENTPULSE_SNAPSHOT_STATE`.

## Minor Deviations (Tracked)
1. Native macOS blur and shadow composition will differ slightly from HTML/CSS rendering.
2. Font rasterization differs between browser render and SwiftUI text shaping.
3. Orb pulse timing may differ by a few frames due to native animation interpolation.

## Follow-up
- Re-capture `docs/visual-current/*.png` from the built app after running:
`AGENTPULSE_SNAPSHOT_STATE=<state> /path/to/AgentPulse.app`.
- Re-validate this checklist:
`/Users/tejasbhardwaj/Desktop/AgentPulse/docs/visual-checklist.md`.
