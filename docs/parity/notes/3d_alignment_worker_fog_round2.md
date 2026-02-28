# 3D Alignment Worker Fog Round 2

- Scope: `render3d` fog/atmosphere surfaces and examples
  `atmospheric_fog`, `atmosphere`, `scrolling_fog`, `fog_volumes`
- Updated: 2026-02-28

## Completed in this pass

- `render3d` fog API alignment:
  - Extended `DistanceFog` with Bevy-aligned fields:
    `directional_light_color`, `directional_light_exponent`.
  - Extended `FogFalloff3d` with `Atmospheric(extinction, inscattering)`.
  - Added Bevy-style fog helper parity methods:
    `from_visibility*`, `from_visibility*_color(s)`, and Koschmieder threshold support.
- `render3d` fog behavior:
  - Implemented atmospheric per-channel fog application (extinction + inscattering) in draw path.
  - Implemented directional-light fog glow approximation driven by view/light alignment,
    directional-light color, exponent, and illuminance.
- Volumetric/atmosphere data-model stubs:
  - Added API-parity stubs for
    `VolumetricFog`, `FogVolume`, `VolumetricLight`,
    `Atmosphere`, `AtmosphereSettings`, `AtmosphereMode`,
    `ScatteringMedium`, `AtmosphereEnvironmentMapLight`.
- Example alignment updates:
  - `atmospheric_fog`: switched to direct `DistanceFog` directional fields +
    `FogFalloff3d::from_visibility_colors`.
  - `atmosphere`: switched fog setup to visibility/color helper path; integrated atmosphere/volumetric stub state into approximation controls.
  - `scrolling_fog`: uses volumetric/fog-volume stub state and maps it to distance-fog approximation each frame.
  - `fog_volumes`: uses volumetric/fog-volume stub state and maps it to distance-fog approximation during camera orbit.

## TODO blockers (backend/runtime)

- [TODO] Per-camera fog ownership parity:
  `DistanceFog` is still applied through global runtime state, not as a camera ECS component.
- [TODO] Atmosphere rendering pipeline parity:
  no runtime/ECS wiring for atmospheric LUT generation and sampling
  (`Atmosphere` + `ScatteringMedium` + `AtmosphereSettings`).
- [TODO] Volumetric fog pipeline parity:
  no raymarching volumetric pass and no real `FogVolume` voxel integration with directional lights.
- [TODO] 3D density texture parity:
  no runtime path for Bevy-like scrolling 3D density textures (`density_texture` + UVW repeat sampling).
- [TODO] Volumetric lighting coupling parity:
  `VolumetricLight` is currently API-level only, without shader/pass-level coupling to fog volumes.
- [TODO] Atmosphere material extension parity:
  no `ExtendedMaterial` custom deferred shader path equivalent for Bevy water/atmosphere material extension usage.
