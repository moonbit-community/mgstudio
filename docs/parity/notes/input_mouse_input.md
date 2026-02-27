# mouse_input Parity Note

- Bevy source: `bevy/examples/input/mouse_input.rs`
- mgstudio target: `mgstudio-engine/examples/input/mouse_input/`
- Baseline commit: `48ec375a3a3cdc904476ef1d13f9d71c9f2820d3`
- Status: `Adapted`
- Owner: `team-input_window`

## Behavioral Comparison

- Rendering: Not applicable (console logging only).
- Input:
  - Left mouse button `pressed` / `just_pressed` / `just_released` behavior is aligned via `ButtonInput<MouseButton>`.
  - Mouse movement logging is derived from frame-to-frame cursor position delta.
  - Mouse wheel logging uses per-frame host wheel delta.
- Timing/Update model: Polling in update systems per frame.
- Asset path/loading: Not applicable.

## Known Differences

- `AccumulatedMouseMotion` / `AccumulatedMouseScroll` are available, but values are synthesized from host polling each frame.

## Runtime Constraints

- WASM/Web: Supported through host mouse polling and wheel delta.
- Native runtime: Supported through host mouse polling and wheel delta.

## Validation Evidence

- Build command: `moon -C mgstudio-engine build --release --target wasm examples/input/mouse_input`
- Smoke command: `moon -C mgstudio-engine check`
- Logs: `window.host_debug_string` with `[mouse_input] ...` prefix.

## Follow-up Tasks

- Remaining blockers: Move accumulated mouse motion/scroll from host polling synthesis to backend event accumulation parity.
