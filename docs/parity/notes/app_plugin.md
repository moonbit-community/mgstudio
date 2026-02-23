# plugin Parity Note

- Bevy source: `bevy/examples/app/plugin.rs`
- mgstudio target: `mgstudio-engine/examples/app/plugin/`
- Baseline commit: `48ec375a3a3cdc904476ef1d13f9d71c9f2820d3`
- Status: `Exact`
- Owner: `team-core`

## Behavioral Comparison

- Plugin setup: Matches Bevy flow (`add_plugins` with default bundle + custom plugin).
- Resource model: Plugin inserts `PrintMessageState` resource and updates it in an update system.
- Time model: System now reads `Res<Time>` and ticks `Timer` from `time.delta_seconds()`.
- Output: Periodic message print behavior matches the Bevy example intent.

## Known Differences

- Language-level derive macros (`#[derive(Resource)]`) are represented by explicit MoonBit resource impls.

## Runtime Constraints

- WASM/Web: Supported.
- Native runtimes: Supported.

## Validation Evidence

- Build command: `moon -C mgstudio-engine build --release --target wasm examples/app/plugin`
- Smoke command: `moon -C mgstudio-engine check`
