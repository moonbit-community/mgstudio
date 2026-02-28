# 3D Alignment Worker 3 Notes

- Date: 2026-02-28
- Scope: `contact_shadows`, `decal`, `deferred_rendering`, `depth_of_field`, `fog`, `fog_volumes`, `generate_custom_mesh`, `irradiance_volumes`
- Owner: `GROUP-3`

## Completed in This Pass

- `contact_shadows`
  - Aligned receiver toggle semantics with Bevy by switching ground behavior to `NotShadowReceiver` component add/remove instead of material-color proxy.
- `decal`
  - Added Bevy-aligned camera pipeline components: `FreeCamera`, `DepthPrepass`, `Msaa::Off`, and `Fxaa`.
  - Kept decal volume proxy mesh path for unsupported material extension.
- `deferred_rendering`
  - Added `EnvironmentMapLight` setup on the camera.
  - Added two `FlightHelmet` scene instances to match Bevy scene composition.
  - Added sky proxy mesh with `NotShadowCaster` and `NotShadowReceiver` markers.
- `fog_volumes`
  - Added `Hdr` component on the camera for closer Bevy camera setup alignment.
- `irradiance_volumes`
  - Marked voxel visualization cubes as `NotShadowCaster` to align with Bevy intent.

## Unresolved Capability Blockers

1. `contact_shadows`
- Bevy widget-based UI (`widgets.rs`) and pointer drag/cursor icon interaction path are not exposed in current mgstudio runtime surface.
- Current port keeps keyboard controls and model rotation fallback.

2. `decal`
- Bevy forward decal pipeline is unavailable (`ForwardDecal`, `ForwardDecalMaterial`, `ForwardDecalMaterialExt`).
- Current port renders a textured translucent proxy cube to preserve scene semantics.

3. `deferred_rendering`
- Native deferred renderer execution path is unavailable (`Opaque3dDeferred` render path equivalence).
- Directional shadow map size resource parity (`DirectionalLightShadowMap`) is not exposed.

4. `depth_of_field`
- Bevy DOF post-process stack is unavailable (`DepthOfField` with Bokeh/Gaussian runtime modes).
- Current port maps focus/aperture controls to projection + fog/lighting proxies.

5. `fog`
- No hard engine blocker identified for current parity scope.
- Input mapping remains keyboard-adapted to runtime key handling conventions.

6. `fog_volumes`
- Bevy volumetric fog pipeline is unavailable (`FogVolume`, `VolumetricFog`, `VolumetricLight`).
- Current port approximates behavior through distance-fog + proxy geometry.

7. `generate_custom_mesh`
- No hard engine blocker identified for current parity scope.

8. `irradiance_volumes`
- Bevy voxel visualization material extension path is unavailable (`ExtendedMaterial` + custom shader extension hooks).
- Animation graph playback setup for the fox is not exposed with Bevy-equivalent API semantics in this example path.
- Bevy 3D gizmo rendering path used for debug visualization is unavailable.

## Suggested Engine Follow-ups

- Add forward decal material extension support.
- Add renderer-level deferred execution parity (including shadow-map resource sizing controls).
- Add native depth-of-field post-processing components.
- Add volumetric fog volume/light components.
- Add custom material extension shader hooks for voxel visualization and 3D gizmo rendering APIs.
- Add animation graph/player parity hooks required by `irradiance_volumes`.
