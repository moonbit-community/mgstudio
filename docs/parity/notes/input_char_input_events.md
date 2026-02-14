# char_input_events Parity Note

- Bevy source: `bevy/examples/input/char_input_events.rs`
- mgstudio target: `mgstudio-engine/examples/input/char_input_events/`
- Baseline commit: `48ec375a3a3cdc904476ef1d13f9d71c9f2820d3`
- Status: `Adapted`
- Owner: `team-input_window`

## Behavioral Comparison

- Rendering: Not applicable (console logging only).
- Input:
  - Keyboard message stream is read each frame and only `Pressed` events are considered.
  - Character logs are emitted in response to mapped keycodes.
- Timing/Update model: MessageReader-based event iteration per frame.
- Asset path/loading: Not applicable.

## Known Differences

- Bevy uses `logical_key: Key::Character`, which is layout-aware.
- mgstudio currently has no logical-key/IME character event model; this port maps a subset of `KeyCode` values to ASCII characters.
- Shift/layout-dependent characters are not represented.

## Runtime Constraints

- WASM/Web: Supported via host keyboard polling/event synthesis.
- Native runtime: Supported via host keyboard polling/event synthesis.

## Validation Evidence

- Build command: `moon -C mgstudio-engine build --release --target wasm examples/input/char_input_events`
- Smoke command: `moon -C mgstudio-engine check`
- Logs: `window.host_debug_string` with `[char_input_events] ...` prefix.

## Follow-up Tasks

- `bd issue`: `moon-game-studio-p71.26.1`
- Remaining blockers: Add Bevy-like logical key / IME character input API.
