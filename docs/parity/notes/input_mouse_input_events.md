# mouse_input_events Parity Note

- Bevy source: `bevy/examples/input/mouse_input_events.rs`
- mgstudio target: `mgstudio-engine/examples/input/mouse_input_events/`
- Baseline commit: `48ec375a3a3cdc904476ef1d13f9d71c9f2820d3`
- Status: `Adapted`
- Owner: `team-input_window`

## Behavioral Comparison

- Rendering: Not applicable (console logging only).
- Input:
  - Mouse button events are logged from `just_pressed` / `just_released` transitions.
  - Mouse motion and cursor moved logs are synthesized from frame-to-frame cursor position changes.
  - Mouse wheel logs are emitted from host per-frame wheel delta.
- Timing/Update model: Polling in update system per frame.
- Asset path/loading: Not applicable.

## Known Differences

- Bevy `MessageReader<MouseButtonInput/MouseMotion/CursorMoved/MouseWheel>` APIs are not available in mgstudio yet.
- Bevy gesture events (`PinchGesture`, `RotationGesture`, `DoubleTapGesture`) are platform-specific and currently not available in mgstudio runtime.
- `window` entity metadata in Bevy input events is not represented in this port.

## Runtime Constraints

- WASM/Web: Supported through host mouse polling and wheel delta.
- Native runtime: Supported through host mouse polling and wheel delta.

## Validation Evidence

- Build command: `moon -C mgstudio-engine build --release --target wasm examples/input/mouse_input_events`
- Smoke command: `moon -C mgstudio-engine check`
- Logs: `window.host_debug_string` with `[mouse_input_events] ...` prefix.

## Follow-up Tasks

- `bd issue`: `moon-game-studio-p71.26.10`
- Remaining blockers: Add Bevy-like mouse/gesture message event surfaces and reader semantics.
