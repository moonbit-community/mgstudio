# keyboard_input Parity Note

- Bevy source: `bevy/examples/input/keyboard_input.rs`
- mgstudio target: `mgstudio-engine/examples/input/keyboard_input/`
- Baseline commit: `48ec375a3a3cdc904476ef1d13f9d71c9f2820d3`
- Status: `Adapted`
- Owner: `team-input_window`

## Behavioral Comparison

- Rendering: Not applicable (console logging only).
- Input: `ButtonInput<KeyCode>` (`KeyA`) and `ButtonInput<Key>` (`Key::Character("?")`) press/just_press/just_release semantics are aligned for this example path.
- Timing/Update model: Polling in update system per frame.
- Asset path/loading: Not applicable.

## Known Differences

- Logical-key model is still a subset and currently backed by host key polling mapping.

## Runtime Constraints

- WASM/Web: Supported through host key state polling.
- Native runtime: Supported through host key state polling.

## Validation Evidence

- Build command: `moon -C mgstudio-engine build --release --target wasm examples/input/keyboard_input`
- Smoke command: `moon -C mgstudio-engine check`
- Logs: `window.host_debug_string` with `[keyboard_input] ...` prefix.

## Follow-up Tasks

- `bd issue`: `moon-game-studio-p71.26.5`
- Remaining blockers: Add full Bevy-equivalent `Key` model.
