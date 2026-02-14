# touch_input Parity Note

- Bevy source: `bevy/examples/input/touch_input.rs`
- mgstudio target: `mgstudio-engine/examples/input/touch_input/`
- Baseline commit: `48ec375a3a3cdc904476ef1d13f9d71c9f2820d3`
- Status: `Adapted`
- Owner: `team-input_window`

## Behavioral Comparison

- Rendering: Not applicable (console logging only).
- Input:
  - Logs `just_pressed`, `just_released`, and `active` touch state each frame.
  - Keeps touch id and position logging pattern from Bevy example.
- Timing/Update model: Polling in update system per frame.
- Asset path/loading: Not applicable.

## Known Differences

- Bevy uses `Touches` resource with real multi-touch streams.
- mgstudio currently has no touch resource in engine/runtime input surface; this port maps left mouse to a single synthetic touch id (`0`).
- Touch cancel events are not available in this runtime path.

## Runtime Constraints

- WASM/Web: Uses mouse fallback path (single synthetic touch).
- Native runtime: Uses mouse fallback path (single synthetic touch).

## Validation Evidence

- Build command: `moon -C mgstudio-engine build --release --target wasm examples/input/touch_input`
- Smoke command: `moon -C mgstudio-engine check`
- Logs: `window.host_debug_string` with `[touch_input] ...` prefix.

## Follow-up Tasks

- `bd issue`: `moon-game-studio-p71.26.12`
- Remaining blockers: Add native touch resource/events (`Touches`, just_pressed/released/canceled) and multi-touch support.
