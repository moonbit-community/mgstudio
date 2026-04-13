This file must not exceed 200 lines.

| Bevy Side | mgstudio Side | Structure | Runtime | Overall | Status | Main Gaps |
|---|---|---:|---:|---:|---|---|
| `bevy_app` | `mgstudio-engine/app` | 96% | 85% | 85% | 🟡 In Progress | System scheduling and ergonomics still diverge in several APIs. |
| `bevy_ecs` (core surface) | `mgstudio-engine/ecs` | 88% | 80% | 80% | 🟡 In Progress | By-design architecture differences from Bevy remain and need documented boundaries. |
| `bevy_transform` | `mgstudio-engine/transform` | 95% | 86% | 86% | 🟡 In Progress | Stress-scene throughput and integration ordering still need parity validation. |
| `bevy_hierarchy` | `mgstudio-engine/hierarchy` | 96% | 90% | 90% | 🟡 In Progress | Large-scene edge cases still require screenshot-level parity confirmation. |
| `bevy_reflect` | N/A (explicit non-goal) | 0% | 0% | 0% | ⏸ Excluded | Reflection remains explicitly out of scope. |
| `bevy_tasks` | N/A (explicit non-goal) | 0% | 0% | 0% | ⏸ Excluded | Task runtime parity remains explicitly out of scope. |
| `bevy_render` (topology) | `mgstudio-engine/render` | 97% | 70% | 70% | 🟡 In Progress | Stage-boundary ownership is still not fully equivalent in runtime behavior. |
| `bevy_render::renderer` | `mgstudio-engine/render/renderer` | 96% | 68% | 68% | 🟡 In Progress | Draw/prepare responsibilities are still partially mixed in hot paths. |
| `bevy_core_pipeline` | `mgstudio-engine/core_pipeline` | 94% | 72% | 72% | 🟡 In Progress | Postprocess/mip/runtime ordering still needs stricter source-level convergence. |
| `bevy_pbr` (overall) | `mgstudio-engine/pbr` | 95% | 77% | 77% | 🟡 In Progress | Remaining parity gaps concentrate in light/fog/meshlet/deferred depth behavior. |
| `bevy_pbr::render` | `mgstudio-engine/pbr/render` | 96% | 80% | 80% | 🟡 In Progress | Core stage split is landed; remaining gaps are meshlet/advanced pass feature depth. |
| `bevy_pbr::prepass` | `mgstudio-engine/pbr/prepass` | 94% | 74% | 74% | 🟡 In Progress | Remaining pass ordering/bind-group lifecycle needs Bevy-level matching. |
| `bevy_pbr::meshlet` | `mgstudio-engine/pbr/meshlet` | 92% | 64% | 64% | 🟡 In Progress | Meshlet runtime is still partial and must follow Bevy ownership boundaries. |
| `bevy_material` | `mgstudio-engine/material` | 93% | 76% | 76% | 🟡 In Progress | Deferred/forward/decal behavior details still not fully converged. |
| `bevy_camera` | `mgstudio-engine/camera` + `pbr/render` | 92% | 76% | 76% | 🟡 In Progress | Camera/view/projection integration still has residual divergence points. |
| `bevy_sprite` | `mgstudio-engine/sprite` + `sprite_render` | 93% | 78% | 78% | 🟡 In Progress | Visual parity in stress-scale and edge picking cases needs more verification. |
| `bevy_ui` | `mgstudio-engine/ui` + `ui_render` + `ui_widgets` | 92% | 72% | 72% | 🟡 In Progress | Pointer-hit and layout/render consistency still require continuous parity checks. |
| `bevy_text` | `mgstudio-engine/text` | 90% | 66% | 66% | 🟡 In Progress | Text shaping/BiDi dependency gaps still block full behavior equivalence. |
| `bevy_gltf` | `mgstudio-engine/gltf` + `scene` | 93% | 70% | 70% | 🟡 In Progress | Loader/runtime edge cases and extension semantics are not fully closed yet. |
| `bevy_animation` | `mgstudio-engine/animation` | 93% | 68% | 68% | 🟡 In Progress | Typed event and runtime coupling still need deeper source-level alignment. |
| `bevy_scene` (static scene path) | `mgstudio-engine/scene` | 92% | 72% | 72% | 🟡 In Progress | Spawn/runtime integration has remaining parity-tail differences. |
| `bevy_scene` (`dynamic_scene*`) | N/A (explicit non-goal: dynamic) | 0% | 0% | 0% | ⏸ Excluded | Dynamic-scene path remains explicitly out of scope. |
| `bevy_gizmos` | `mgstudio-engine/gizmos` + `gizmos_render` | 90% | 74% | 74% | 🟡 In Progress | Gizmo rendering/runtime polish and behavior tails are still pending. |
| `bevy_picking` | `mgstudio-engine/picking` | 90% | 70% | 70% | 🟡 In Progress | Camera-space and UI interaction edge cases still need strict parity validation. |
| `bevy_input` | `mgstudio-engine/input` | 94% | 82% | 82% | 🟡 In Progress | Remaining platform/event-order corner cases still need alignment checks. |
| `bevy_window` + `bevy_winit` | `mgstudio-engine/window` + `winit` | 93% | 80% | 80% | 🟡 In Progress | Monitor-aware sizing and platform-semantics tails are still open. |
| `bevy_asset` | `mgstudio-engine/asset` | 90% | 68% | 68% | 🟡 In Progress | Asset tests/runtime still have unresolved environment/link/decode constraints. |
| `bevy_log` + diagnostics | `mgstudio-engine/log` + `diagnostic` + `dev_tools` | 91% | 76% | 76% | 🟡 In Progress | Trace/overlay pipeline is present but not fully equivalent to Bevy depth. |
| `bevy_anti_alias` | `mgstudio-engine/anti_alias` | 90% | 68% | 68% | 🟡 In Progress | Anti-alias stage integration still needs stricter parity verification. |
| `bevy_light` | `mgstudio-engine/light` | 92% | 72% | 72% | 🟡 In Progress | Light clustering/runtime integration still has parity-tail differences. |
| `bevy_mesh` | `mgstudio-engine/mesh` | 93% | 74% | 74% | 🟡 In Progress | Mesh extraction/upload behavior is not yet fully Bevy-equivalent. |
| `bevy_image` | `mgstudio-engine/image` | 88% | 62% | 62% | 🟡 In Progress | Codec/runtime behavior parity remains incomplete in constrained environments. |
| `bevy_color` | `mgstudio-engine/color` | 97% | 92% | 92% | ✅ Mostly Done | Only maintenance-level parity drift monitoring remains. |
| `bevy_math` | `mgstudio-engine/math` | 96% | 90% | 90% | ✅ Mostly Done | Only maintenance-level parity drift monitoring remains. |
| `bevy_a11y` | `mgstudio-engine/a11y` | 95% | 88% | 88% | 🟡 In Progress | Final semantic parity audit against Bevy accessibility behavior is pending. |
| `bevy_rapier` integration | `mgstudio-engine/physics2d` + `physics3d` | 92% | 64% | 64% | 🟡 In Progress | Full bevy_rapier example behavior parity is still not closed. |
| Stress test parity | `examples/stress_tests/*` + scripts | 95% | 62% | 62% | 🟡 In Progress | Many heavy cases still require source-first render/runtime convergence. |
| Visual screenshot parity | `/tmp` captures + parity gates | 96% | 70% | 70% | 🟡 In Progress | Representative coverage exists, but full-suite visual equivalence is incomplete. |
| Workspace-wide native validation | `moon check/test` integration | 90% | 58% | 58% | 🟡 In Progress | Full native test reliability is still blocked by remaining environment/runtime gaps. |

| Rollup | Value |
|---|---:|
| Bevy→mgstudio path parity (considered scope) | 100% (`1028/1028`, `missing=0`, 2026-04-13) |
| Migration completion scoring rule | `Overall = min(Structure, Runtime)` |
| Current weighted migration completion (included scope) | 75% |
| Last updated | 2026-04-13 |

- [x] `render/pbr`: close `RENDER-003` with current/previous skin matrices persistence and dual-slot upload for motion vectors.
- [x] `render/pbr`: close `RENDER-004` with incremental mesh extract/remove and cache cleanup flow aligned to stage boundaries.
- [x] `render/pbr`: close `RENDER-005` with per-mesh `motion_vector_enabled` data authored in extract/collect path and consumed by motion-vector pass.
- [x] `render/pbr`: close `RENDER-006` by moving camera preprocess payload uploads into `render3d_prepare_bind_groups_system`.
- [x] `render/pbr`: close `RENDER-007` by storing per-view prepared queue/projection/viewport state and consuming it at execute.
- [x] `render/pbr`: close `RENDER-008` by splitting camera queue build/upload/dispatch across prepare-bind-groups/queue stages.
- [x] `render/pbr`: close `RENDER-010` by removing execute-side queue-build/preprocess duties from camera hot path.
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
- [x] `render/pbr`: move render3d diagnostics state (runtime flag + queue/execute counters) from global `Ref` to world-owned resource.
- [x] `pbr/free_camera`: move controller system-state from global `Ref` to world-owned resource.
- [x] `render/renderer`: collapse duplicated frame-begin/frame-end diagnostics bookkeeping into `render_diagnostics_runtime` owner APIs (`render_diagnostics_begin_frame/end_frame`) and remove direct state mutation from `window_surface`.
- [x] `render/renderer`: collapse `window_surface` scattered binding globals (`surfaces/frames/id seeds`) into a single owner runtime state (`WindowSurfaceRuntimeState`), keeping behavior-local ownership.
- [x] `render/renderer`: move `mesh2d` gizmo-line mesh-id cache from global `Ref` to `GpuBackend` owner field (`mesh2d_gizmo_line_mesh_id`).
- [x] `render/renderer`: collapse screenshot capture/parity globals into one owner runtime state (`ScreenshotRuntimeState`) and remove multi-Ref scattered mutation.
- [x] `render/render_resource`: collapse 8 independent id-seed globals into single owner runtime state (`RenderResourceIdState`).
- [x] `render/renderer`: replace direct mesh2d/mesh3d diagnostic counter mutations with owner API calls from `render_diagnostics_runtime`.
- [x] `render/render_phase`: collapse render-pass trace active-span global into owner runtime state (`RenderPassTraceRuntimeState`).
- [x] `render/renderer`: wrap backend singleton in `RenderContextRuntimeState` and migrate renderer whitebox tests to explicit test-set/get hooks.
- [x] `gltf/scene`: remove `scene` package dependency on root `@gltf` forwarding layer by switching runtime/tests to owner `gltf/loader` package alias.
- [ ] `shell-packages`: keep Bevy path coverage without regressing into wrapper-only compatibility layers.
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
- [x] `dev_tools+render_diagnostic-shell-prune`: remove alias-only exports in `dev_tools/frame_time_graph/top` and `render/diagnostic/internal`, with `render/lib` typing synchronized to renderer owner type.
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
- [x] `scene/ecs_keys`: remove unused wrapper exports (`scene_spawn_roots_system_ecs`, `scene_plugin_ecs`) and switch tests to owner systems.
- [x] `state/state`: promote Bevy path files to compiled owner subpackage (`Milky2018/mgstudio/state/state`) instead of dead wrappers.
- [x] `state/state-foundation-ownerization`: replace alias forwarding in `state/state/{states,state_set,freely_mutable_state}` with local owner trait + helper implementations.
- [x] `window/cursor`: promote Bevy path files to compiled owner subpackage (`Milky2018/mgstudio/window/cursor`) with root compatibility exports.
- [x] `post_process/render_phase/pbr_transmission`: remove dead `*_runtime_available()` placeholder APIs and keep only behavior-bearing surfaces.
- [x] `pbr/transmission`: move `ScreenSpaceTransmission*` type + ECS key ownership from `post_process` to `pbr/transmission`.
- [x] `post_process`: remove compatibility re-exports for transmission (`ScreenSpaceTransmission*` + key) after call sites switched to `pbr`.
- [x] `pbr/atmosphere`: remove dead `atmosphere_runtime_available()` placeholder gate from plugin default path.
- [x] `pbr/meshlet`: remove dead per-file `*_runtime_available()` forwarding wrappers and keep a single package-level runtime gate.
- [x] `pbr/meshlet`: remove `HAS_MESHLET_RUNTIME=false` hard stub gate; switch to renderer capability-based runtime probe.
- [ ] `render/wgpu_mbt` (deferred, upstream): expose queryable/bridgeable Bevy meshlet-required texture atomic feature flags (`TEXTURE_INT64_ATOMIC`, `TEXTURE_ATOMIC`) for full meshlet capability parity (`SHADER_INT64`/`SUBGROUP`/`IMMEDIATES`已接入，tracked at `moonbit-community/wgpu-mbt#11`).
- [ ] `animation/gltf/scene`: audit and close remaining runtime ownership differences against Bevy source modules.
- [ ] `ui/sprite/picking`: run visual + interaction parity gate and fix any camera-space/pointer-space drift.
- [ ] `text`: track upstream shaping/BiDi blockers and keep behavior parity deltas explicit and minimized.
- [ ] `asset/image`: close runtime decode/link gaps and restore stable native testability.
- [ ] `physics2d/physics3d`: finish bevy_rapier example behavior parity and update parity evidence.
- [ ] `stress_tests`: use render-trace evidence to drive source-level convergence, not heuristic tuning.
- [x] `path-audit`: `scripts/check_bevy_rs_to_mbt_paths.sh` stays green (`missing=0`, `scaffold_files=0`) after non-scaffold path recovery.
