# 3D Alignment Worker Interaction Round 2

- Date: 2026-02-28
- Owner: `interaction/gizmos/picking`
- Scope:
  - `mgstudio-engine/input/*`
  - `mgstudio-engine/render3d/*`
  - `examples/3d/mesh_ray_cast`
  - `examples/3d/light_probe_blending`
  - `examples/3d/split_screen`
  - `examples/3d/contact_shadows`

## Completed in This Pass

1. Added Bevy-style mesh ray-cast convenience shim in `@render3d`.
- New API surface:
  - `MeshRayCastSettings`
  - `MeshRayCastHit`
  - `mesh_ray_cast(...)`
  - `mesh_ray_cast_first(...)`
  - `mesh_ray_cast_from_camera(...)`
  - `mesh_ray_cast_from_camera_first(...)`
- Runtime behavior:
  - World-space ray against visible `Mesh3d` entities.
  - AABB-based hit testing (local mesh bounds + transform conversion).
  - Distance-sorted hits with optional entity allow-list (`only_entities`).

2. Added cross-backend primary-pointer input helpers in `@input`.
- New helpers:
  - `mouse_motion_delta()` / `mouse_motion_delta_opt()`
  - `primary_pointer_position()`
  - `primary_pointer_pressed()` / `primary_pointer_just_pressed()` / `primary_pointer_just_released()`
  - `primary_pointer_delta()` / `primary_pointer_delta_opt()`
- Intent:
  - Keep camera/picking interactions behaviorally closer between web and wasmtime.
  - Unify mouse + touch fallback paths for example controls.

3. Updated `mesh_ray_cast` example to use the new ray-cast shim.
- Removed analytic box-plane intersection code path.
- Uses `mesh_ray_cast_first` with `only_entities` restricted to the six box planes.
- Keeps mesh-primitive visualization fallback for missing `Gizmos` line/sphere API parity.
- Cursor ray now consumes `primary_pointer_position()`.

4. Updated `light_probe_blending` input flow.
- Removed per-example manual `last_mouse_position` tracking.
- Orbit/free-look now consume `primary_pointer_pressed()` + `primary_pointer_delta()`.
- Kept keyboard fallback controls and existing gizmo visibility toggle behavior.

5. Updated `split_screen` interaction fallback.
- Kept keyboard controls (`1..4`, `Left/Right`).
- Added primary-pointer click to select active viewport camera.
- Added primary-pointer drag to rotate selected camera.
- This is a lightweight replacement for Bevy's per-viewport `UiTargetCamera` button widgets.

6. Updated `contact_shadows` interaction fallback.
- Added primary-pointer drag model rotation (`Pointer<Drag>`-style fallback).
- Kept keyboard rotation fallback.
- Ground shadow receive toggle now uses `NotShadowReceiver` component insertion/removal on the ground entity.

## Residual Blockers

1. Mesh ray cast precision parity
- Current shim is AABB-based, not triangle-accurate.
- Missing Bevy-equivalent per-triangle `HitData` semantics and barycentric/face data.

2. Full MeshRayCast filtering parity
- Missing richer Bevy-style filter expressions and backend picking integration semantics.
- Current filtering is limited to visibility + optional explicit entity allow-list.

3. 3D Gizmos parity
- Real Bevy `Gizmos` drawing API is still missing.
- Examples still rely on mesh primitives for debug visualization.

4. Contact shadows pointer picking parity
- Drag fallback is global pointer drag, not true per-entity pointer over/out/drag-end routed by a 3D picking backend.
- Cursor icon transitions (`Grab` / `Grabbing`) are still not mapped.

5. Split-screen per-viewport UI routing parity
- Bevy `UiTargetCamera` + widget event routing is still not implemented.
- Current behavior uses pointer-derived viewport selection and drag rotation instead of per-viewport UI buttons.

## Targeted Checks

- `moon check render3d`
- `moon check examples/3d/mesh_ray_cast`
- `moon check examples/3d/light_probe_blending`
- `moon check examples/3d/split_screen`
- `moon check examples/3d/contact_shadows`

Result: all above checks passed with existing `render3d` warnings (`unused_struct_update`), no new errors from this pass.
