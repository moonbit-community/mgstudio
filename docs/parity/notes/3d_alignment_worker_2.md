# 3D Alignment Worker 2 Notes

Date: 2026-02-28
Scope: `auto_exposure`, `blend_modes`, `bloom_3d`, `camera_sub_view`, `clearcoat`, `clustered_decal_maps`, `clustered_decals`, `color_grading`.

## Summary
- Implemented cursor icon plumbing (`Default` / `EwResize`) end-to-end and wired it into `clustered_decals`.
- Wired real camera `ColorGrading` + `Hdr` in `color_grading`.
- Wired real camera `Bloom` + `Hdr` + `Tonemapping::TonyMcMapface` in `bloom_3d`.
- Remaining differences are now concentrated in advanced post-process/decal features.

## Resolved in This Burn-Down

### Cursor style (`clustered_decals` dependency)
- Added `window_set_cursor_icon` host API path:
  - engine `window` package API surface
  - runtime native host import + Cocoa backend
  - runtime web host import + JS bridge
  - native-wasmtime host import + winit backend
- Added `CursorIcon::EwResize` usage in `clustered_decals` for hover affordance on Scale/Roll drag buttons.

### `color_grading`
- Example now writes camera `ColorGrading` component values directly (`get_color_grading_store`) and enables camera `Hdr`.
- Previous proxy-based light/fog shaping is retained only as supplemental visual behavior.

### `bloom_3d`
- Example now uses real camera components for `Hdr`, `Tonemapping::TonyMcMapface`, and `Bloom` intensity/toggle.
- Existing proxy controls remain for advanced Bevy bloom parameters not yet represented by mgstudio's `Bloom` struct.

## Remaining Engine/Runtime Gaps

### `auto_exposure`
- Missing direct parity for Bevy's auto-exposure pipeline (`AutoExposurePlugin`, camera `AutoExposure`, compensation curve assets, metering-mask evaluation in post-process).
- Example currently uses ambient-light proxy smoothing instead of true histogram/compute driven exposure adaptation.

### `bloom_3d`
- Advanced Bevy bloom fields still missing (`low_frequency_boost`, curvature, prefilter, composite mode, anisotropic scale axes).
- Current example maps those advanced fields to emissive/ambient proxies.

### `clustered_decal_maps`
- Missing native `ClusteredDecal` map-channel pipeline parity (projected decal rendering path with normal/metallic-roughness/emissive maps).
- Current example uses translucent mesh decals to preserve lifecycle/animation/control behavior.

### `clustered_decals`
- Missing native `ClusteredDecal` projection and custom decal material extension shader parity.
- Current example preserves Bevy-like UI + drag control flow and now has `EwResize` cursor feedback, but still uses proxy meshes.

### `color_grading`
- Camera `ColorGrading` component parity is implemented.
- Residual differences are in exact UI parity polish and combined proxy-light/fog behavior retained for visual continuity.

## Notes on Near-Parity Examples

### `blend_modes`
- Behavior and controls are aligned at example level.
- Any residual differences are implementation-level (engine internals, exact random stream equivalence).

### `camera_sub_view`
- Multi-camera layout, moving sub-view offsets, and resize behavior are aligned.

### `clearcoat`
- Scene composition and controls are aligned.
- Residual differences are tied to rendering backend internals (exact material/light pipeline output).
