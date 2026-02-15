# orthographic Parity Note

- Bevy source: `bevy/examples/3d/orthographic.rs`
- mgstudio target: `mgstudio-engine/examples/3d/orthographic/`
- Baseline commit: `48ec375a3a3cdc904476ef1d13f9d71c9f2820d3`
- Status: `Exact`
- Owner: `team-render`

## Behavioral Comparison

- Camera projection:
  - Bevy uses `OrthographicProjection` with `ScalingMode::FixedVertical { viewport_height: 6.0 }`.
  - mgstudio now mirrors fixed-vertical behavior by updating orthographic scale from current logical window height each frame.
- Scene composition:
  - One plane (`5x5`), four unit cubes at `(±1.5, 0.5, ±1.5)`, one point light at `(3, 8, 5)`, and a camera at `(5, 5, 5)` looking at origin.
- Runtime projection semantics:
  - Orthographic mode is encoded in the 3D projection uniform and decoded by the shared `mesh3d.wgsl` runtime shader path (web/native/wasmtime).

## Known Differences

- None for this example’s scoped behavior.

## Runtime Constraints

- WASM/Web: behavior depends on host-provided logical window size and scale factor.
- Native runtime: behavior depends on host window DPI/scale reporting.

## Validation Evidence

- Build command: `moon -C mgstudio-engine build --release --target wasm examples/3d/orthographic`
- Check command: `moon -C mgstudio-engine check`
- Matrix refresh: `python3 scripts/generate_bevy_example_parity.py`

## Follow-up Tasks

- `bd issue`: `moon-game-studio-p71.11.33`
- Related API track: `moon-game-studio-p71.6.1`
