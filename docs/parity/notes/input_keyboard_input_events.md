# keyboard_input_events Parity Note

- Bevy source: `bevy/examples/input/keyboard_input_events.rs`
- mgstudio target: `mgstudio-engine/examples/input/keyboard_input_events/`
- Baseline commit: `48ec375a3a3cdc904476ef1d13f9d71c9f2820d3`
- Status: `Adapted`
- Owner: `team-input_window`

## Behavioral Comparison

- Rendering: Not applicable (console logging only).
- Input: Logs keyboard press/release events from mgstudio input pipeline.
- Timing/Update model: Events are emitted during pre-update and consumed in update.
- Asset path/loading: Not applicable.

## Known Differences

- Events are synthesized from per-frame `just_pressed` / `just_released` polling.
- Event payload includes `logical_key`, but still remains a reduced subset of Bevy's full keyboard payload surface.

## Runtime Constraints

- WASM/Web: Supported through host key state polling.
- Native runtime: Supported through host key state polling.

## Validation Evidence

- Build command: `moon -C mgstudio-engine build --release --target wasm examples/input/keyboard_input_events`
- Smoke command: `moon -C mgstudio-engine check`
- Logs: `window.host_debug_string` with `[keyboard_input_events] ...` prefix.

## Follow-up Tasks

- `bd issue`: `moon-game-studio-p71.26.6`
- Remaining blockers: Close remaining keyboard payload parity gaps (layout/IME-complete logical key and text semantics).
