# 3D Alignment Worker Sweep Round2-B

Date: 2026-02-28
Owner scope: 3d sweep auditor/fixer for assigned unowned examples

## Summary
This sweep focused on low-conflict parity fixes in assigned files and avoided touching files that already showed active edits in this round.

### Applied parity fixes
1. `mgstudio-engine/examples/3d/3d_scene/main.mbt`
- Switched the point light initialization to Bevy-style defaults + explicit shadow enable:
  - From explicit `PointLight::new(..., 1_000_000.0, 20.0, true)`
  - To `PointLight::default().with_shadow_maps_enabled(true)`

2. `mgstudio-engine/examples/3d/fog/main.mbt`
- Added missing pyramid-scene parity elements from Bevy:
  - Added `NotShadowCaster` and `NotShadowReceiver` markers to the orb.
  - Added the large unlit sky cuboid (`scale = 1_000_000`, `cull_mode = None`).
  - Switched point light setup to Bevy-style default + shadow enable.
- Updated fog falloff handling to match current engine enum coverage:
  - Added `FogFalloff3d::Atmospheric` handling in all relevant matches.
- Updated color-control key mapping text and inputs to available keycodes while staying as close as possible to Bevy intent.

3. `mgstudio-engine/examples/3d/lighting/main.mbt`
- Aligned material defaults with Bevy setup:
  - Ground and wall materials now explicitly use `perceptual_roughness = 1.0`.
  - Bevy logo material now uses `perceptual_roughness = 1.0` and `cull_mode = None`.

## Files intentionally skipped due conflict risk
These assigned files already showed active edits in the worktree during this sweep and were not modified to avoid merge thrash:
- `mgstudio-engine/examples/3d/3d_shapes/main.mbt`
- `mgstudio-engine/examples/3d/3d_viewport_to_world/main.mbt`
- `mgstudio-engine/examples/3d/blend_modes/main.mbt`
- `mgstudio-engine/examples/3d/camera_sub_view/main.mbt`
- `mgstudio-engine/examples/3d/spotlight/main.mbt`

## Files reviewed but unchanged
- `mgstudio-engine/examples/3d/clearcoat/main.mbt`
- `mgstudio-engine/examples/3d/orthographic/main.mbt`
- `mgstudio-engine/examples/3d/parenting/main.mbt`
- `mgstudio-engine/examples/3d/texture/main.mbt` (optional file; not touched)

## Targeted checks
Executed:
- `moon check -p examples/3d/3d_scene`
- `moon check -p examples/3d/fog`
- `moon check -p examples/3d/lighting`

Result:
- Checks completed without new type/compile errors after the applied changes.

## Remaining blockers
1. Exact Bevy fog keybinding parity is not fully possible with current `@window.KeyCode` coverage:
- Missing: `Minus`, `Equal`, `BracketLeft`, `BracketRight`, `Quote`.
- Available alternatives were used for this round.

2. Files already under active edit in this round were intentionally deferred to avoid conflict; final text/constant parity for those files should be validated after their owners finish.
