# visibility_range Parity Note

- Bevy source: `bevy/examples/3d/visibility_range.rs`
- mgstudio target: `mgstudio-engine/examples/3d/visibility_range/`
- Baseline commit: `48ec375a3a3cdc904476ef1d13f9d71c9f2820d3`
- Status: `Adapted`
- Owner: `team-render`

## Behavioral Comparison

- Camera controls are aligned:
  - zoom with `W/S` or `Up/Down`,
  - pan with `A/D` or `Left/Right`,
  - mouse wheel zoom support.
- Mode switching is aligned:
  - `1`: distance-based switch between high/low detail,
  - `2`: high-detail only,
  - `3`: low-detail only.
- Visibility behavior is preserved in intent:
  - high detail appears at near distance,
  - low detail appears at far distance,
  - overlap range where both can be visible.

## Known Differences

- Baseline parity: Bevy uses glTF `FlightHelmet` assets with `VisibilityRange`
  components and optional prepass toggling.
- This port now uses engine-level `VisibilityRange` components for distance
  gating in 3D render execution.
- mgstudio still lacks Bevy's glTF `FlightHelmet` scene path in this example,
  so two procedural mesh stand-ins (high-poly sphere and low-poly sphere) are
  used instead.
- Baseline parity: Bevy's `Space` prepass toggle is not included in this port.

## Runtime Constraints

- WASM/Web: depends on browser WebGPU availability.
- Native runtimes: depends on backend GPU capabilities.

## Validation Evidence

- Build command: `moon -C mgstudio-engine build --release --target wasm examples/3d/visibility_range`
- Check command: `moon -C mgstudio-engine check`

## Follow-up Tasks

- `bd issue`: `moon-game-studio-p71.11.54`
