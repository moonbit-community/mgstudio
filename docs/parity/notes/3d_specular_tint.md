# specular_tint Parity Note

- Bevy source: `bevy/examples/3d/specular_tint.rs`
- mgstudio target: `mgstudio-engine/examples/3d/specular_tint/`
- Baseline commit: `48ec375a3a3cdc904476ef1d13f9d71c9f2820d3`
- Status: `Exact`
- Owner: `team-render`

## Behavioral Comparison

- Scene setup is aligned with Bevy:
  - `Camera3d` + `Hdr`,
  - `Skybox`,
  - `EnvironmentMapLight` (diffuse + specular maps),
  - a black non-metallic sphere with animated `specular_tint`.
- Interaction and update flow are aligned:
  - camera rotates every frame,
  - `Space` toggles between solid specular tint and `specular_tint_texture`,
  - help text updates with current mode.
- Material semantics are aligned for this example path:
  - `StandardMaterial.specular_tint`,
  - `StandardMaterial.specular_tint_texture`,
  - reflectance scaling above `1.0` for tint-map mode.

## Runtime Constraints

- WASM/Web: depends on browser WebGPU availability.
- Native runtimes: depends on backend GPU capabilities.

## Validation Evidence

- Build command: `moon -C mgstudio-engine build --release --target wasm examples/3d/specular_tint`
- Check command: `moon -C mgstudio-engine check`
- ABI command: `python3 scripts/check_host_abi.py`

## Follow-up Tasks

