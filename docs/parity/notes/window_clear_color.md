# clear_color Parity Note

- Bevy source: bevy/examples/window/clear_color.rs
- mgstudio target: mgstudio-engine/examples/window/clear_color/
- Baseline commit: 48ec375a3a3cdc904476ef1d13f9d71c9f2820d3
- Status: Exact
- Owner: team-input_window

## Behavioral Comparison

- Rendering: Startup camera uses default clear color from `render2d.ClearColor` resource.
- Window/Input: Press `Space` updates clear color to purple (`0.5, 0.0, 0.5`), matching Bevy flow.
- Timing/Update model: Update system per frame.
- Asset path/loading: Not applicable.

## Known Differences

- No intentional behavior differences.

## Runtime Constraints

- WASM/Web: Available features depend on current web host window API exposure.
- Native runtime: Available features depend on current native host window API exposure.

## Validation Evidence

- Build command: moon -C mgstudio-engine build --release --target wasm examples/window/clear_color
- Engine checks: moon -C mgstudio-engine info && moon -C mgstudio-engine fmt && moon -C mgstudio-engine check

## Follow-up Tasks

- Remaining blockers: None for this example.
