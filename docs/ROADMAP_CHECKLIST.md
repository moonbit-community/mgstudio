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
| `bevy_pbr` (overall) | `mgstudio-engine/pbr` | 95% | 66% | 66% | 🟡 In Progress | PBR module shape is close, but runtime parity is still significantly incomplete. |
| `bevy_pbr::render` | `mgstudio-engine/pbr/render` | 96% | 60% | 60% | 🟡 In Progress | `RENDER-003..012` are still open and block true behavior parity. |
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
| Bevy→mgstudio path parity (considered scope) | 100% (`1031/1031`, `missing=0`, 2026-04-12) |
| Migration completion scoring rule | `Overall = min(Structure, Runtime)` |
| Current weighted migration completion (included scope) | 73% |
| Last updated | 2026-04-12 |

- [ ] `render/pbr`: close `RENDER-003` by introducing Bevy-shaped global skin uniform allocator and previous-frame buffers.
- [ ] `render/pbr`: close `RENDER-004` with incremental mesh extract/remove flow matching Bevy boundaries.
- [ ] `render/pbr`: close `RENDER-005` by adding dedicated motion-vector flag stage after skin/morph extraction.
- [ ] `render/pbr`: close `RENDER-006` by moving remaining bind-group creation fully into prepare-bind-groups stage.
- [ ] `render/pbr`: close `RENDER-007` by aligning per-view bind-group ownership and preparation ordering.
- [ ] `render/pbr`: close `RENDER-008` by matching GPU preprocess flush/prepare lifecycle to Bevy stage split.
- [ ] `render/pbr`: close `RENDER-010` by removing non-queue responsibilities from queue/execute hot path.
- [ ] `render/pbr`: close `RENDER-011` by aligning occlusion/depth-pyramid preprocess boundaries.
- [ ] `render/pbr`: close `RENDER-012` by wiring concrete work to new Prepare* set topology.
- [x] `gltf/scene/state/window`: remove pure compatibility alias shells and merge required exports into owner modules.
- [x] `shell-packages`: drop dead wrapper-only subpackages (`ui/widget`, `window/cursor`, `state/state`, `picking/mesh_picking/ray_cast`, `gltf/loader`, `dev_tools/frame_time_graph`).
- [x] `post_process/render_phase/pbr_transmission`: remove dead `*_runtime_available()` placeholder APIs and keep only behavior-bearing surfaces.
- [x] `pbr/transmission`: move `ScreenSpaceTransmission*` type + ECS key ownership from `post_process` to `pbr/transmission`.
- [x] `post_process`: remove compatibility re-exports for transmission (`ScreenSpaceTransmission*` + key) after call sites switched to `pbr`.
- [x] `pbr/atmosphere`: remove dead `atmosphere_runtime_available()` placeholder gate from plugin default path.
- [ ] `pbr/meshlet`: remove `HAS_MESHLET_RUNTIME=false` style hard stub gating by landing real runtime path or explicit scope exclusion.
- [ ] `render/wgpu_mbt`: expose Bevy meshlet-required feature flags (`TEXTURE_INT64_ATOMIC`, `TEXTURE_ATOMIC`, `SHADER_INT64`, `SUBGROUP`, `IMMEDIATES`) for runtime capability checks.
- [ ] `animation/gltf/scene`: audit and close remaining runtime ownership differences against Bevy source modules.
- [ ] `ui/sprite/picking`: run visual + interaction parity gate and fix any camera-space/pointer-space drift.
- [ ] `text`: track upstream shaping/BiDi blockers and keep behavior parity deltas explicit and minimized.
- [ ] `asset/image`: close runtime decode/link gaps and restore stable native testability.
- [ ] `physics2d/physics3d`: finish bevy_rapier example behavior parity and update parity evidence.
- [ ] `stress_tests`: use render-trace evidence to drive source-level convergence, not heuristic tuning.
