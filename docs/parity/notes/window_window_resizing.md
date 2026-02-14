# window_resizing Parity Note

- Bevy source: bevy/examples/window/window_resizing.rs
- mgstudio target: mgstudio-engine/examples/window/window_resizing/
- Baseline commit: 48ec375a3a3cdc904476ef1d13f9d71c9f2820d3
- Status: Adapted
- Owner: team-input_window

## Behavioral Comparison

- Rendering: Adapted with runtime logging for parity visibility.
- Window/Input: Captures the Bevy example intent under current API constraints.
- Timing/Update model: Update system per frame.
- Asset path/loading: Not applicable.

## Known Differences

- Programmatic window resize API is not exposed in current path.
- This port keeps behavior traceability through window.host_debug_string logs.

## Runtime Constraints

- WASM/Web: Available features depend on current web host window API exposure.
- Native runtime: Available features depend on current native host window API exposure.

## Validation Evidence

- Build command: moon -C mgstudio-engine build --release --target wasm examples/window/window_resizing
- Smoke command: moon -C mgstudio-engine check
- Logs: window.host_debug_string with [window_resizing] prefix.

## Follow-up Tasks

- Remaining blockers: Programmatic window resize API is not exposed in current path.
