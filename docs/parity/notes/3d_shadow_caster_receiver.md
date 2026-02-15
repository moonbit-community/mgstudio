# shadow_caster_receiver Parity Note

- Bevy source: `bevy/examples/3d/shadow_caster_receiver.rs`
- mgstudio target: `mgstudio-engine/examples/3d/shadow_caster_receiver/`
- Baseline commit: `48ec375a3a3cdc904476ef1d13f9d71c9f2820d3`
- Status: `Adapted`
- Owner: `team-render`

## Behavioral Comparison

- Scene composition is aligned:
  - two spheres, one floating plane, one ground plane.
  - one directional light and one point light.
  - camera at `(-5.0, 5.0, 5.0)` looking toward `(-1.0, 1.0, 0.0)`.
- Control bindings are aligned:
  - `L` switches between directional and point lights.
  - `C` toggles shadow-related behavior.
  - `R` toggles receiver-related behavior.

## Known Differences

- Baseline parity: Bevy uses per-entity `NotShadowCaster` / `NotShadowReceiver` components and toggles them directly.
- mgstudio currently does not expose equivalent per-entity shadow caster/receiver component controls in this example path.
- This port maps:
  - `C` to global light shadow-map enable/disable,
  - `R` to toggling receiver plane shading via material `unlit`.

## Runtime Constraints

- WASM/Web: depends on browser WebGPU availability.
- Native runtimes: depends on backend GPU capabilities.

## Validation Evidence

- Build command: `moon -C mgstudio-engine build --release --target wasm examples/3d/shadow_caster_receiver`
- Check command: `moon -C mgstudio-engine check`

## Follow-up Tasks

- `bd issue`: `moon-game-studio-p71.11.43`
