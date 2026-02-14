# mouse_grab Parity Note

- Bevy source: `bevy/examples/input/mouse_grab.rs`
- mgstudio target: `mgstudio-engine/examples/input/mouse_grab/`
- Baseline commit: `48ec375a3a3cdc904476ef1d13f9d71c9f2820d3`
- Status: `Adapted`
- Owner: `team-input_window`

## Behavioral Comparison

- Rendering: Not applicable (console logging only).
- Input:
  - Left mouse click switches to a grabbed intent state.
  - `Escape` switches back to a released intent state.
  - Visibility/grab mode state transitions are logged with Bevy-like semantics.
- Timing/Update model: Polling in update system per frame.
- Asset path/loading: Not applicable.

## Known Differences

- Bevy mutates `CursorOptions` (`visible`, `grab_mode`) directly on window.
- mgstudio currently does not expose host cursor lock/visibility controls in public API; this port tracks simulated state only.

## Runtime Constraints

- WASM/Web: No exported cursor lock API in current runtime path.
- Native runtime: No exported cursor lock API in current runtime path.

## Validation Evidence

- Build command: `moon -C mgstudio-engine build --release --target wasm examples/input/mouse_grab`
- Smoke command: `moon -C mgstudio-engine check`
- Logs: `window.host_debug_string` with `[mouse_grab] ...` prefix.

## Follow-up Tasks

- `bd issue`: `moon-game-studio-p71.26.8`
- Remaining blockers: Expose host cursor visibility/grab controls aligned with Bevy `CursorOptions`.
