# 3D Alignment Worker Remaining Round2 A

- Date: `2026-02-28`
- Owner: `advanced 3d examples (meshlet/occlusion/solari + misc untouched parity)`
- Bevy sources compared:
  - `bevy/examples/3d/meshlet.rs`
  - `bevy/examples/3d/occlusion_culling.rs`
  - `bevy/examples/3d/solari.rs`
  - `bevy/examples/3d/parallax_mapping.rs`
  - `bevy/examples/3d/texture.rs`
  - `bevy/examples/3d/wireframe.rs`

## Completed Alignment in This Round

1. `examples/3d/meshlet`
- Kept the adapted proxy-mesh topology (5 + 5 rows + floor) and row color/roughness mapping.
- Aligned camera-side settings closer to Bevy where runtime supports it:
  - inserted `@render3d.Msaa::Off` on the camera;
  - inserted `@render3d.EnvironmentMapLight` with intensity `150.0`.
- Aligned light energy to Bevy intent (`DIRECTIONAL_LIGHT_ILLUMINANCE = 100_000.0`).

2. `examples/3d/occlusion_culling`
- Updated status text shape to Bevy-style phrasing (`Occlusion culling ON/OFF (Press Space to toggle)` + rendered mesh count), with explicit adapted note for readback.
- Aligned directional light rotation setup to Bevy’s `-0.15π` Y/X orientation.
- Aligned per-frame spin model to Bevy’s frame-step style (no delta-time scaling).

3. `examples/3d/solari`
- Restored Bevy-count stress scene parameters:
  - `MANY_LIGHTS_CUBE_COUNT = 200`
  - `MANY_LIGHTS_EMISSIVE_COUNT = 100`
  - `PATROL_SPEED = 1.0`
- Aligned camera/light transforms to Bevy’s authored quaternions for both Pica and ManyLights views.
- Aligned camera setup intent:
  - black clear color;
  - `@render3d.Msaa::Off`;
  - bloom intensity kept at `0.1`.
- Aligned many-lights parameter ranges to Bevy behavior:
  - cube scale range `0.2..2.0`, roughness `0..1`, x/z `-18..18`;
  - emissive intensity channels `0..20000`, y `6..9`.
- Added deterministic seeded RNG (seed `42`) to keep stable pseudo-random distribution per run.
- Updated control/perf text content to mirror Bevy control semantics more closely while surfacing unavailable Solari diagnostics explicitly as `N/A`.

4. `examples/3d/wireframe`
- Updated control text refresh behavior to run every frame (matching Bevy’s continuously refreshed status text behavior).

5. `examples/3d/parallax_mapping`
- Retained existing parity behavior; current example already tracks Bevy controls and camera/view switching model.
- Kept linear normal-map loading (`is_srgb = false`) in place for normal/parallax correctness.

6. `examples/3d/texture`
- No additional code changes required in this round; implementation already matches Bevy setup closely.

## Runtime Blockers (Exact Missing APIs/Modules)

1. Meshlet pipeline is not exposed in mgstudio runtime surface
- Missing equivalents for Bevy meshlet path components/plugins:
  - `MeshletPlugin`
  - `MeshletMesh3d`
  - meshlet debug material plugin flow (`MaterialPlugin::<MeshletDebugMaterial>`-style path)
- Impact: `meshlet` must stay proxy-based instead of true meshlet asset rendering.

2. Directional shadow-map resource insertion is not available on app world
- `@ecs_world.World` has no `get_directional_light_shadow_map_resource()` method.
- Impact: exact Bevy-style `insert_resource(DirectionalLightShadowMap { size: 4096 })` cannot be replicated from example app code.

3. Free camera controller plugin surface is missing
- No mgstudio equivalent of Bevy `FreeCameraPlugin` / `FreeCamera` component in these example paths.
- Impact: camera interaction remains static/adapted in `meshlet` and `solari`.

4. Occlusion introspection/readback API surface is missing
- No mgstudio equivalents for Bevy indirect-parameter readback path used in `occlusion_culling`:
  - `IndirectParametersBuffers`
  - `IndirectParametersIndexed`
  - staging-buffer readback systems / render-world node wiring
- Impact: rendered/culled counts remain heuristic approximation, not GPU-authoritative counts.

5. Solari/pathtracer/DLSS modules are not present in mgstudio render API
- Missing equivalents for Bevy modules/components:
  - `SolariPlugins` / `SolariLighting`
  - `PathtracingPlugin` / `Pathtracer`
  - `RaytracingMesh3d`
  - DLSS RR components/resources
  - GPU Solari diagnostics feed used by `RenderDiagnosticsPlugin`
- Impact: `solari` remains raster-path adapted with emulated controls and text.

6. Scene-load material-name adaptation hooks are missing for exact Solari scene tuning
- Missing equivalent of Bevy’s `SceneInstanceReady` observer + `GltfMaterialName`-driven material patching pass in this example pipeline.
- Impact: robot light material and glass/material-specific adjustments are approximated via standalone lights/text, not mesh-material mutation by material name.

7. Primitive parity gap for emissive spheres in ManyLights
- `@render3d.Mesh3d` currently has no direct sphere primitive constructor (`from_sphere`-style API).
- Impact: emissive light proxies in `solari` ManyLights remain tetrahedron-based instead of sphere meshes.

## Validation

Executed in `mgstudio-engine/`:

- `moon check -p examples/3d/meshlet`
- `moon check -p examples/3d/occlusion_culling`
- `moon check -p examples/3d/solari`
- `moon check -p examples/3d/parallax_mapping`
- `moon check -p examples/3d/texture`
- `moon check -p examples/3d/wireframe`

Result:

- All targeted checks passed.
- One pre-existing package warning remains in `examples/3d/occlusion_culling/moon.pkg`:
  - `unused_package`: `Milky2018/mgstudio/time`
