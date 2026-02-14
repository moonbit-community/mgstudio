# multiple_windows Parity Note

- Bevy source: bevy/examples/window/multiple_windows.rs
- mgstudio target: mgstudio-engine/examples/window/multiple_windows/
- Baseline commit: 48ec375a3a3cdc904476ef1d13f9d71c9f2820d3
- Status: Adapted
- Owner: team-input_window

## Behavioral Comparison

- Rendering: Adapted with runtime logging for parity visibility.
- Window/Input: Captures the Bevy example intent under current API constraints.
- Timing/Update model: Update system per frame.
- Asset path/loading: Not applicable.

## Known Differences

- Secondary window orchestration API is not available in current path.
- This port keeps behavior traceability through window.host_debug_string logs.

## Runtime Constraints

- WASM/Web: Available features depend on current web host window API exposure.
- Native runtime: Available features depend on current native host window API exposure.

## Validation Evidence

- Build command: moon -C mgstudio-engine build --release --target wasm examples/window/multiple_windows
- Smoke command: moon -C mgstudio-engine check
- Logs: window.host_debug_string with [multiple_windows] prefix.

## Follow-up Tasks

- Remaining blockers: Secondary window orchestration API is not available in current path.
