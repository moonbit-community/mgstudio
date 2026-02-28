# 3D Alignment Worker Lighting Round 2

- Scope owner: `lighting/shadow/lightmap/reflection/mesh utilities parity`
- Date: `2026-02-28`
- Owned paths touched:
  - `mgstudio-engine/render3d/*`
  - `mgstudio-engine/mesh/*`
  - `mgstudio-engine/asset/*`
  - `mgstudio-engine/examples/3d/{shadow_caster_receiver,lightmaps,mixed_lighting,reflection_probes,rotate_environment_map}/main.mbt`

## Completed in this round

1. Cascaded shadow config API surface
- Added Bevy-shaped API in `@render3d`:
  - `CascadeShadowConfig`
  - `CascadeShadowConfigBuilder`
  - Builder methods for `num_cascades`, `minimum_distance`, `maximum_distance`, `first_cascade_far_bound`, and `overlap_proportion`
- Added directional-light wiring surface:
  - `DirectionalLight.cascade_shadow_config : CascadeShadowConfig?`
  - `DirectionalLight::with_cascade_shadow_config(...)`
  - `DirectionalLight::with_cascade_shadow_config_builder(...)`
- Updated `shadow_caster_receiver` example to configure:
  - `first_cascade_far_bound = 7.0`
  - `maximum_distance = 25.0`

2. Image usage mutation support (reflection probe blocker)
- Added public image usage bit API in `@asset`:
  - constants: `IMAGE_USAGE_TEXTURE_BINDING`, `IMAGE_USAGE_COPY_DST`, `IMAGE_USAGE_COPY_SRC`, `IMAGE_USAGE_RENDER_ATTACHMENT`
  - mutation/query: `asset_image_set_usage_bits`, `asset_image_add_usage`, `asset_image_remove_usage`, `asset_image_has_usage`, `asset_image_usage_bits`
- Added internal usage metadata tracking for loaded/generated images.
- Updated `reflection_probes` example with Bevy-like setup pass that ensures `COPY_SRC` usage on the specular environment map before generated-environment usage.

3. Mesh tangent generation API exposure
- Added tangent data slot on `Mesh3dGeometry` and validation coverage:
  - `mut tangents : Array[Vec4]?`
  - `Mesh3dValidationError::TangentLengthMismatch`
- Added tangent API:
  - `Mesh3dGeometry::generate_tangents()`
  - `Mesh3dGeometry::has_tangents()`, `tangent(...)`, `replace_tangents(...)`, `clear_tangents()`
  - `Mesh3dGenerateTangentsError`
- Added mesh-level forwarding API:
  - `Mesh::generate_tangents()`
  - `MeshGenerateTangentsError`
- Updated `rotate_environment_map` example to call tangent generation on the procedural sphere mesh.

4. Lightmaps example semantic alignment touch-up
- In `lightmaps`, added deferred-camera prepass insertion when `args.deferred` is enabled:
  - `DepthPrepass`, `MotionVectorPrepass`, `DeferredPrepass`, `Msaa::Off`

## Remaining blockers after this round

1. Cascade config is currently data-surface only
- `CascadeShadowConfig`/builder values are stored and configurable, but renderer/backend shadow cascade sampling and split application are not yet implemented.
- Impact: API parity improved, visual parity for cascaded shadow behavior remains adapted.

2. Image usage mutation is currently metadata-level only
- Usage bits can be mutated and queried from engine API.
- Runtime backend texture descriptor mutation/recreation flow is still missing, so usage changes are not guaranteed to alter backend allocation behavior today.
- Impact: reflection probe setup now has API parity, but backend-level usage enforcement remains adapted.

3. Tangent data is generated but not yet consumed by GPU mesh upload/shader path
- Tangent vectors are now generated/stored in mesh geometry.
- Existing upload/draw path still uses XYZ/UV/RGBA surface only.
- Impact: mesh API parity blocker closed at surface level; full normal-map parity still needs tangent attribute propagation in renderer.

4. Lightmap component pipeline is still incomplete
- Per-mesh Bevy `Lightmap` component semantics (`image`, `uv_rect`, `bicubic_sampling`) and full material integration remain missing.
- Impact: `lightmaps` / `mixed_lighting` remain adapted where true per-mesh lightmap behavior is required.

## Targeted validation

Executed:
- `moon check -p mesh`
- `moon check -p asset`
- `moon check -p render3d`
- `moon check -p examples/3d/shadow_caster_receiver`
- `moon check -p examples/3d/lightmaps`
- `moon check -p examples/3d/mixed_lighting`
- `moon check -p examples/3d/reflection_probes`
- `moon check -p examples/3d/rotate_environment_map`

Result:
- All targeted checks passed.
- Existing unrelated warning in `render3d/render3d.mbt:3624` remains unchanged in this round.
