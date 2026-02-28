# 3D Alignment Worker 5 Notes

- Date: 2026-02-28
- Scope: `mixed_lighting`, `motion_blur`, `occlusion_culling`, `order_independent_transparency`, `orthographic`, `parallax_mapping`, `parenting`, `pbr`
- Owner: `GROUP-5`

## Completed in This Pass

- `order_independent_transparency`: aligned test-scene content closer to Bevy source (`spheres`, `quads`, `occlusion`, `auto instancing`) and switched OIT toggle semantics to camera-component add/remove instead of alpha-mode proxy.
- `parallax_mapping`: normal map now loads with `ImageLoaderSettings.with_is_srgb(false)` to match Bevy's linear normal-map handling.
- `pbr`: camera orthographic projection now explicitly uses window-size scaling; environment-map loading label is now despawned after both maps load.
- `orthographic` and `parenting`: no functional delta required in this pass.

## Unresolved Blockers

1. `mixed_lighting`
- Missing ECS/runtime surface for per-mesh `Lightmap` assignment (`image`, `uv_rect`, exposure path) blocks exact parity.
- Missing Bevy-equivalent pointer picking hit stream (`PointerInteraction`/`HitData`) blocks exact click-to-surface sphere placement behavior.
- Current example remains an adapted fallback (keyboard mode selection + camera ray/ground-plane intersection).

2. `motion_blur`
- Exact parity requires renderer-level validation of motion-vector + depth-prepass resolve behavior across web/native backends.
- Current API exposes `MotionBlur`, but parity sign-off remains blocked without cross-backend render equivalence evidence.

3. `occlusion_culling`
- Missing render-world hooks for indirect-parameter staging/readback blocks exact rendered-mesh count introspection.
- Current implementation preserves camera `DepthPrepass`/`OcclusionCulling` toggles but uses heuristic status text instead of GPU readback counts.

4. `order_independent_transparency`
- Missing weighted OIT resolve implementation in renderer blocks exact Bevy behavior.
- Current example keeps Bevy-like controls and camera marker semantics, but visual output is still bounded by fallback blending path.

## Suggested Engine Follow-ups

- Add `Lightmap` component pipeline and material exposure parity hooks.
- Add pointer-picking hit-data API for world-surface interaction parity.
- Add render-app bridge for indirect draw-parameter readback.
- Implement weighted order-independent transparency resolve path.
- Add cross-backend screenshot or pixel-diff harness for motion-blur parity validation.
