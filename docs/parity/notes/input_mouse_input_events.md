# mouse_input_events Parity Note

- Bevy source: `bevy/examples/input/mouse_input_events.rs`
- mgstudio target: `mgstudio-engine/examples/input/mouse_input_events/`
- Baseline commit: `48ec375a3a3cdc904476ef1d13f9d71c9f2820d3`
- Status: `Adapted`
- Owner: `team-input_window`

## Behavioral Comparison

- Rendering: Not applicable (console logging only).
- Input:
  - `MouseButtonInput`, `MouseMotion`, `CursorMoved`, and `MouseWheel` are consumed via `MessageReader`.
  - Gesture readers (`PinchGesture`, `RotationGesture`, `DoubleTapGesture`) are present in API shape.
- Timing/Update model: Event readers consumed in update systems.
- Asset path/loading: Not applicable.

## Known Differences

- Event data is currently synthesized from host polling each frame rather than native event callbacks.
- Gesture sources (`PinchGesture`, `RotationGesture`, `DoubleTapGesture`) are runtime-limited and typically absent.
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
- Remaining blockers: Add native gesture sources and full Bevy event payload parity.
