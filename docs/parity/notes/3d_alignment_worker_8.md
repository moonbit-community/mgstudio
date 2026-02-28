# 3D Alignment Worker 8 Notes

- Date: 2026-02-28
- Scope: `texture`, `tonemapping`, `transmission`, `transparency_3d`, `two_passes`, `vertex_colors`, `visibility_range`, `volumetric_fog`, `wireframe`
- Owner: `GROUP-8`

## Completed in This Pass

- `tonemapping`
  - Switched runtime tonemapping/color-grading updates to camera ECS components (`Tonemapping`, `ColorGrading`) instead of material/fog proxy tuning.
  - Added Bevy-aligned camera setup pieces: `Hdr`, `EnvironmentMapLight` (`pisa_*` maps, intensity `2000.0`), and linear distance fog baseline (`start=1.0`, `end=8.0`).
  - Removed obsolete proxy-only helper code and unused material tracking in this example.
- `transmission`
  - Added `PointLightShadowMap` resource initialization with size `2048`.
  - Aligned paper plane material to Bevy behavior with `double_sided=true`, `cull_mode=None`, and inserted `TransmittedShadowReceiver` marker on the paper entity.
  - Added Bevy-aligned camera post stack entries: `Exposure(ev100=6.0)` and `ColorGrading(global.post_saturation=1.2)`.
- `volumetric_fog`
  - Added Bevy-aligned camera post stack entries currently available in mgstudio: `Tonemapping::TonyMcMapface`, `Bloom::default()`, and `Skybox` (`pisa_specular`, brightness `1000.0`).
- `texture`, `transparency_3d`, `two_passes`, `vertex_colors`, `visibility_range`, `wireframe`
  - No additional functional delta required in this pass.

## Unresolved Blockers

1. `tonemapping`
- Bevy drag-and-drop HDR/EXR local-file flow (`FileDragAndDrop` + `UnapprovedPathMode::Allow`) does not have an equivalent mgstudio runtime path in this example.
- Bevy `ColorGradientMaterial` custom shader path is not mapped one-to-one in current mgstudio example/runtime surface.

2. `transmission`
- Exact visual parity for screen-space transmission resolve quality (especially with TAA/depth-prepass interactions) remains backend-dependent and needs renderer-level validation.
- Bevy's platform-conditional TAA/depth behavior (`WebGL` exclusions) is not mirrored one-to-one in the current example path.

3. `volumetric_fog`
- Core volumetric APIs/pipeline are not yet available in mgstudio runtime: `VolumetricFog`, `VolumetricLight`, `FogVolume`.
- Without those ECS/render features, Bevy's voxel volumetric shafts and imported-light `tweak_scene` behavior cannot be made exact.

## Targeted Checks Run

- `moon check examples/3d/tonemapping`
- `moon check examples/3d/transmission`
- `moon check examples/3d/volumetric_fog`
- `moon build examples/3d/texture`
- `moon build examples/3d/tonemapping`
- `moon build examples/3d/transmission`
- `moon build examples/3d/transparency_3d`
- `moon build examples/3d/two_passes`
- `moon build examples/3d/vertex_colors`
- `moon build examples/3d/visibility_range`
- `moon build examples/3d/volumetric_fog`
- `moon build examples/3d/wireframe`
