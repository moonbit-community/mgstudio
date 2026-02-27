# 3d_scene Parity Note

- Bevy source: `bevy/examples/3d/3d_scene.rs`
- mgstudio target: `mgstudio-engine/examples/3d/3d_scene/`
- Baseline commit: `48ec375a3a3cdc904476ef1d13f9d71c9f2820d3`
- Status: `Exact`
- Owner: `team-render`

## Behavioral Comparison

- Scene composition is aligned:
  - circular base with radius `4.0`
  - one unit cube at `(0, 0.5, 0)`
  - one point light at `(4, 8, 4)`
  - one camera at `(-2.5, 4.5, 9)` looking at origin
- Render behavior uses the same standard 3D PBR path as other mgstudio 3D examples.

## Known Differences

- None for this example scope.

## Runtime Constraints

- WASM/Web: depends on browser WebGPU availability.
- Native runtimes: depends on backend GPU capabilities.

## Validation Evidence

- Build command: `moon -C mgstudio-engine build --release --target wasm examples/3d/3d_scene`
- Check command: `moon -C mgstudio-engine check`

## Follow-up Tasks

