# specular_tint Parity Note

- Bevy source: `bevy/examples/3d/specular_tint.rs`
- mgstudio target: `mgstudio-engine/examples/3d/specular_tint/`
- Baseline commit: `48ec375a3a3cdc904476ef1d13f9d71c9f2820d3`
- Status: `Adapted`
- Owner: `team-render`

## Behavioral Comparison

- Interaction pattern is aligned:
  - camera rotates around the subject every frame,
  - `Space` toggles between two tint modes.
- Material updates are animated each frame in solid mode.

## Known Differences

- Baseline parity: Bevy uses `Hdr`, `Skybox`, `EnvironmentMapLight`,
  `specular_tint`, and `specular_tint_texture`.
- mgstudio currently does not expose equivalent public surfaces for those
  features in this example path.
- This port adapts the behavior by switching `StandardMaterial::base_color`
  between:
  - animated solid tint mode,
  - texture-driven tint mode (`textures/AlphaNoise.png`).

## Runtime Constraints

- WASM/Web: depends on browser WebGPU availability.
- Native runtimes: depends on backend GPU capabilities.

## Validation Evidence

- Build command: `moon -C mgstudio-engine build --release --target wasm examples/3d/specular_tint`
- Check command: `moon -C mgstudio-engine check`

## Follow-up Tasks

- `bd issue`: `moon-game-studio-p71.11.46`
