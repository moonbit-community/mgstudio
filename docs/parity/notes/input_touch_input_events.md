# touch_input_events Parity Note

- Bevy source: `bevy/examples/input/touch_input_events.rs`
- mgstudio target: `mgstudio-engine/examples/input/touch_input_events/`
- Baseline commit: `48ec375a3a3cdc904476ef1d13f9d71c9f2820d3`
- Status: `Adapted`
- Owner: `team-input_window`

## Behavioral Comparison

- Rendering: Not applicable (console logging only).
- Input:
  - Uses `MessageReader<TouchInput>` and logs each incoming touch event.
  - Event stream supports `Started`, `Moved`, `Ended`, and `Canceled` phases.
- Timing/Update model: MessageReader iteration in update system.
- Asset path/loading: Not applicable.

## Known Differences

- `WASM/Web` and `native-wasmtime` now provide host touch events (id/phase/position) to `MessageReader<TouchInput>`.
- Bevy-level extended touch metadata is not implemented yet.
- Legacy MoonBit native runtime (Cocoa backend) had no touch source wired, so the stream was empty there.

## Runtime Constraints

- WASM/Web: Pointer touch events are forwarded to `input_touch_event_*`.
- Native runtime (wasmtime): `winit::WindowEvent::Touch` is forwarded to `input_touch_event_*`.
- Legacy native runtime (Cocoa backend): touch input path was unavailable.

## Validation Evidence

- Build command: `moon -C mgstudio-engine build --release --target wasm examples/input/touch_input_events`
- Smoke command: `moon -C mgstudio-engine check`
- Logs: `window.host_debug_string` with `[touch_input_events] ...` prefix.

## Follow-up Tasks

- Remaining blockers (historical): add touch source for native Cocoa backend and full Bevy touch metadata/lifecycle parity.
