# gamepad_input Parity Note

- Bevy source: `bevy/examples/input/gamepad_input.rs`
- mgstudio target: `mgstudio-engine/examples/input/gamepad_input/`
- Baseline commit: `48ec375a3a3cdc904476ef1d13f9d71c9f2820d3`
- Status: `Adapted`
- Owner: `team-input_window`

## Behavioral Comparison

- Rendering: Not applicable (console logging only).
- Input:
  - `South` button `just_pressed` / `just_released` logging is aligned.
  - `RightTrigger2` and `LeftStickX` threshold checks (`abs > 0.01`) are aligned.
- Timing/Update model: Polling in update system per frame.
- Asset path/loading: Not applicable.

## Known Differences

- Bevy reads `(Entity, &Gamepad)` from ECS query; this port iterates `input.gamepads()` and logs runtime `gamepad_id`.
- Bevy query semantics (archetype ordering/entity identifiers) are not represented in this example path.

## Runtime Constraints

- WASM/Web: Depends on browser gamepad API availability and user gesture requirements.
- Native runtime: Depends on host backend gamepad support.

## Validation Evidence

- Build command: `moon -C mgstudio-engine build --release --target wasm examples/input/gamepad_input`
- Smoke command: `moon -C mgstudio-engine check`
- Logs: `window.host_debug_string` with `[gamepad_input] ...` prefix.

## Follow-up Tasks

- `bd issue`: `moon-game-studio-p71.26.2`
- Remaining blockers: Bevy-style ECS gamepad entity parity (if strict entity-level semantics are required).
