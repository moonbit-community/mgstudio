# blend_modes Parity Note

- Bevy source: `bevy/examples/3d/blend_modes.rs`
- mgstudio target: `mgstudio-engine/examples/3d/blend_modes/`
- Baseline commit: `48ec375a3a3cdc904476ef1d13f9d71c9f2820d3`
- Status: `Adapted`
- Owner: `team-render`

## Behavioral Comparison

- Scene composition is aligned with Bevy intent:
  - 5 spheres with `Opaque/Blend/Premultiplied/Add/Multiply` material blend modes.
  - checkerboard plane grid under the spheres.
  - point light and orbit camera framing.
- Runtime controls are aligned:
  - `Up` / `Down` changes material alpha.
  - `Left` / `Right` rotates the camera around scene center.
  - `Space` toggles unlit mode for the sphere materials.
  - `C` changes colors for controlled materials.

## Known Differences

- Baseline parity: Bevy toggles camera `Hdr` with `H`; mgstudio camera runtime currently has no HDR toggle surface.
- Baseline parity: Bevy renders on-screen UI labels/text in this example; mgstudio port keeps scene behavior but does not include the UI overlay.
- Baseline parity: color randomization uses deterministic palette stepping instead of RNG.

## Runtime Constraints

- WASM/Web: depends on browser WebGPU availability.
- Native runtimes: depends on backend GPU capabilities.

## Validation Evidence

- Build command: `moon -C mgstudio-engine build --release --target wasm examples/3d/blend_modes`
- Check command: `moon -C mgstudio-engine check`

## Follow-up Tasks

- `bd issue`: `moon-game-studio-p71.11.9`
