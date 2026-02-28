# 3D Alignment Round 3 Worker B

- Date: `2026-02-28`
- Owner: `3D examples set B parity tightening (fog/post/lighting/advanced, non-decal)`
- Bevy baselines compared:
  - `bevy/examples/3d/atmosphere.rs`
  - `bevy/examples/3d/atmospheric_fog.rs`
  - `bevy/examples/3d/fog_volumes.rs`
  - `bevy/examples/3d/scrolling_fog.rs`
  - `bevy/examples/3d/auto_exposure.rs`
  - `bevy/examples/3d/depth_of_field.rs`
  - `bevy/examples/3d/lightmaps.rs`
  - `bevy/examples/3d/mixed_lighting.rs`
  - `bevy/examples/3d/meshlet.rs`
  - `bevy/examples/3d/solari.rs`
  - `bevy/examples/3d/occlusion_culling.rs`

## Completed in this pass

1. `examples/3d/atmosphere`
- Switched camera exposure control to the real camera component path (`@render3d.Exposure`) instead of local-state-only mutation.
- Added deferred renderer resource parity (`@render3d.DefaultOpaqueRendererMethod::deferred()`).
- Added Bevy-aligned directional light cascade setup via `@render3d.CascadeShadowConfigBuilder` (`first_cascade_far_bound = 0.3`, `maximum_distance = 15.0`).

2. `examples/3d/atmospheric_fog`
- Added Bevy-aligned directional cascade shadow configuration (`first_cascade_far_bound = 0.3`, `maximum_distance = 3.0`).

3. `examples/3d/scrolling_fog`
- Added Bevy-aligned directional shadow map resource setup (`@render3d.DirectionalLightShadowMap::new(4096)`).
- Removed prior animated-light workaround; fog scrolling is now driven by density-texture-offset progression rather than moving the sun transform every frame.

4. `examples/3d/auto_exposure`
- Replaced the previous ambient-brightness adaptation proxy with camera exposure adaptation on `@render3d.Exposure`, keeping the same input controls (`Left/Right`, `C`, `M`, `V`).
- Preserved metering-mask and compensation toggles and mapped them into the exposure adaptation proxy path.

5. `examples/3d/lightmaps`
- Added deferred renderer resource parity when `args.deferred` is enabled (`@render3d.DefaultOpaqueRendererMethod::deferred()`), in addition to prepass components.

6. `examples/3d/meshlet`
- Added Bevy-aligned directional shadow map resource setup (`4096`).
- Added `@render3d.FreeCamera` camera component.
- Retained camera environment-map intensity parity (`intensity = 150.0`).
- Added directional cascade shadow config parity (`num_cascades = 1`, `maximum_distance = 15.0`).

7. `examples/3d/solari`
- Added `@render3d.FreeCamera` camera component to match Bevy free-camera behavior.
- Tightened bloom behavior by scene mode:
  - PicaPica scene: bloom removed.
  - ManyLights scene: bloom enabled with intensity `0.1`.

8. Reviewed with no code change in this pass
- `examples/3d/fog_volumes`: current deltas remain tied to missing volumetric runtime pass + density-texture execution; no newly available example-local API removed those blockers.
- `examples/3d/depth_of_field`: no new `DepthOfField` runtime component/pipeline landed; existing proxy path remains required.
- `examples/3d/mixed_lighting`: no new per-mesh lightmap component path landed; existing keyboard-mode proxy path remains required.
- `examples/3d/occlusion_culling`: no new GPU readback/indirect introspection path landed; existing heuristic counter remains required.

## Exact unresolved blockers

1. Atmosphere and volumetric rendering pipeline parity is still missing in runtime/backend
- Missing ECS/runtime execution for:
  - `@render3d.Atmosphere`
  - `@render3d.ScatteringMedium`
  - `@render3d.AtmosphereSettings`
  - `@render3d.AtmosphereEnvironmentMapLight`
  - `@render3d.FogVolume`
  - `@render3d.VolumetricFog`
  - `@render3d.VolumetricLight`
- Impacted examples: `atmosphere`, `fog_volumes`, `scrolling_fog`.

2. Material extension/deferred custom shader parity is still missing
- Missing Bevy-equivalent `ExtendedMaterial<StandardMaterial, T>` runtime shading path used by `atmosphere` water material.
- Impacted example: `atmosphere`.

3. Auto exposure compute pipeline parity is still missing
- Missing Bevy-equivalent `AutoExposurePlugin` histogram/metering/compute adaptation backend path and compensation-curve asset execution.
- Impacted example: `auto_exposure`.

4. Depth of field post-process parity is still missing
- Missing Bevy-equivalent `DepthOfField` camera component/runtime pipeline (`Bokeh`, `Gaussian`, `Off`).
- Impacted example: `depth_of_field`.

5. Per-mesh lightmap component parity is still missing
- Missing Bevy-equivalent `Lightmap` component surface (`image`, `uv_rect`, `bicubic_sampling`) and full material/lightmap integration.
- Impacted examples: `lightmaps`, `mixed_lighting`.

6. Meshlet experimental pipeline parity is still missing
- Missing Bevy-equivalent meshlet runtime surfaces:
  - `MeshletPlugin`
  - `MeshletMesh3d`
  - meshlet-processed asset ingestion + debug material rendering path
- Impacted example: `meshlet`.

7. Solari/pathtracing/DLSS runtime parity is still missing
- Missing Bevy-equivalent runtime surfaces:
  - `SolariPlugins` / `SolariLighting`
  - `PathtracingPlugin` / `Pathtracer`
  - `RaytracingMesh3d`
  - `CameraMainTextureUsages` storage-binding path
  - DLSS Ray Reconstruction components/resources
  - render diagnostics feed parity used by the Bevy sample
- Impacted example: `solari`.

8. Occlusion culling introspection parity is still missing
- Missing GPU indirect-parameter staging/readback and render-world bridge equivalent to Bevy’s occlusion introspection path.
- Impacted example: `occlusion_culling`.
