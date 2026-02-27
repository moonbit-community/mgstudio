# animated_material Parity Note

- Bevy source: `bevy/examples/3d/animated_material.rs`
- mgstudio target: `mgstudio-engine/examples/3d/animated_material/`
- Baseline commit: `48ec375a3a3cdc904476ef1d13f9d71c9f2820d3`
- Status: `Adapted`
- Owner: `team-render`

## Behavioral Comparison

- Material animation behavior is aligned:
  - a `3x3` grid of cubes
  - per-frame hue rotation of each material based on elapsed delta time
- Camera placement and scene framing are aligned to the Bevy example intent.

## Known Differences

- Baseline parity: Bevy's `EnvironmentMapLight` setup is not available in mgstudio yet.
- This port uses a point light to keep the scene readable while preserving material animation semantics.

## Runtime Constraints

- WASM/Web: depends on browser WebGPU availability.
- Native runtimes: depends on backend GPU capabilities.

## Validation Evidence

- Build command: `moon -C mgstudio-engine build --release --target wasm examples/3d/animated_material`
- Check command: `moon -C mgstudio-engine check`

## Follow-up Tasks

