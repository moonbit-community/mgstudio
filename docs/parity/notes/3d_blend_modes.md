# blend_modes Parity Note

- Bevy source: `bevy/examples/3d/blend_modes.rs`
- mgstudio target: `mgstudio-engine/examples/3d/blend_modes/`
- Baseline commit: `48ec375a3a3cdc904476ef1d13f9d71c9f2820d3`
- Status: `Exact`
- Owner: `team-render`

## Behavioral Comparison

- Scene composition matches Bevy:
  - 5 spheres with `Opaque/Blend/Premultiplied/Add/Multiply` alpha modes.
  - checkerboard plane grid, point light, and orbit camera framing.
- Runtime controls match Bevy:
  - `Up` / `Down`: increase/decrease alpha.
  - `Left` / `Right`: rotate camera.
  - `H`: toggle camera `Hdr`.
  - `Space`: toggle unlit on the sphere set.
  - `C`: randomize colors.
- UI behavior matches Bevy intent:
  - top-left controls legend,
  - top-right runtime status (`HDR` + `Alpha`),
  - per-sphere labels repositioned each frame using world-to-viewport projection.

## Runtime Constraints

- WASM/Web: depends on browser WebGPU availability.
- Native runtimes: depends on backend GPU capabilities.

## Validation Evidence

- Build command: `moon -C mgstudio-engine build --target wasm examples/3d/blend_modes`
- Check command: `moon -C mgstudio-engine check`

## Follow-up Tasks

- `bd issue`: `moon-game-studio-p71.11.9`
