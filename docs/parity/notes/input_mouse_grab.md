# mouse_grab Parity Note

- Bevy source: `bevy/examples/input/mouse_grab.rs`
- mgstudio target: `mgstudio-engine/examples/input/mouse_grab/`
- Baseline commit: `48ec375a3a3cdc904476ef1d13f9d71c9f2820d3`
- Status: `Adapted`
- Owner: `team-input_window`

## Behavioral Comparison

- Rendering: Not applicable (console logging only).
- Input:
  - Left mouse click switches to grabbed mode (`GrabLocked`) and hides cursor.
  - `Escape` releases grab mode (`GrabNone`) and shows cursor.
  - State transitions are logged with Bevy-like semantics.
- Timing/Update model: Polling in update system per frame.
- Asset path/loading: Not applicable.

## Known Differences

- Bevy mutates `CursorOptions` (`visible`, `grab_mode`) directly on window.
- mgstudio applies equivalent behavior through direct window cursor APIs, not Bevy `CursorOptions` component.

## Runtime Constraints

- WASM/Web: Depends on browser/runtime support for cursor lock and pointer constraints.
- Native runtime: Supported through runtime window backend cursor APIs.

## Validation Evidence

- Build command: `moon -C mgstudio-engine build --release --target wasm examples/input/mouse_grab`
- Smoke command: `moon -C mgstudio-engine check`
- Logs: `window.host_debug_string` with `[mouse_grab] ...` prefix.

## Follow-up Tasks

- Remaining blockers: Align with Bevy `CursorOptions` component-level API surface.
