# 3D Alignment Blockers Master

- Updated: 2026-02-28
- Sources:
  - `docs/parity/notes/3d_alignment_worker_1.md`
  - `docs/parity/notes/3d_alignment_worker_2.md`
  - `docs/parity/notes/3d_alignment_worker_3.md`
  - `docs/parity/notes/3d_alignment_worker_4.md`
  - `docs/parity/notes/3d_alignment_worker_5.md`
  - `docs/parity/notes/3d_alignment_worker_6.md`
  - `docs/parity/notes/3d_alignment_worker_7.md`
- Scope: consolidated unresolved blockers for Bevy `examples/3d` parity.

## Consolidated Blocker Matrix

| Recommended Order | Blocker Category | Affected Bevy 3D Examples | Current mgstudio Gap (Exact API/Module) | Feasibility |
|---|---|---|---|---|
| 1 | Material Extension and Shader Hook Framework | `bevy/examples/3d/atmosphere.rs`, `bevy/examples/3d/clustered_decals.rs`, `bevy/examples/3d/mirror.rs`, `bevy/examples/3d/ssr.rs`, `bevy/examples/3d/irradiance_volumes.rs` | Missing generalized `ExtendedMaterial<StandardMaterial, T>`-style extension path and shader hook surface in `@render3d` plus backend pass integration in runtime GPU pipelines. | Large |
| 2 | Decal Projected Rendering | `bevy/examples/3d/decal.rs`, `bevy/examples/3d/clustered_decals.rs`, `bevy/examples/3d/clustered_decal_maps.rs` | Missing projected decal APIs and passes in `@render3d`: `ForwardDecal`, `ForwardDecalMaterial`, `ForwardDecalMaterialExt`, and `ClusteredDecal`-equivalent execution path. | Large |
| 3 | Deferred Renderer and Shadow Configuration | `bevy/examples/3d/deferred_rendering.rs`, `bevy/examples/3d/post_processing.rs`, `bevy/examples/3d/shadow_caster_receiver.rs`, `bevy/examples/3d/lightmaps.rs` | Missing full deferred render-path equivalence (`OpaqueRendererMethod::Deferred` runtime behavior), missing public `DirectionalLightShadowMap` controls, missing `CascadeShadowConfigBuilder`-equivalent API in `@render3d`. | Large |
| 4 | Volumetric Fog and Volumetric Light Family | `bevy/examples/3d/fog_volumes.rs`, `bevy/examples/3d/scrolling_fog.rs`, `bevy/examples/3d/atmosphere.rs` | Missing public volumetric surfaces in `@render3d`: `FogVolume`, `VolumetricFog`, `VolumetricLight`, volumetric density texture controls (`density_texture_offset`-style behavior), and related runtime passes. | Large |
| 5 | Atmosphere Scattering Pipeline | `bevy/examples/3d/atmosphere.rs` | Missing atmosphere feature family in `@render3d`: `Atmosphere`, `ScatteringMedium`, `AtmosphereSettings`, and atmosphere-coupled environment-light behavior. | Large |
| 6 | Anti-Aliasing and Sharpening Stack | `bevy/examples/3d/anti_aliasing.rs`, `bevy/examples/3d/skybox.rs` | Missing/partial parity for camera AA selection and sharpening controls in `@render3d` + runtime backends: `Msaa/Fxaa/Smaa/TemporalAntiAliasing/Dlss/ContrastAdaptiveSharpening` end-to-end behavior and platform-specific camera extra wiring. | Large |
| 7 | Camera Post-Process Optics and Grading | `bevy/examples/3d/auto_exposure.rs`, `bevy/examples/3d/bloom_3d.rs`, `bevy/examples/3d/color_grading.rs`, `bevy/examples/3d/depth_of_field.rs` | Missing or incomplete parity in `@render3d` post-process surfaces: `AutoExposurePlugin`/`AutoExposure`, compensation-curve and metering-mask flow, full `Bloom` compositor parity, `ColorGrading` parity, and `DepthOfField` mode parity (Bokeh/Gaussian/Off). | Large |
| 8 | SSAO and SSR Runtime Parity | `bevy/examples/3d/ssao.rs`, `bevy/examples/3d/ssr.rs` | Missing Bevy-equivalent SSAO + temporal-jitter control surfaces and missing full deferred SSR + water material extension pipeline in runtime renderer. | Large |
| 9 | Lightmap Data Model and Integration | `bevy/examples/3d/lightmaps.rs`, `bevy/examples/3d/mixed_lighting.rs` | Missing per-mesh lightmap component surface in `@render3d` (`image`, `uv_rect`, `bicubic_sampling`) and missing full material/exposure integration for exact lightmap behavior. | Large |
| 10 | Solari Raytracing Feature Set | `bevy/examples/3d/solari.rs` | Missing Solari-specific runtime features: realtime raytracing mode, pathtracer mode, raytracing-mesh components, DLSS integration, and GPU diagnostics exposure. | Large |
| 11 | Pointer, Picking, and Viewport-UI Interaction | `bevy/examples/3d/contact_shadows.rs`, `bevy/examples/3d/clustered_decals.rs`, `bevy/examples/3d/light_probe_blending.rs`, `bevy/examples/3d/split_screen.rs`, `bevy/examples/3d/mesh_ray_cast.rs`, `bevy/examples/3d/mixed_lighting.rs` | Missing interaction APIs: Bevy widget-pointer event flow (`widgets.rs` style), full cursor icon parity (`CursorIcon::System`), `MeshRayCast` system param, `PointerInteraction/HitData` stream, and per-viewport `UiTargetCamera` UI input routing parity. | Medium |
| 12 | Light Cookie Projection Runtime | `bevy/examples/3d/light_textures.rs` | `@render3d` surfaces (`DirectionalLightTexture`, `SpotLightTexture`, `PointLightTexture`) exist, but runtime renderer does not apply Bevy-equivalent cookie projection/sampling. | Medium |
| 13 | Weighted OIT Resolve | `bevy/examples/3d/order_independent_transparency.rs` | Missing weighted order-independent-transparency accumulation and resolve pass in renderer. | Large |
| 14 | Occlusion Culling Readback and Metrics | `bevy/examples/3d/occlusion_culling.rs` | Missing render-world bridge for indirect-parameter staging/readback, preventing exact rendered-mesh count introspection. | Medium |
| 15 | Reflection-Probe Image Usage Mutation | `bevy/examples/3d/reflection_probes.rs` | Missing public image usage mutation in asset API (COPY_SRC-equivalent control) needed by runtime-generated environment-map workflow parity. | Quick |
| 16 | Mesh Tangent Generation API | `bevy/examples/3d/rotate_environment_map.rs` | Missing public tangent-generation API in mesh surface for normal-map parity on generated meshes. | Quick |
| 17 | Spherical Area-Light Radius Shading Semantics | `bevy/examples/3d/spherical_area_lights.rs` | `PointLight.radius` area-light shading semantics are not exposed as Bevy-equivalent runtime behavior; current ports approximate via intensity/range mapping. | Medium |
| 18 | Atmospheric Fog Inscattering Controls | `bevy/examples/3d/atmospheric_fog.rs` | `@render3d.DistanceFog` lacks Bevy fields and helpers: `directional_light_color`, `directional_light_exponent`, and `FogFalloff::from_visibility_colors` equivalent. | Medium |
| 19 | Motion-Blur Parity Validation Infrastructure | `bevy/examples/3d/motion_blur.rs` | `@render3d.MotionBlur` exists, but no cross-backend parity harness (screenshot/pixel-diff or equivalent) exists to sign off motion-vector/depth-prepass correctness. | Medium |
| 20 | Meshlet Experimental Pipeline | `bevy/examples/3d/meshlet.rs` | Missing meshlet feature family: `MeshletPlugin`, `MeshletMesh3d`, meshlet-processed asset pipeline, and debug material/visualization flow. | Large |
| 21 | Irradiance Debug Visualization and Animation Graph Parity | `bevy/examples/3d/irradiance_volumes.rs` | Missing Bevy-equivalent 3D gizmo rendering path and missing full animation-graph/player parity in this example path (fox animation control flow). | Medium |

## Partially Implemented Blockers (What Exists, What Remains)

- Deferred prepass components are present (`DepthPrepass`, `MotionVectorPrepass`, `DeferredPrepass`) and example toggles are wired, but full deferred renderer parity and shadow-map resource controls are still missing.
- Decal-adjacent camera prerequisites (`DepthPrepass`, `Msaa::Off`, `Fxaa`, free-camera behavior) are already wired in ports, but true forward/clustered decal projection passes are still absent.
- Contact-shadow receiver semantics use `NotShadowReceiver`, but widget-driven pointer interactions and full cursor-state parity are still missing.
- Volumetric-fog examples already use distance-fog/proxy approximations, but true `FogVolume`/`VolumetricFog`/`VolumetricLight` components and passes are still unavailable.
- Light-texture component surfaces are exposed, but renderer-side cookie projection is not implemented.
- Reflection-probe generated mode is wired, but image usage mutation (`COPY_SRC`-equivalent) is still unavailable.
- Motion-blur component/API is available, but exact parity is blocked by missing cross-backend validation tooling.
- OIT interaction wiring is present in example logic, but weighted OIT resolve remains missing in renderer.
- SSR controls exist in adapted form, but full deferred SSR + custom water material extension path remains unavailable.
