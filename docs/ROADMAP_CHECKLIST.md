This file must not exceed 200 lines.
| Bevy Side | mgstudio Side | Structure | Runtime | Overall | Status | Main Gaps |
|---|---|---:|---:|---:|---|---|
| `bevy_app` | `mgstudio-engine/app` | 96% | 91% | 91% | 🟡 In Progress | System scheduling and ergonomics still diverge in several APIs. |
| `bevy_ecs` (core surface) | `mgstudio-engine/ecs` | 88% | 80% | 80% | 🟡 In Progress | By-design architecture differences from Bevy remain and need documented boundaries. |
| `bevy_transform` | `mgstudio-engine/transform` | 95% | 86% | 86% | 🟡 In Progress | Stress-scene throughput and integration ordering still need parity validation. |
| `bevy_hierarchy` | `mgstudio-engine/hierarchy` | 96% | 90% | 90% | 🟡 In Progress | Large-scene edge cases still require screenshot-level parity confirmation. |
| `bevy_reflect` | N/A (explicit non-goal) | 0% | 0% | 0% | ⏸ Excluded | Reflection remains explicitly out of scope. |
| `bevy_tasks` | N/A (explicit non-goal) | 0% | 0% | 0% | ⏸ Excluded | Task runtime parity remains explicitly out of scope. |
| `bevy_render` (topology) | `mgstudio-engine/render` | 97% | 71% | 71% | 🟡 In Progress | Stage-boundary ownership is still not fully equivalent in runtime behavior. |
| `bevy_render::renderer` | `mgstudio-engine/render/renderer` | 96% | 69% | 69% | 🟡 In Progress | Draw/prepare responsibilities are still partially mixed in hot paths. |
| `bevy_core_pipeline` | `mgstudio-engine/core_pipeline` | 94% | 75% | 75% | 🟡 In Progress | Postprocess/mip/runtime ordering still needs stricter source-level convergence. |
| `bevy_pbr` (overall) | `mgstudio-engine/pbr` | 95% | 95% | 95% | 🟡 In Progress | Remaining parity gaps concentrate in meshlet/deferred/advanced-pass behavior depth. |
| `bevy_pbr::render` | `mgstudio-engine/pbr/render` | 96% | 96% | 96% | 🟡 In Progress | Core stage split is landed; remaining gaps are meshlet/advanced pass feature depth. |
| `bevy_pbr::prepass` | `mgstudio-engine/pbr/prepass` | 95% | 95% | 95% | ✅ Mostly Done | Remaining parity work is maintenance-level drift monitoring. |
| `bevy_pbr::meshlet` | `mgstudio-engine/pbr/meshlet` | 94% | 74% | 74% | 🟡 In Progress | Runtime state semantics + render/core3d stage ownership are aligned; shader/pipeline-specialization depth is still simplified vs Bevy. |
| `bevy_material` | `mgstudio-engine/material` | 93% | 77% | 77% | 🟡 In Progress | Deferred/forward/decal behavior details still not fully converged. |
| `bevy_camera` | `mgstudio-engine/camera` + `pbr/render` | 92% | 77% | 77% | 🟡 In Progress | Camera/view/projection integration still has residual divergence points. |
| `bevy_sprite` | `mgstudio-engine/sprite` + `sprite_render` | 93% | 79% | 79% | 🟡 In Progress | Visual parity in stress-scale and edge picking cases needs more verification. |
| `bevy_ui` | `mgstudio-engine/ui` + `ui_render` + `ui_widgets` | 92% | 82% | 82% | 🟡 In Progress | Core package tests are green; remaining work is screenshot-level parity for complex UI/pointer edge cases. |
| `bevy_text` | `mgstudio-engine/text` | 90% | 80% | 80% | 🟡 In Progress | Core package tests are green; remaining work is full visual/line-break parity across script families. |
| `bevy_gltf` | `mgstudio-engine/gltf` + `scene` | 93% | 80% | 80% | 🟡 In Progress | Loader/runtime edge cases and extension semantics are not fully closed yet. |
| `bevy_animation` | `mgstudio-engine/animation` | 94% | 74% | 74% | 🟡 In Progress | Typed event and runtime coupling still need deeper source-level alignment. |
| `bevy_scene` (static scene path) | `mgstudio-engine/scene` | 92% | 77% | 77% | 🟡 In Progress | Spawn/runtime integration has remaining parity-tail differences. |
| `bevy_scene` (`dynamic_scene*`) | N/A (explicit non-goal: dynamic) | 0% | 0% | 0% | ⏸ Excluded | Dynamic-scene path remains explicitly out of scope. |
| `bevy_gizmos` | `mgstudio-engine/gizmos` + `gizmos_render` | 90% | 74% | 74% | 🟡 In Progress | Gizmo rendering/runtime polish and behavior tails are still pending. |
| `bevy_picking` | `mgstudio-engine/picking` | 90% | 80% | 80% | 🟡 In Progress | Package tests are green; remaining work is broader screenshot/regression parity across mixed camera/UI scenes. |
| `bevy_input` | `mgstudio-engine/input` | 94% | 88% | 88% | 🟡 In Progress | Package tests are green; remaining platform/event-order corner cases still need alignment checks. |
| `bevy_window` + `bevy_winit` | `mgstudio-engine/window` + `winit` | 93% | 86% | 86% | 🟡 In Progress | Package tests are green; monitor-aware sizing and platform-semantics tails are still open. |
| `bevy_asset` | `mgstudio-engine/asset` | 95% | 95% | 95% | 🟡 In Progress | Native asset runtime is stable with capability-gated HTTP fetch; image extension routing now derives from `bevy_image`-shaped loader tables and image meta settings (including sampler compare/border/anisotropy) are wired; remaining gaps focus on broader codec parity depth. |
| `bevy_log` + diagnostics | `mgstudio-engine/log` + `diagnostic` + `dev_tools` | 91% | 76% | 76% | 🟡 In Progress | Trace/overlay pipeline is present but not fully equivalent to Bevy depth. |
| `bevy_anti_alias` | `mgstudio-engine/anti_alias` | 91% | 74% | 74% | 🟡 In Progress | Camera-only runtime semantics and node gating are aligned for FXAA/SMAA/TAA/CAS/DLSS; `FxaaSensitivity::get_str` API shape is aligned; render-stage depth still pending. |
| `bevy_light` | `mgstudio-engine/light` | 93% | 87% | 87% | 🟡 In Progress | Light clustering/runtime integration still has parity-tail differences. |
| `bevy_mesh` | `mgstudio-engine/mesh` | 93% | 74% | 74% | 🟡 In Progress | Mesh extraction/upload behavior is not yet fully Bevy-equivalent. |
| `bevy_image` | `mgstudio-engine/image` | 96% | 95% | 95% | ✅ Mostly Done | `ImageLoader` shape, extension routing, supported-format table, magic-byte guessing, and host decode/dimension coverage now include BMP, TGA(RLE), PNM(P1..P7, 8/16-bit), farbfeld, QOI, ICO(PNG+DIB32), GIF/WEBP/TIFF/JPEG/TGA dimensions; remaining work is broader long-tail codec behavior depth. |
| `bevy_color` | `mgstudio-engine/color` | 97% | 92% | 92% | ✅ Mostly Done | Only maintenance-level parity drift monitoring remains. |
| `bevy_math` | `mgstudio-engine/math` | 96% | 90% | 90% | ✅ Mostly Done | Only maintenance-level parity drift monitoring remains. |
| `bevy_a11y` | `mgstudio-engine/a11y` | 95% | 95% | 95% | ✅ Mostly Done | Only maintenance-level parity drift monitoring remains. |
| `bevy_rapier` integration | `mgstudio-engine/physics2d` + `physics3d` | 92% | 82% | 82% | 🟡 In Progress | Package tests are green and 2D/3D visual captures now exist; remaining work is full behavior-level parity closure vs `bevy_rapier`. |
| Stress test parity | `examples/stress_tests/*` + scripts | 95% | 70% | 70% | 🟡 In Progress | Full-suite profile baseline now runs end-to-end; remaining work is source-first convergence for low-FPS heavy cases. |
| Visual screenshot parity | `/tmp` captures + parity gates | 96% | 75% | 75% | 🟡 In Progress | Coverage expanded to heavy stress + physics3d cases; remaining work is full-suite visual equivalence closure. |
| Workspace-wide native validation | `moon check/test` integration | 90% | 66% | 66% | 🟡 In Progress | Package-level native reliability improved and stress diagnostics are stable; full-suite runtime parity is still open. |

| Rollup | Value |
|---|---:|
| Bevy→mgstudio path parity (considered scope) | 100% (`1028/1028`, `missing=0`, 2026-04-13) |
| Migration completion scoring rule | `Overall = min(Structure, Runtime)` |
| Current weighted migration completion (included scope) | 95% |
| Last updated | 2026-04-14 |

- [x] `render/pbr`: close `RENDER-003` with current/previous skin matrices persistence and dual-slot upload for motion vectors.
- [x] `render/pbr`: close `RENDER-004` with incremental mesh extract/remove and cache cleanup flow aligned to stage boundaries.
- [x] `render/pbr`: close `RENDER-005` with per-mesh `motion_vector_enabled` data authored in extract/collect path and consumed by motion-vector pass.
- [x] `render/pbr`: close `RENDER-006` by moving camera preprocess payload uploads into `render3d_prepare_bind_groups_system`.
- [x] `render/pbr`: close `RENDER-007` by storing per-view prepared queue/projection/viewport state and consuming it at execute.
- [x] `render/pbr`: close `RENDER-008` by splitting camera queue build/upload/dispatch across prepare-bind-groups/queue stages.
- [x] `render/pbr`: close `RENDER-010` by removing execute-side queue-build/preprocess duties from camera hot path, and correct clip-matrix axis wiring in `render3d_begin_pass_3d` (unjittered/previous x-axis fields).
- [x] `render/pbr`: close `RENDER-011` by confining depth-pyramid and late-occlusion preprocess dispatch to queue stage.
- [x] `render/pbr`: close `RENDER-012` by wiring concrete work to staged `prepare meshes -> prepare bind groups -> queue -> execute` topology.
- [x] `pbr/wireframe-ownerization`: move wireframe mesh-cache/runtime helpers from main-pass file into `pbr/wireframe.mbt` owner module.
- [x] `pbr/material-ownerization`: add `ExtractedMaterialInstances3d` world resource and populate it from `render3d_prepare_meshes_system`.
- [x] `pbr/render/mesh_view_bindings-depth`: add Bevy-shaped `MeshPipelineViewLayoutKey` + layout label + layout-entry generation.
- [x] `pbr/render/gpu_preprocess-depth`: add Bevy-shaped preprocess/bind-indirect pipeline key models and pipeline prepare-id flow.
- [x] `pbr/render/fog-prepare-shape`: align `pbr/render/fog` with Bevy `GpuFog`/mode constants/meta buffer/view offset/prepare encoding shape.
- [x] `pbr/fog-render-bridge`: add camera-owned `DistanceFog -> pbr/render Render3dViewFogData` bridge and world prepare helper.
- [x] `render/pbr`: replace point-light shadow sentinel entity path with `Option<Entity>` ownership flow.
- [x] `render/pbr`: move point-shadow target cache and scene postprocess target caches from global `Ref` to render-world resources.
- [x] `render/pbr`: move wireframe mesh cache from global `Ref` to render-world resource ownership.
- [x] `render/pbr`: move world-transform cache from global shared `Ref` to render-world resource ownership.
- [x] `pbr/plugin`: remove global plugin runtime-config `Ref`; resolve runtime config from ECS resource/default per world.
- [x] `render/pbr` + `diagnostic/timeline_trace`: move render3d diagnostics state to world-owned resource and move timeline pending-span buffer ownership from diagnostic global `Ref` to app timeline owner queue.
- [x] `pbr/free_camera`: move controller system-state from global `Ref` to world-owned resource.
- [x] `render/renderer`: collapse duplicated frame-begin/frame-end diagnostics bookkeeping into `render_diagnostics_runtime` owner APIs (`render_diagnostics_begin_frame/end_frame`), remove direct state mutation from `window_surface`, and merge pass-timing + draw/drop/debug/frame/snapshot refs into one owner runtime state.
- [x] `pbr/prepass`: replace queue-state camera/mesh motion-blur history caches with ECS-owned previous-frame components (`PreviousViewData`, `PreviousGlobalTransform`), move write-back into `PreUpdate` sync system, split sync flow to Bevy-shaped `update_mesh_previous_global_transforms` + `update_previous_view_data`, gate previous-data sync by standard-material prepass enablement, align camera collection/order to `camera.is_active`, and use projection `Changed` signals instead of force-updating runtime projection every frame.
- [x] `pbr/prepass`: add wb coverage for `PreUpdate` previous-data sync (camera previous-view + mesh previous-global + active-camera gating) and keep `moon test pbr` green.
- [x] `render/renderer`: collapse `window_surface` scattered binding globals (`surfaces/frames/id seeds`) into a single owner runtime state (`WindowSurfaceRuntimeState`), keeping behavior-local ownership.
- [x] `render/renderer`: move `mesh2d` gizmo-line mesh-id cache from global `Ref` to `GpuBackend` owner field (`mesh2d_gizmo_line_mesh_id`).
- [x] `render/renderer`: collapse screenshot capture/parity globals into one owner runtime state (`ScreenshotRuntimeState`) and remove multi-Ref scattered mutation.
- [x] `render/render_resource`: collapse 8 independent id-seed globals into single owner runtime state (`RenderResourceIdState`).
- [x] `render/renderer`: replace direct mesh2d/mesh3d diagnostic counter mutations with owner API calls from `render_diagnostics_runtime`.
- [x] `render/render_phase`: collapse render-pass trace active-span global into owner runtime state (`RenderPassTraceRuntimeState`).
- [x] `render/renderer`: wrap backend singleton in `RenderContextRuntimeState` and migrate renderer whitebox tests to explicit test-set/get hooks.
- [x] `gltf/scene`: remove `scene` package dependency on root `@gltf` forwarding layer by switching runtime/tests to owner `gltf/loader` package alias.
- [x] `picking/mesh_picking/ray_cast`: replace wrapper forwarding with owner intersection implementation and switch `picking/backend` to this path.
- [x] `camera`: switch camera mesh ray-cast API surface to `picking/mesh_picking/ray_cast` owner types/functions instead of `pbr` wrappers.
- [x] `examples`: switch in-tree mesh ray-cast usage (`3d/mesh_ray_cast`, `ui/render_ui_to_texture`) from `@pbr` shim calls to `picking/mesh_picking/ray_cast` owner path.
- [x] `examples/camera-projection-queries`: switch remaining example camera ray/view helpers from `@pbr.render3d_camera_*` to `@camera.camera_*` owner surface.
- [x] `gltf-owner-callsites`: switch in-repo consumers (`pbr/scene/gltf examples`) from `@gltf` forwarding helpers to direct `@gltf_loader` owner APIs.
- [x] `gltf-extensions-callsites`: switch scene runtime and extension examples from `@gltf.gltf_extension_*` forwarding helpers to `@gltf_loader_extensions` owner APIs.
- [x] `scene/dead-wrapper-prune`: remove unreferenced compatibility wrappers (`scene_spawner_run_*`, `scene_spawner_plugin*`, `scene_loader_plugin`, `scene_*_to_json`) to keep scene surface behavior-only.
- [x] `pbr/deferred-ownerization`: move deferred lighting plugin/state/depth-id ownership into `pbr/deferred/top` and reduce root `pbr/deferred.mbt` to compatibility forwarding.
- [x] `pbr/deferred-depth-id-runtime`: add PostUpdate auto-insert system for `DeferredPrepass -> PbrDeferredLightingDepthId` defaulting without overwriting explicit values.
- [x] `pbr/diagnostic-material-allocator-shape`: add Bevy-shaped material allocator diagnostic paths and slab/size/allocation snapshot helpers.
- [x] `pbr/fog-koschmieder-api`: expose Bevy-shaped `FogFalloff::koschmieder` helper and contrast-threshold constant on fog surface.
- [x] `pbr/render-fog-world-path`: wire fog prepare output into render-world (`FogMeta` resource + per-view `ViewFogUniformOffset` component) during prepare-bind-groups.
- [x] `pbr/render-light-extraction-formulas`: align light extraction with Bevy formulas for point/spot lumens->intensity, shadow-normal-bias scaling, and directional `dir_to_light=back()`.
- [x] `pbr/render-light-view-visibility`: align extraction with Bevy visibility semantics by skipping lights marked `ViewVisibility(false)`.
- [x] `pbr/light-affects-lightmap-flags`: add missing spot/directional `affects_lightmapped_mesh_diffuse` authoring fields and propagate them through render extraction.
- [x] `pbr/render-spot-flag-direction`: align `SPOT_LIGHT_Y_NEGATIVE` flag logic with Bevy by deriving from spotlight direction sign, not outer-angle value.
- [x] `pbr/render-directional-cascade-overlap`: align directional GPU light payload to use extracted cascade overlap proportion instead of constant fallback.
- [x] `pbr/render-directional-zero-shadow-cascades`: align directional GPU payload with Bevy behavior by keeping cascade count/array empty when directional shadows are disabled.
- [x] `light/authoring-shadow-toggle-api`: add missing `with_shadow_maps_enabled` authoring helpers for directional/spot lights to match Bevy-side usage ergonomics.
- [x] `pbr/render-ambient-lightmap-flag`: add Bevy-shaped ambient lightmap influence field (`affects_lightmapped_meshes`) and propagate it into `GpuLights3d`.
- [x] `pbr/render-sun-disk-propagation`: add `SunDisk` component in `light` and propagate directional sun-disk angular-size/intensity through extract and GPU light payload.
- [x] `light/directional-shadow-map-validate`: add Bevy-shaped directional shadow-map size validation path (`non-power-of-two -> next power-of-two`) on world resource.
- [x] `pbr/render-directional-color-premultiply`: align directional GPU-light payload with Bevy by writing `color * illuminance` into the GPU color field.
- [x] `pbr/render-directional-default-cascades`: align directional extraction with Bevy by using default `CascadeShadowConfig` when no explicit cascade config component is present.
- [x] `pbr/light-shadowmap-resource-init+validate`: initialize directional shadow-map resource in mesh-render startup and run Bevy-shaped non-power-of-two correction system on post-update.
- [x] `pbr/render-volumetric-flag-gating`: align point/directional light flags with Bevy by requiring `shadow_maps_enabled` before setting the `VOLUMETRIC` GPU flag.
- [x] `pbr/light-sun-disk-public-surface`: export `SunDisk` through pbr-facing aliases and ECS key list so authoring surface matches Bevy light API shape.
- [x] `pbr/render-directional-sort-key`: align directional-light ordering with Bevy key strategy (`volumetric`, `shadow_maps_enabled`, `entity`) to keep over-limit light selection deterministic.
- [x] `pbr/render-directional-depth-base-index`: add Bevy-shaped directional shadow array indexing fields (`depth_texture_base_index`, `decal_index`) and cumulative-base calculation in GPU light payload.
- [x] `pbr/render-point-spot-sort-keys`: align point/spot extracted-light ordering with Bevy-style shadow/volumetric/entity priority for deterministic over-limit light selection.
- [x] `pbr/render-spot-shadowmap-offset`: add Bevy-shaped `spot_light_shadowmap_offset` field on GPU lights and compute it from directional cascade count and point-light count.
- [x] `pbr/render-clusterable-point-light-ordering`: add Bevy-shaped point+spot combined ordering path (`point first`, then shadow/volumetric/entity key) and source `spot_light_shadowmap_offset` point-count from this combined stream.
- [x] `pbr/render-gpu-lights-cluster-shape`: add Bevy-shaped `GpuLights` cluster payload fields (`cluster_dimensions`, `cluster_factors`) with deterministic defaults in current single-view path.
- [x] `pbr/render-cluster-factor-formula`: align `cluster_factors.zw` computation with Bevy `calculate_cluster_factors`, derive dimensions from `ClusterConfig` + screen-size rounding via `light/cluster`, and zero-out cluster payload for `ClusterConfig::None`.
- [x] `light/cluster-camera-owned-runtime`: make `cluster_assign_lights_system` write `Clusters/VisibleClusterableObjects` per camera entity with Bevy-shaped `ClusterConfig` dimensions/far-z + visible entity-list semantics.
- [x] `pbr/render-cluster-runtime-source`: make `render3d_collect_gpu_lights` prefer camera-owned `light/cluster.Clusters` runtime data (`dimensions/near/far`) before config fallback, and prefer `VisibleClusterableObjects` entity lists for point/spot extraction.
- [x] `pbr/render-directional-decal-index`: source directional GPU `decal_index` from `RenderClusteredDecals` resource mapping (fallback `-1`) instead of hardcoded sentinel.
- [x] `pbr/render-directional-fixed-array-shape`: align `GpuLights` directional payload shape with Bevy by padding to `MAX_DIRECTIONAL_LIGHTS` and using `n_directional_lights` as logical count.
- [x] `pbr/render-gpu-ambient-premultiply`: align `GpuLights.ambient_color` with Bevy by writing pre-multiplied ambient color (`color * brightness`) instead of split GPU fields.
- [x] `pbr/render-directional-cascade-fixed-array-shape`: align directional cascade payload shape with Bevy by padding to `MAX_CASCADES_PER_LIGHT` and separating logical cascade count from storage length.
- [x] `a11y/resource-shared-flag-semantics`: add clone/shared-handle semantics tests for `AccessibilityRequested`, mutation coverage for `ManageAccessibilityUpdates`, `init_resource` keep-existing semantics parity, `ActionRequest` passthrough, and `node_id`/`AccessibilityNode` mutator coverage.
- [x] `pbr/render-uninitialized-slot-flags`: align padded directional GPU slot defaults with Bevy flag semantics by using `DIRECTIONAL_LIGHT_FLAG_UNINITIALIZED`.
- [x] `ui_widgets/dead-wrapper-prune`: remove unreferenced identity/entry compatibility wrappers to keep `ui_widgets` surface behavior-bearing.
- [x] `gltf/root-pure-functions`: make `gltf/assets` + `gltf/material` + `gltf/convert_coordinates` real implementations (direct `gltf_ext` / local logic), not loader pass-through.
- [x] `sprite_render/mesh2d-dead-wrapper-prune`: remove unreferenced plugin forwarding wrappers from `mesh2d/top` and `mesh2d/wireframe2d`.
- [x] `ui/widget-dead-wrapper-prune`: remove unreferenced interaction/plugin forwarding wrappers from `ui/widget/top`.
- [x] `material/dead-wrapper-prune`: remove unreferenced identity wrappers in `material/key` and `material/descriptor`.
- [x] `math/rects-dead-wrapper-prune`: remove unreferenced identity wrappers in `math/rects/{rect,irect,urect}`.
- [x] `window/cursor-dead-wrapper-prune`: remove unreferenced `system_cursor_icon_identity` forwarding helper.
- [x] `window/cursor-system_cursor-owner`: replace `system_cursor` alias shell with Bevy-shaped `SystemCursorIcon` enum + native conversion mapping.
- [x] `window/cursor-root-ownerization`: replace `window/cursor.mbt` root aliases with package-owned cursor enums/structs/keys and native conversion helpers.
- [x] `gizmos/dead-wrapper-prune`: remove unreferenced `*_identity` forwarders in `aabb/arcs/arrows/circles/curves/frustum/grid/primitives/dim2/rounded_box`.
- [x] `math/dead-wrapper-prune`: remove unreferenced identity forwarders in `math/curve/easing` and `math/sampling/mesh_sampling`.
- [x] `math/rects-ownerization`: replace `math/rects/{rect,irect,urect,top}` alias forwarding with owner structs/methods/constructors inside `math/rects` package.
- [x] `math/sampling-ownerization`: replace `math/sampling/{top,mesh_sampling,standard,shape_sampling}` alias forwarding with owner sampling types/traits/runtime logic.
- [x] `math/curve-adaptors-ownerization`: replace `math/curve/{adaptors,iterable}` alias forwarding with owner runtime curve adaptor/iterable implementations.
- [x] `math/curve-derivatives-ownerization`: replace `math/curve/derivatives/adaptor_impls` alias re-export with owner derivative carrier structs/constructors.
- [x] `math/curve-cores-ownerization`: replace `math/curve/{cores,sample_curves}` alias forwarding with owner core interpolation/sample-curve implementations.
- [x] `math/curve-top+interval+easing-ownerization`: replace `math/curve/{top,interval,easing}` direct `@math` alias shells with owner types/runtime and local curve-domain wiring.
- [x] `math/cubic_splines-curve_impls-ownerization`: replace `math/cubic_splines/curve_impls` derivative wrappers with owner derivative payload/runtime sampling logic.
- [x] `math/cubic_splines-top-ownerization`: replace `math/cubic_splines/top` direct type aliases with owner wrapper structs and explicit spline conversion/runtime APIs.
- [x] `camera/winit/utils-shell-prune`: remove alias-only shells in `camera/visibility/*`, `winit/cursor/*`, and `utils/{debug_info,utils}` by switching to behavior-bearing helper surfaces.
- [x] `state+render-shell-prune`: remove alias-only exports in `state/state/{resources,transitions}` and `render/error_handler` with direct runtime helper APIs.
- [x] `camera+dof-shell-prune`: remove alias-only exports in `camera/clear_color` and `post_process/dof/top`, keep direct behavior helpers over owner runtime types.
- [x] `render/view-shell-prune`: remove alias-only exports in `render/view/top` and `render/view/window/screenshot` and align capture result typing in `render/gpu_readback`.
- [x] `render_phase/draw_state-shell-prune`: remove alias-only `DrawState` export in `render/render_phase/draw_state` and use renderer owner state type directly in behavior APIs.
- [x] `transform/components-shape`: replace dead forwarding fns in `transform/components/{transform,global_transform}` with Bevy-path type ownership aliases.
- [x] `transform/components-ownerization`: replace `transform/components/{transform,global_transform,top}` alias forwarding with owner `Transform/Affine2/GlobalTransform` runtime definitions.
- [x] `utils/dead-wrapper-prune`: remove unused `utils_*_available` placeholders and replace map identity shim with concrete `map_new/map_from_entries`.
- [x] `utils/runtime-ownerization`: replace placeholder `bloom_filter` / `buffered_channel` / `parallel_queue` stubs with concrete MoonBit runtime implementations.
- [x] `utils/once+atomic_id-ownerization`: replace bevy-utils placeholder wording with concrete `OnceFlag/OnceCell` and monotonic atomic-id runtime behavior.
- [x] `feathers/no-op-plugin-prune`: replace `feathers` controls/cursor/alpha_pattern `app -> app` stubs with real install path (`controls` chain + resource init + plugin markers).
- [x] `examples/camera-shell-prune`: remove top-level stub files (`2d_on_ui.mbt`, `2d_screen_shake.mbt`, `2d_top_down_camera.mbt`) and keep only owner `*/main.mbt` entries.
- [x] `ui_widgets/empty-file-prune`: delete unused empty `ui_widgets/ui_widgets.mbt`.
- [x] `asset/io-dead-wrapper-prune`: remove unreferenced `asset_io_{android,wasm,web}_supported` stubs and keep source-name owner APIs.
- [x] `asset/io-platform-exclude-prune`: delete unused `asset/io/{android,wasm,web}.mbt` shell files and exclude corresponding Bevy platform sources from parity scope.
- [x] `dev_tools/dead-wrapper-prune`: remove unreferenced `*_available` stubs in `ci_testing`, `easy_screenshot`, `picking_debug`, `render_debug`, `states`.
- [x] `dev_tools/ci_testing-runtime`: replace `dev_tools/ci_testing` shell package with Bevy-shaped config/events/runtime plugin (screenshot/app-exit/custom-event/camera-move flow).
- [x] `text/error+font_loader-shape`: replace boolean availability stubs with concrete `TextError` / `FontLoader` / `FontLoaderError` owner types.
- [x] `math/curve-dead-wrapper-prune`: remove unreferenced `curve_identity` and `easing_curve_identity`.
- [x] `gizmos/cross+stroke_text-shape`: replace `*_supported` placeholders with concrete cross/text helper APIs in owner files.
- [x] `gizmos/simplex+skinned+retained-shape`: replace bool stubs with concrete constants/types for simplex font, skinned-bounds config, retained gizmo data.
- [x] `gizmos/aabb+frustum-ownerization`: replace alias-only `gizmos/{aabb,frustum}` with Bevy-shaped config/component/system/plugin runtime implementations.
- [x] `gizmos/arcs+arrows+circles+curves+grid+rounded_box+config-ownerization`: replace alias-only gizmo utility files with behavior APIs (draw/config helpers) over owner runtime.
- [x] `gizmos/plugin-entry-ownerization`: replace delegated `gizmos/lib` and `gizmos_render/lib` shells with real plugin structs (`PluginReplacement` + marker gating + explicit subplugin composition).
- [x] `gizmos/skinned-mesh-bounds-entry-ownerization`: make `skinned_mesh_bounds` behavior-bearing (`GizmoConfigGroup` + `Component` + plugin install path) instead of struct-only placeholder.
- [x] `math/primitives/top-ownerization`: keep Bevy-shaped type aggregation while adding behavior-bearing primitive helper surface in `math/primitives/top`.
- [x] `camera_controller/ownerization`: move `free_camera` + `pan_camera` from pure forwarding into package-owned runtime components/systems/plugins.
- [x] `module-tag-cleanup`: remove leftover `*_MODULE_ID`/`*_module_id` marker-only APIs from `math/curve/derivatives`, `ui/layout`, `gizmos/primitives`, and `camera/visibility`.
- [x] `app/hotpatch-ownerization`: replace `app/hotpatch` runtime forwarding shell with package-owned hotpatch plugin/message/resource surface.
- [x] `app/terminal-ctrlc-ownerization`: replace `app/terminal_ctrl_c_handler` helper shell with Bevy-shaped plugin + graceful-exit/exit-on-flag flow.
- [x] `asset/io/file-sync-ownerization`: replace `sync_file_asset` host-forwarding shell with local file write path (parent-dir ensure + bytes flush).
- [x] `gilrs/system-ownerization`: replace `gilrs_event_{startup,event}` pure forwarding with package-owned runtime polling state and counters.
- [x] `gltf/loader`: promote `Milky2018/mgstudio/gltf/loader` to compiled subpackage (`moon.pkg`) so Bevy-path files are no longer dead.
- [x] `gltf/loader`: move plugin/config/vertex-attribute/convert-coordinates ownership from root `gltf/*` into `gltf/loader/top.mbt`; root now compatibility forwarders.
- [x] `gltf/assets+material`: route asset-label/material helper ownership through `gltf/loader` to remove duplicate root implementations.
- [x] `path-subpackages`: promote `ui/widget` `winit/cursor` `dev_tools/frame_time_graph` `picking/mesh_picking/ray_cast` `sprite_render/*` path dirs to compiled packages.
- [x] `winit/cursor`: move cursor-options apply system ownership into subpackage and wire plugin call path through it.
- [x] `scene/components+scene_spawner`: move `SceneRoot/SceneInstance*` and plugin/spawner systems out of `scene/lib.mbt` into Bevy-shaped owner files.
- [x] `scene/scene_loader+serde`: move glTF ready-check loader wiring and scene serde impl ownership out of aggregating files.
- [x] `state/state`: promote Bevy path files to compiled owner subpackage (`Milky2018/mgstudio/state/state`) instead of dead wrappers.
- [x] `state/state-foundation-ownerization`: replace alias forwarding in `state/state/{states,state_set,freely_mutable_state}` with local owner trait + helper implementations.
- [x] `window/cursor`: promote Bevy path files to compiled owner subpackage (`Milky2018/mgstudio/window/cursor`) with root compatibility exports.
- [x] `post_process/render_phase/pbr_transmission`: remove dead `*_runtime_available()` placeholder APIs and keep only behavior-bearing surfaces.
- [x] `pbr/transmission`: move `ScreenSpaceTransmission*` type + ECS key ownership from `post_process` to `pbr/transmission`.
- [x] `post_process`: remove compatibility re-exports for transmission (`ScreenSpaceTransmission*` + key) after call sites switched to `pbr`.
- [x] `pbr/atmosphere`: remove dead `atmosphere_runtime_available()` placeholder gate from plugin default path.
- [x] `pbr/meshlet`: remove `HAS_MESHLET_RUNTIME=false` hard stub gate; switch to renderer capability-based runtime probe with Bevy-shaped required-feature mask + cluster-slot bound validation, and align runtime state transitions (`Enabled/Disabled/RuntimeUnavailable`) with deterministic tests.
- [x] `pbr/meshlet`: align render-sub-app scheduling to Bevy-shaped stage ownership (`extract/prepare_resources_flush/prepare_meshes/prepare_resources/prepare_bind_groups/queue`), add `configure_meshlet_views` (`Msaa::Off` + prepass/deferred markers), wire meshlet pass entry systems into `core_3d` prepass/main-pass sets, and hook `prepare_material_meshlet_meshes_{main_opaque_pass,prepass}` into per-view material bin preparation.
- [ ] `render/wgpu_mbt` (deferred, upstream): meshlet texture-atomic rust-feature gating is wired; remaining gap is mesh-shader feature constant/capability surface in `wgpu_mbt` for Bevy-equivalent meshlet capability reporting (tracked at `moonbit-community/wgpu-mbt#11`).
- [x] `animation/gltf/scene`: ownerization convergence continued (done: scene LOD registration moved to plugin install path, animation/gltf runtime bootstrap data now clears after runtime resource initialization, runtime-time callback/dispatcher registration is resource-first, and animation now exposes typed `AnimationPlugin`/`animation_plugin_with` plugin surface).
- [x] `ui/sprite/picking`: close camera/pointer drift baseline (done: window->sprite Y-axis/viewport-origin/rotation/scale wb tests + ui viewport pointer-boundary wb tests + `moon test picking` green).
- [ ] `text`: keep behavior parity deltas explicit and minimized (archived: `moon_cosmic` bidi linearization starvation no longer reproducible on `0.3.0`; remaining work is visual/script-coverage parity, not startup blocker).
- [x] `asset/image`: close mainline runtime decode/dimension gaps (done: embedded source-path fallback + capability-gated web fetch + native `moon test asset` green + settings/format-selection/array-layout + extension routing from loader tables + BMP/TGA(RLE)/PNM(P1..P7, 8/16-bit)/farbfeld/QOI/ICO(PNG+DIB32) decode + GIF/WEBP/TIFF/JPEG/TGA/PNM dimensions with wb coverage); remaining codec long-tail is tracked under module-level parity depth.
- [ ] `physics2d/physics3d`: finish bevy_rapier behavior parity closure (evidence updated: `physics2d` + `physics3d` screenshots and sanity reports in `/tmp/mgstudio_physics*_visual_20260414`).
- [ ] `stress_tests`: keep source-level convergence tracker from full-suite baseline (`/tmp/mgstudio_stress_full_20260414/results.tsv`) and per-case traces (e.g. `/tmp/mgstudio_trace_many_foxes_20260414`).
- [x] `render/mesh2d-depth-pipeline-key`: fix render crash by adding `with_depth` to mesh2d pipeline key/cache and only enabling depth-stencil state when pass has depth (prevents depth/no-depth pass pipeline mismatch in physics2d examples).
