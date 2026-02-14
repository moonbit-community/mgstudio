# touch_input_events Parity Note

- Bevy source: `bevy/examples/input/touch_input_events.rs`
- mgstudio target: `mgstudio-engine/examples/input/touch_input_events/`
- Baseline commit: `48ec375a3a3cdc904476ef1d13f9d71c9f2820d3`
- Status: `Adapted`
- Owner: `team-input_window`

## Behavioral Comparison

- Rendering: Not applicable (console logging only).
- Input:
  - Event-style logs are produced with `Started`, `Moved`, and `Ended` phases.
  - Event stream shape follows the Bevy touch-input-events example intent.
- Timing/Update model: Polling in update system per frame.
- Asset path/loading: Not applicable.

## Known Differences

- Bevy uses `MessageReader<TouchInput>` from real touch input events.
- mgstudio currently has no touch event/message API in engine input surface; this port maps left mouse to synthetic touch id `0`.
- Touch cancel and multi-touch semantics are not represented.

## Runtime Constraints

- WASM/Web: Uses mouse fallback path.
- Native runtime: Uses mouse fallback path.

## Validation Evidence

- Build command: `moon -C mgstudio-engine build --release --target wasm examples/input/touch_input_events`
- Smoke command: `moon -C mgstudio-engine check`
- Logs: `window.host_debug_string` with `[touch_input_events] ...` prefix.

## Follow-up Tasks

- `bd issue`: `moon-game-studio-p71.26.13`
- Remaining blockers: Add native touch message API and full multi-touch lifecycle parity.
