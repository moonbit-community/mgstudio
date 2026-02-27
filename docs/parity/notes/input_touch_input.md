# touch_input Parity Note

- Bevy source: `bevy/examples/input/touch_input.rs`
- mgstudio target: `mgstudio-engine/examples/input/touch_input/`
- Baseline commit: `48ec375a3a3cdc904476ef1d13f9d71c9f2820d3`
- Status: `Adapted`
- Owner: `team-input_window`

## Behavioral Comparison

- Rendering: Not applicable (console logging only).
- Input:
  - Uses `Res<Touches>` with `iter_just_pressed`, `iter_just_released`, `iter_just_canceled`, and `iter`.
  - Logs touch id/position and `just_pressed(id)` in Bevy-like flow.
- Timing/Update model: Resource snapshot consumed in update system.
- Asset path/loading: Not applicable.

## Known Differences

- `WASM/Web` and `native-wasmtime` now provide host touch streams (id/phase/position) to `Touches`.
- Platform-specific touch metadata from Bevy (`force`, advanced gesture/device details) is not implemented yet.
- `native` (wasmoon + Cocoa window backend) currently has no touch source wired, so the stream is empty there.

## Runtime Constraints

- WASM/Web: Pointer touch events are forwarded to `input_touch_event_*`.
- Native runtime (wasmtime): `winit::WindowEvent::Touch` is forwarded to `input_touch_event_*`.
- Native runtime (wasmoon/Cocoa backend): touch input path is currently unavailable.

## Validation Evidence

- Build command: `moon -C mgstudio-engine build --release --target wasm examples/input/touch_input`
- Smoke command: `moon -C mgstudio-engine check`
- Logs: `window.host_debug_string` with `[touch_input] ...` prefix.

## Follow-up Tasks

- Remaining blockers: Add touch source for wasmoon/Cocoa backend and implement full Bevy touch metadata parity.
