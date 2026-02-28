# 3D Alignment Worker 4 Notes

- Scope: `light_probe_blending`, `light_textures`, `lighting`, `lightmaps`, `lines`, `mesh_ray_cast`, `meshlet`, `mirror`
- Updated: 2026-02-28

## Completed in this pass

- Fixed `examples/3d/mirror` package breakage (`moon.pkg` imports + compile errors).
- Restored mirror camera drag/orbit behavior to orbit around Bevy's camera target instead of world origin.
- Replaced unavailable accumulated-mouse-motion resource access with local cursor-delta tracking.

## Unresolved blockers

- `light_probe_blending`
  - No hard engine blocker currently; UI widgets remain keyboard-adapted rather than Bevy widget UI.
- `light_textures`
  - Renderer does not yet apply Bevy-equivalent light-cookie projection.
  - `DirectionalLightTexture` / `SpotLightTexture` / `PointLightTexture` surfaces are present, but visual effect is runtime-adapted.
- `lighting`
  - No known hard blocker for current parity target.
- `lightmaps`
  - Per-mesh `Lightmap` component surface (`image`, `uv_rect`, `bicubic_sampling`) is not exposed.
  - Deferred prepass components used by Bevy are not exposed in the current runtime surface.
- `lines`
  - No known hard blocker for current parity target.
- `mesh_ray_cast`
  - Bevy `MeshRayCast` system parameter is unavailable.
  - Bevy 3D `Gizmos` line/sphere rendering path is unavailable.
- `meshlet`
  - Experimental meshlet pipeline is unavailable (`MeshletPlugin`, `MeshletMesh3d`, meshlet-processed asset format, debug material flow).
- `mirror`
  - Bevy `ExtendedMaterial` + screen-space mirror shader path is not available in current renderer.
  - Projection near-plane normal clipping path is unavailable.
  - `Camera::invert_culling` equivalent is unavailable.
