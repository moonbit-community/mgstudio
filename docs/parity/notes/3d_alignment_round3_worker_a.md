# 3D Alignment Round3 Worker A

- Date: `2026-02-28`
- Owner: `3d examples set A parity tightening (rendering-heavy)`
- Scope:
  - `examples/3d/decal`
  - `examples/3d/clustered_decals`
  - `examples/3d/clustered_decal_maps`
  - `examples/3d/deferred_rendering`
  - `examples/3d/ssr`
  - `examples/3d/ssao`
  - `examples/3d/order_independent_transparency`
- Bevy sources compared:
  - `bevy/examples/3d/decal.rs`
  - `bevy/examples/3d/clustered_decals.rs`
  - `bevy/examples/3d/clustered_decal_maps.rs`
  - `bevy/examples/3d/deferred_rendering.rs`
  - `bevy/examples/3d/ssr.rs`
  - `bevy/examples/3d/ssao.rs`
  - `bevy/examples/3d/order_independent_transparency.rs`

## Completed Alignment in This Round

1. `examples/3d/decal`
- Switched the main decal entity to attach real decal components:
  - `@render3d.ForwardDecal`
  - `@render3d.ForwardDecalMaterialExt::new(1.0)`
- Kept a proxy decal volume mesh as visual fallback while renderer-side forward decal projection remains unavailable.
- Tightened camera/prepass/MSAA/FXAA flow and point light setup to Bevy-style intent.

2. `examples/3d/clustered_decals`
- Attached `@render3d.ClusteredDecal` on both decal entities with Bevy-aligned texture + tag values (`1`/`2`).
- Preserved Bevy-like interaction flow (selection buttons, hover-to-switch drag mode, cursor hint).
- Tightened directional light setup toward Bevy default behavior.

3. `examples/3d/clustered_decal_maps`
- Attached `@render3d.ClusteredDecal` on each spawned decal with base/normal/metallic-roughness/emissive channels.
- Updated texture loading to use linear-space settings where appropriate:
  - `@asset.ImageLoaderSettings::with_is_srgb(false)` for normal and metallic-roughness textures.
- Preserved Bevy animation flow (spawn interval, animate-in, idle, animate-out lifecycle).

4. `examples/3d/deferred_rendering`
- Added Bevy-aligned directional shadow-map resource hookup:
  - `@ecs_world.World::get_directional_light_shadow_map_resource()`
  - `@render3d.DirectionalLightShadowMap::new(4096)`
- Added Bevy-aligned cascade setup on directional light:
  - `@render3d.CascadeShadowConfigBuilder::with_num_cascades(3)`
  - `@render3d.CascadeShadowConfigBuilder::with_maximum_distance(10.0)`
- Tightened spin flow so only the parallax object is in the spin target set, matching Bevy system intent.
- Loaded parallax normal map with linear settings (`is_srgb = false`).

5. `examples/3d/ssr`
- Loaded water normal map with explicit linear + repeating sampler settings:
  - `@asset.ImageLoaderSettings::with_is_srgb(false)`
  - `@asset.ImageLoaderSettings::with_sampler(@asset.ImageSampler::LinearRepeat)`
- Tightened model rotation to Bevy’s elapsed-time Y rotation behavior.

6. `examples/3d/ssao`
- Aligned startup SSAO defaults with Bevy defaults:
  - quality: `High`
  - `constant_object_thickness: 0.25`

7. `examples/3d/order_independent_transparency`
- Tightened controls/text flow to Bevy example behavior (`T` toggle OIT, `C` cycle scenes).
- Removed non-Bevy extra runtime tuning controls (`1..6`) from the example-level UX.
- Kept transparent materials consistently in `AlphaMode3d::Blend` to mirror Bevy comparison behavior.
- Fixed scene parity issue in occlusion test: center cube now spawns at `x = 0.0` for the intersection pair.

## Remaining Blockers (Exact API / Module Names)

1. Forward and clustered decals are not consumed by the active render execution path
- Available API surface:
  - `@render3d.ForwardDecal`
  - `@render3d.ForwardDecalMaterialExt`
  - `@render3d.ClusteredDecal`
- Blocking integration point:
  - `@render3d.Render3dExecuteWorld` bounds in `mgstudio-engine/render3d/render3d.mbt` do not include decal traits (`Has_ForwardDecal`, `Has_ForwardDecalMaterialExt`, `Has_ClusteredDecal`).
  - `render3d_execute_system` does not query these component stores.
- Impact: decal examples still require proxy meshes for visible output.

2. Clustered-decal usability probe API is missing
- Missing equivalent for Bevy’s runtime capability check:
  - `decal::clustered::clustered_decals_are_usable(...)`
- Impact: no early platform gate / error-path parity in `clustered_decals`.

3. Material extension path is missing
- Missing Bevy-equivalent extension stack:
  - `ExtendedMaterial`
  - `MaterialExtension`
  - `MaterialPlugin::<ExtendedMaterial<...>>`
- Impact:
  - `clustered_decals`: custom decal extension shader (`tag`-based tint) cannot be ported directly.
  - `ssr`: custom deferred water material shader path cannot be ported directly.

4. OIT settings are not consumed by the current renderer
- Available component:
  - `@render3d.OrderIndependentTransparencySettings`
- Blocking integration point:
  - no `Has_OrderIndependentTransparencySettings` in `@render3d.Render3dExecuteWorld` bounds.
  - no OIT settings query/use in `render3d_execute_system`.
- Impact: camera OIT component flow is API-aligned, but weighted OIT resolve parity is still pending.

5. SSAO component is not consumed by the current renderer
- Available component:
  - `@render3d.ScreenSpaceAmbientOcclusion`
- Blocking integration point:
  - no `Has_ScreenSpaceAmbientOcclusion` in `@render3d.Render3dExecuteWorld` bounds.
  - no SSAO query/use in `render3d_execute_system`.
- Impact: example controls are aligned, but full SSAO render parity depends on backend execution hookup.

6. Primitive constructor parity gaps for certain Bevy meshes
- Missing direct constructors in `@render3d.Mesh3d`:
  - `from_sphere`
  - `from_capsule`
- Impact: some examples still rely on generated UV-sphere or cuboid proxies where Bevy uses sphere/capsule primitives.

## Validation

Executed in `mgstudio-engine/`:

- `moon check -p examples/3d/decal`
- `moon check -p examples/3d/clustered_decals`
- `moon check -p examples/3d/clustered_decal_maps`
- `moon check -p examples/3d/deferred_rendering`
- `moon check -p examples/3d/ssr`
- `moon check -p examples/3d/ssao`
- `moon check -p examples/3d/order_independent_transparency`

Result:

- All targeted checks returned success (`Finished. moon: no work to do`).
- Some runs waited briefly on `_build/.moon-lock` due concurrent checks.
