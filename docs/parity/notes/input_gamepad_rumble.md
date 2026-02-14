# gamepad_rumble Parity Note

- Bevy source: `bevy/examples/input/gamepad_rumble.rs`
- mgstudio target: `mgstudio-engine/examples/input/gamepad_rumble/`
- Baseline commit: `48ec375a3a3cdc904476ef1d13f9d71c9f2820d3`
- Status: `Adapted`
- Owner: `team-input_window`

## Behavioral Comparison

- Rendering: Not applicable (console logging only).
- Input:
  - Same gamepad button triggers are preserved: `North/East/South/West/Start`.
  - Rumble add/stop requests are emitted as logs with per-button intent.
- Timing/Update model: Polling in update system per frame.
- Asset path/loading: Not applicable.

## Known Differences

- Bevy uses `MessageWriter<GamepadRumbleRequest>` with real force-feedback output.
- mgstudio currently has no host force-feedback API; this port logs equivalent requests only.
- ECS gamepad entity identifiers are adapted to runtime `gamepad_id`.

## Runtime Constraints

- WASM/Web: Gamepad detection depends on browser support and user gesture policy; rumble output is not implemented.
- Native runtime: Gamepad detection depends on backend support; rumble output is not implemented.

## Validation Evidence

- Build command: `moon -C mgstudio-engine build --release --target wasm examples/input/gamepad_rumble`
- Smoke command: `moon -C mgstudio-engine check`
- Logs: `window.host_debug_string` with `[gamepad_rumble] ...` prefix.

## Follow-up Tasks

- `bd issue`: `moon-game-studio-p71.26.4`
- Remaining blockers: Add host/gamepad rumble capability and Bevy-like request dispatch.
