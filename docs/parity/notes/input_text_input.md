# text_input Parity Note

- Bevy source: `bevy/examples/input/text_input.rs`
- mgstudio target: `mgstudio-engine/examples/input/text_input/`
- Baseline commit: `48ec375a3a3cdc904476ef1d13f9d71c9f2820d3`
- Status: `Adapted`
- Owner: `team-input_window`

## Behavioral Comparison

- Rendering: Adapted to console logging in current port path.
- Input:
  - Left mouse click toggles an `IME Enabled` flag.
  - `Enter` commits current edit buffer as a bubble line.
  - `Backspace` removes the last buffered character.
  - Printable character input appends text to the edit buffer.
- Timing/Update model: MessageReader iteration for keyboard events per frame.
- Asset path/loading: Not applicable.

## Known Differences

- Bevy UI layout (`Text`, `Node`, `Text2d`) and bubbling animation are not implemented in this example path.
- Bevy `Ime` message stream is not available in current mgstudio runtime.
- `KeyboardInput.logical_key` is available, but full composition and layout-aware IME behavior are not yet parity-complete.

## Runtime Constraints

- WASM/Web: Supported through host keyboard/mouse event polling.
- Native runtime: Supported through host keyboard/mouse event polling.

## Validation Evidence

- Build command: `moon -C mgstudio-engine build --release --target wasm examples/input/text_input`
- Smoke command: `moon -C mgstudio-engine check`
- Logs: `window.host_debug_string` with `[text_input] ...` prefix.

## Follow-up Tasks

- `bd issue`: `moon-game-studio-p71.26.11`
- Remaining blockers: Add Bevy-like IME message model and complete composition/layout behavior.
