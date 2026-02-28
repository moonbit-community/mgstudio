# 3D Alignment Worker Decal Round 2

- Date: 2026-02-28
- Scope: `decal`, `clustered_decals`, `clustered_decal_maps`, `deferred_rendering`, `ssr`, and `render3d` parity surface updates.
- Owner: `decals/material extension/deferred surface parity`

## Completed in This Pass

- `render3d` public parity surface
  - Added Bevy-aligned decal-facing public types in [`mgstudio-engine/render3d/render3d.mbt`]:
    - `ForwardDecal` (component marker)
    - `ForwardDecalMaterialExt` (`depth_fade_factor` API)
    - `ClusteredDecal` (base/normal/metallic-roughness/emissive textures + `tag`)
  - Added Bevy-aligned `DirectionalLightShadowMap` resource surface (`size`, power-of-two sanitization).
  - Updated [`mgstudio-engine/render3d/ecs.g.mbt`] trait surface to include new decal components/resources.
- `clustered_decals`
  - Aligned drag movement logic with Bevy spherical-orbit semantics (camera vs decal factors, theta clamp, center-facing orientation) instead of planar XY translation.
  - Aligned scaling behavior to multiplicative drag scaling (closer to Bevy `transform.scale *= ...`).
- `clustered_decal_maps`
  - Kept continuous spawn + in/out lifecycle behavior.
  - Refined emissive toggle flow from single flip-toggle to discrete On/Off controls (`E` => On, `R` => Off), preserving Bevy-style explicit state selection intent.
- `deferred_rendering`
  - Aligned directional-light animation to in-place yaw rotation behavior (closer to Bevy `rotate_y`) instead of orbiting translation.
- `ssr`
  - Reduced control surface to Bevy-nearer SSR/model/base/range controls by removing extra non-Bevy key controls from the on-screen instruction flow.

## Hard Runtime / Integration Blockers

1. Forward decal projection backend is still not active
- Even with `ForwardDecal` / `ForwardDecalMaterialExt` API surface exposed, projected forward decal rendering/shader specialization is not executed in current mgstudio backend.
- Impact: `decal` example still uses a translucent proxy mesh to represent decal volume.

2. Clustered decal projection backend is still not active
- `ClusteredDecal` API surface is exposed, but clustered projected decal rendering (including map-channel projection behavior) is not active.
- Impact: `clustered_decals` and `clustered_decal_maps` still rely on proxy meshes for visual behavior.

3. World-level codegen integration for newly added render3d surfaces was out of owned-file scope
- This pass only touched `render3d/*` and owned examples.
- `@ecs_world.World` accessors/impl wiring for newly added render3d components/resources (generated world glue) was not updated in this owned scope.
- Impact: new surfaces are present in render3d API, but end-to-end world accessor parity still requires follow-up codegen/integration pass.

4. Directional shadow-map size resource is not fully wired into renderer execution
- `DirectionalLightShadowMap` surface exists, but deferred/lighting runtime consumption parity is not fully active.
- Impact: Bevy-equivalent shadow-map size tuning remains partial.

5. SSR water material extension parity remains unavailable
- Bevy deferred `ExtendedMaterial<StandardMaterial, Water>` shader path is still not available.
- Impact: `ssr` water remains approximated with standard-material animation.

## Targeted Checks Run

- `moon check render3d`
- `moon check examples/3d/decal`
- `moon check examples/3d/clustered_decals`
- `moon check examples/3d/clustered_decal_maps`
- `moon check examples/3d/deferred_rendering`
- `moon check examples/3d/ssr`
