# 3D Alignment Worker 1 - Remaining Engine Blockers

## Blocker 1
- missing capability: Native anti-aliasing pipelines and post-process sharpening components equivalent to Bevy `Msaa/Fxaa/Smaa/TemporalAntiAliasing/Dlss/ContrastAdaptiveSharpening`.
- affected examples: `anti_aliasing`.
- exact file/API needed: `mgstudio-engine/render3d/*` camera AA component stores and runtime pass integration in `mgstudio-runtime/native-wasmtime/src/gpu_backend.rs` (and corresponding web backend) for AA method selection and CAS post-process controls.
- why blocked: Current engine exposes no runtime-selectable AA/camera post-process components, so the example can only approximate visual differences via material/fog proxies.

## Blocker 2
- missing capability: Atmosphere scattering pipeline parity with Bevy (`Atmosphere`, `ScatteringMedium`, `AtmosphereSettings`, and atmosphere-driven environment lighting).
- affected examples: `atmosphere`.
- exact file/API needed: new render3d atmosphere ECS/component APIs in `mgstudio-engine/render3d/*` plus shader/runtime integration in `mgstudio-runtime/native-wasmtime/src/gpu_backend.rs` and web runtime host pipeline.
- why blocked: There is no atmospheric scattering render path in mgstudio yet, so the example can only emulate color/fog/exposure behavior.

## Blocker 3
- missing capability: Volumetric fog/light volume components equivalent to Bevy (`FogVolume`, `VolumetricFog`, `VolumetricLight`).
- affected examples: `atmosphere`.
- exact file/API needed: volumetric fog/light component stores and rendering passes under `mgstudio-engine/render3d/*` and runtime volumetric passes in native/web backends.
- why blocked: The engine currently provides only global `DistanceFog` and cannot represent participating media volumes or volumetric light shafts.

## Blocker 4
- missing capability: Extended deferred material extension path for custom shader materials (`ExtendedMaterial<StandardMaterial, T>` style pipeline).
- affected examples: `atmosphere` (animated water material).
- exact file/API needed: material extension API surface in `mgstudio-engine/render3d/*` and deferred material shader hook points in `mgstudio-runtime/native-wasmtime/src/gpu_backend.rs`.
- why blocked: Custom per-material deferred shader extensions are not supported, so water is approximated with animated standard-material parameters.

## Blocker 5
- missing capability: Directional-light inscattering fields on distance fog (`directional_light_color`, `directional_light_exponent`) and `FogFalloff::from_visibility_colors` equivalent.
- affected examples: `atmospheric_fog`.
- exact file/API needed: `mgstudio-engine/render3d/DistanceFog` API expansion and runtime fog shader uniforms in native/web render backends.
- why blocked: Current `DistanceFog` only contains `color` and basic falloff modes (`Linear/Exponential/ExponentialSquared`), so directional inscattering is approximated in gameplay code.

## Blocker 6
- missing capability: Immediate-mode 3D gizmo API parity with Bevy `Gizmos::circle(...)`.
- affected examples: `3d_viewport_to_world`.
- exact file/API needed: a `gizmo` drawing API in `mgstudio-engine/render3d/*` (or dedicated gizmo package) plus per-frame debug primitive rendering support in `mgstudio-runtime/native-wasmtime/src/gpu_backend.rs` and web runtime backend.
- why blocked: mgstudio has no exposed gizmo API, so the example must keep a persistent circle mesh entity and toggle its transform/visibility each frame.

## Blocker 7
- missing capability: Cascaded shadow configuration component parity with Bevy `CascadeShadowConfigBuilder`.
- affected examples: `atmospheric_fog`.
- exact file/API needed: directional-light cascade shadow config component/store in `mgstudio-engine/render3d/*` and cascade split upload/apply path in native/web renderer backends.
- why blocked: mgstudio does not expose a cascade shadow configuration API, so the example cannot tune cascade bounds like Bevy (`first_cascade_far_bound`, `maximum_distance`).

## Blocker 8
- missing capability: Required terrain asset packaging for direct scene parity (`models/terrain/Mountains.gltf` and companion files) under mgstudio asset root.
- affected examples: `atmospheric_fog`.
- exact file/API needed: add `assets/models/terrain/Mountains.gltf` (plus referenced buffers/textures) in `mgstudio-engine/assets`, or provide an equivalent scene asset path consumed by `@scene.scene_load_gltf_scene`.
- why blocked: the Bevy terrain scene asset is not present in `mgstudio-engine/assets`, so the example uses a procedural terrain proxy instead of loading the original GLTF scene.
