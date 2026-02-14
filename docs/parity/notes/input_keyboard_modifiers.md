# keyboard_modifiers Parity Note

- Bevy source: `bevy/examples/input/keyboard_modifiers.rs`
- mgstudio target: `mgstudio-engine/examples/input/keyboard_modifiers/`
- Baseline commit: `48ec375a3a3cdc904476ef1d13f9d71c9f2820d3`
- Status: `Exact`
- Owner: `team-input_window`

## Behavioral Comparison

- Rendering: Not applicable (console logging only).
- Input:
  - `ShiftLeft/ShiftRight` and `ControlLeft/ControlRight` combined press check is aligned.
  - `KeyA` `just_pressed` guard is aligned.
- Timing/Update model: Polling in update system per frame.
- Asset path/loading: Not applicable.

## Known Differences

- No behavioral differences observed for this example path.

## Runtime Constraints

- WASM/Web: Depends on host/browser keycode delivery for modifier keys.
- Native runtime: Depends on host backend keycode delivery for modifier keys.

## Validation Evidence

- Build command: `moon -C mgstudio-engine build --release --target wasm examples/input/keyboard_modifiers`
- Smoke command: `moon -C mgstudio-engine check`
- Logs: `window.host_debug_string` with `[keyboard_modifiers] ...` prefix.

## Follow-up Tasks

- `bd issue`: `moon-game-studio-p71.26.7`
- Remaining blockers: None for this example path.
