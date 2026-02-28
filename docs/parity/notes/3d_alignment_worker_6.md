# 3D Alignment Worker 6 Note

- Scope: `GROUP-6` examples owned by worker-6
- Date: `2026-02-28`
- Bevy baseline: `bevy/examples/3d/{pccm, pcss, post_processing, reflection_probes, render_to_texture, rotate_environment_map, scrolling_fog, shadow_biases}.rs`
- mgstudio targets: `mgstudio-engine/examples/3d/{pccm, pcss, post_processing, reflection_probes, render_to_texture, rotate_environment_map, scrolling_fog, shadow_biases}/`

## Current Status

- `pccm`: `Adapted` (now uses `LightProbe + EnvironmentMapLight + ParallaxCorrection` toggle; scene asset differs from Bevy URL-only asset pack)
- `pcss`: `Adapted` (camera/light wiring aligned; UI remains keyboard-mapped)
- `post_processing`: `Adapted` (camera setup aligned with `Hdr + EnvironmentMapLight + ChromaticAberration + Vignette`; post-process execution path remains backend-approximated)
- `reflection_probes`: `Adapted` (mode switching and camera rotation aligned; generated-environment runtime filtering remains adapted)
- `render_to_texture`: `Exact` (double-pass layering and camera ordering aligned)
- `rotate_environment_map`: `Adapted` (skybox/environment map co-rotation aligned; tangent-generation path not yet exposed)
- `scrolling_fog`: `Blocked` (missing volumetric-fog component family in engine API)
- `shadow_biases`: `Adapted` (control flow and bias math aligned; final visual fidelity depends on backend shadow implementation)

## Unresolved Blockers

1. Missing volumetric fog API surface for `scrolling_fog`
- Missing Bevy-equivalent components/resources in exposed mgstudio API:
  - `FogVolume`
  - `VolumetricFog`
  - `VolumetricLight`
  - `DirectionalLightShadowMap`
- Impact: cannot implement Bevy's density-texture scrolling path (`density_texture_offset`) and volumetric-light interaction. Current example remains an approximation using distance fog and proxy meshes.

2. Missing texture-usage control for reflection-probe runtime generation
- Bevy example mutates image usage to include `COPY_SRC` before runtime environment-map generation.
- mgstudio public API currently does not expose equivalent per-image usage mutation.
- Impact: `reflection_probes` generated mode is wired, but backend behavior remains adapted.

3. Missing tangent generation API for normal-map parity in `rotate_environment_map`
- Bevy uses generated tangents for the sphere mesh before applying clearcoat normal map.
- mgstudio public mesh API does not expose tangent generation.
- Impact: normal-map response can diverge from Bevy in edge cases.

4. Missing cascaded-shadow config API in `post_processing`
- Bevy uses `CascadeShadowConfigBuilder` for directional-light cascade tuning.
- mgstudio public API currently does not expose equivalent cascade configuration.
- Impact: scene lighting/shadow tuning cannot be matched exactly in this example.

## Validation Evidence

- `moon check -p examples/3d/pccm`
- `moon check -p examples/3d/pcss`
- `moon check -p examples/3d/post_processing`
- `moon check -p examples/3d/reflection_probes`
- `moon check -p examples/3d/render_to_texture`
- `moon check -p examples/3d/rotate_environment_map`
- `moon check -p examples/3d/scrolling_fog`
- `moon check -p examples/3d/shadow_biases`
