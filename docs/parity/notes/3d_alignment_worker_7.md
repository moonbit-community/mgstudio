# 3D Alignment Worker 7 Notes

- Scope: `shadow_caster_receiver`, `skybox`, `solari`, `specular_tint`, `spherical_area_lights`, `split_screen`, `spotlight`, `ssao`, `ssr`
- Updated: 2026-02-28

## Completed in this pass

- `shadow_caster_receiver`
  - Updated directional-light orientation to match Bevy's ZYX-angle intent more closely.
- `skybox`
  - Added camera `Msaa::Off`, `ScreenSpaceAmbientOcclusion`, and `TemporalAntiAliasing` components to match Bevy camera stack.
  - Changed directional-light animation from orbiting translation to in-place yaw rotation (matching Bevy behavior).
- `specular_tint`
  - Set global ambient light to black/zero as in Bevy.
  - Replaced prior sinusoid tint approximation with HSV-equivalent hue sweep mapping (S=1, V=1).
- `spotlight`
  - Made ambient-light initialization robust (insert-or-update) to match Bevy's explicit ambient resource setup.
- `ssao`
  - Switched from proxy AO shading to real component wiring:
    - camera now has `Hdr`, `Msaa::Off`, `ScreenSpaceAmbientOcclusion`, `TemporalAntiAliasing`, `TemporalJitter`.
    - quality/thickness keys now update/remove actual SSAO component values.
    - `Space` now toggles `TemporalJitter` component presence.
  - Set ambient brightness baseline to Bevy-like `1000.0`.
- `ssr`
  - Switched default opaque renderer method to deferred.
  - Added Bevy-aligned camera stack components: `Hdr`, `Msaa::Off`, `TemporalAntiAliasing`, `ScreenSpaceAmbientOcclusion`, environment map light, skybox.
  - Aligned default SSR roughness ranges and edge-fade adjustment granularity.
  - Aligned camera input step behavior and speeds closer to Bevy's constants.
- `split_screen`
  - Replaced placeholder cube grid with Bevy-aligned `Fox.glb` scene content.
  - Kept split viewport behavior and keyboard camera-rotation controls.
- `spherical_area_lights`
  - Mapped radius sweep to light influence (intensity/range) so radius variation changes actual lighting, not just proxy mesh scale.
  - Attached point lights as children of the per-radius sphere entities to match Bevy scene topology more closely.
- `solari`
  - Aligned many-lights scene counts with Bevy defaults (`200` cubes, `100` emissive lights).
  - Aligned robot patrol speed to Bevy-like baseline (`1.0` units/s).

## Unresolved blockers

- `shadow_caster_receiver`
  - Bevy cascade-shadow config builder controls are not exposed as equivalent public controls in current mgstudio runtime APIs.
- `skybox`
  - Bevy's explicit cubemap reinterpret/view-dimension handling for stacked PNG (`TextureViewDimension::Cube`) is not exposed with equivalent control in current mgstudio asset/image APIs.
- `solari`
  - Solari realtime raytracing pipeline, pathtracer mode, raytracing-mesh components, DLSS integration, and GPU diagnostics are unavailable in current mgstudio runtime.
- `specular_tint`
  - No hard blocker identified for current parity target.
- `spherical_area_lights`
  - Bevy `PointLight.radius` area-light shading is not exposed directly; current port uses intensity/range mapping approximation.
- `split_screen`
  - Bevy per-viewport UI button interaction (`UiTargetCamera`-driven left/right buttons) is replaced with keyboard controls.
- `spotlight`
  - No hard blocker identified for current parity target.
- `ssao`
  - No hard blocker identified for current parity target.
- `ssr`
  - Bevy `ExtendedMaterial` deferred water shader path is not available; current implementation uses standard-material approximation for water while keeping deferred SSR controls.
