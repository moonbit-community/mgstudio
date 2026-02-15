# lines Parity Note

- Bevy source: `bevy/examples/3d/lines.rs`
- mgstudio target: `mgstudio-engine/examples/3d/lines/`
- Baseline commit: `48ec375a3a3cdc904476ef1d13f9d71c9f2820d3`
- Status: `Adapted`
- Owner: `team-render`

## Behavioral Comparison

- Scene framing and data layout are aligned:
  - one line-list group offset to `(-1.5, 0, 0)`,
  - one line-strip group offset to `(0.5, 0, 0)`,
  - camera at `(-2.0, 2.5, 5.0)` looking at origin.
- Color intent is aligned:
  - left group in green, right group in blue.

## Known Differences

- Baseline parity: Bevy uses custom `LineMaterial` + `LineList/LineStrip` mesh primitive topology and shader pipeline specialization.
- mgstudio currently has no public runtime surface for custom line topology/material specialization in this example path.
- This port renders equivalent segments using thin unlit cuboids.

## Runtime Constraints

- WASM/Web: depends on browser WebGPU availability.
- Native runtimes: depends on backend GPU capabilities.

## Validation Evidence

- Build command: `moon -C mgstudio-engine build --release --target wasm examples/3d/lines`
- Check command: `moon -C mgstudio-engine check`

## Follow-up Tasks

- `bd issue`: `moon-game-studio-p71.11.26`
