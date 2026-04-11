This file must not exceed 200 lines.

| Bevy Side | mgstudio Side | Status | Progress | Remaining Gaps / Notes | Next Action |
|---|---|---|---:|---|---|
| `bevy_app` | `mgstudio-engine/app` | ✅ Done | 95% | Core schedule/system-param path is stable; migration wrappers were removed. | Keep parity through incremental audits only. |
| `bevy_ecs` (core surface) | `mgstudio-engine/ecs` | 🟡 In Progress | 85% | `Changed<T>` and full change-detection boundary are still open. | Land `Changed<T>` and close change-detection scope doc. |
| `bevy_transform` | `mgstudio-engine/transform` | 🟡 In Progress | 88% | Functional parity mostly landed; stress hotspot remains in propagation cost. | Continue source-level parity + perf verification. |
| `bevy_hierarchy` | `mgstudio-engine/hierarchy` | ✅ Done | 92% | Mainline behavior is aligned for current examples. | Keep regression checks on large scene cases. |
| `bevy_reflect` | N/A (explicit non-goal) | ⏸ Excluded | 0% | Reflection is intentionally out of scope. | Do not implement unless scope changes. |
| `bevy_tasks` | N/A (explicit non-goal) | ⏸ Excluded | 0% | Async tasks parity is intentionally out of scope. | Keep excluded in mapping scripts. |
| `bevy_render` (topology) | `mgstudio-engine/render` | 🟡 In Progress | 91% | File topology is close; `renderer` owner splits continue to remove monolithic runtime files (`mesh3d_preprocess_types`, `mesh3d_preprocess_shader_load`, `mesh3d_preprocess_resources`, `mesh3d_preprocess_upload`, `mesh3d_preprocess_runtime`, `mesh3d_draw_pass_data`, `mesh3d_skin_binding`, `mesh3d_mesh_buffers`, `mesh3d_draw_runtime`). | Continue file-by-file owner convergence. |
| `bevy_render::renderer` internals | `mgstudio-engine/render/renderer` | 🟡 In Progress | 95% | Backend runtime API split progressed (`top` wrappers + `mesh3d` public runtime APIs), plus pipeline-cache, bind-group/material-cache, pipeline-build, preprocess shader/resource/upload/runtime owners, and draw-pass data owners split from monolithic `mesh3d_draw`; remaining work is narrower pass-execution decomposition. | Keep converging draw-pass execution ownership by Bevy responsibilities. |
| `bevy_core_pipeline` | `mgstudio-engine/core_pipeline` | 🟡 In Progress | 90% | Most node/plugin shapes landed; some runtime parity still shallow. | Finish remaining runtime-depth parity items. |
| `bevy_pbr` (overall) | `mgstudio-engine/pbr` | 🟡 In Progress | 80% | Forward decal/clustered decal/OIT/occlusion runtime not fully closed; render/prepass file-owner convergence is ongoing. | Complete pending pbr runtime tracks before tuning. |
| `bevy_pbr::render` | `mgstudio-engine/pbr/render` | 🟡 In Progress | 82% | Projection/frustum logic is mirrored, and frusta-update owner logic is now in `pbr/render/systems`; parent compatibility owner duplication remains. | Continue collapsing projection owner duplication under MoonBit constraints. |
| `bevy_pbr::prepass` | `mgstudio-engine/pbr/prepass` | 🟡 In Progress | 80% | File-owner shape now split into `prepass`/`prepass_bindings`/`prepass_utils`; core prepass plugin/view-state/node predicates are now re-exposed on pbr prepass surface. | Finish remaining prepass runtime behavior parity. |
| `bevy_pbr::meshlet` | `mgstudio-engine/pbr/meshlet` | 🟡 In Progress | 40% | Owner surfaces exist but runtime is still limited. | Decide final runtime scope and implement or defer formally. |
| `bevy_material` | `mgstudio-engine/material` | 🟡 In Progress | 76% | Deferred renderer method and forward-decal specialization need closure. | Complete deferred/forward-decal behavior parity. |
| `bevy_camera` (3D projection path) | `mgstudio-engine/pbr` + `pbr/render` + `camera` | 🟡 In Progress | 86% | Cross-package owner split is partially mirrored; compatibility layer still needed. | Continue owner convergence without breaking constructors/components. |
| `bevy_sprite` | `mgstudio-engine/sprite` + `sprite_render` | 🟡 In Progress | 83% | Some stress visual mismatches still tracked. | Keep screenshot-driven parity checks on sprite stress examples. |
| `bevy_ui` | `mgstudio-engine/ui` + `ui_render` + `ui_widgets` | 🟡 In Progress | 81% | Pointer picking traversal parity still has edge-case gaps. | Finish transform-aware picking and traversal parity. |
| `bevy_text` | `mgstudio-engine/text` | 🟡 In Progress | 74% | Text stress bottlenecks are still open. | Continue queue/prepare parity and glyph-path profiling. |
| `bevy_gltf` | `mgstudio-engine/gltf` + `scene` | 🟡 In Progress | 84% | Loader/event/runtime largely landed; visual parity still needs broader audits. | Continue full example-by-example visual verification. |
| `bevy_animation` | `mgstudio-engine/animation` | ✅ Mostly Done | 93% | Major API/runtime/event parity landed; remaining risk is cross-package behavior under stress scenes. | Keep as done-core; verify via gltf/stress integration passes. |
| `bevy_scene` | `mgstudio-engine/scene` | 🟡 In Progress | 80% | Basic flow is present; deeper parity depends on gltf/render closure. | Close remaining scene-runtime parity with gltf/render work. |
| `bevy_gizmos` | `mgstudio-engine/gizmos` + `gizmos_render` | 🟡 In Progress | 78% | Surface parity exists; runtime fidelity still not fully audited. | Complete representative visual/runtime audits. |
| `bevy_picking` | `mgstudio-engine/picking` | 🟡 In Progress | 75% | UI hit-test and traversal edge behavior not fully closed. | Finish Bevy-aligned backend traversal semantics. |
| `bevy_input` | `mgstudio-engine/input` + `window` | 🟡 In Progress | 87% | Major pointer mapping bugs fixed; keep regression pressure. | Add focused regression checks for pointer-space conversions. |
| `bevy_window`/`bevy_winit` | `mgstudio-engine/window` + `winit` | 🟡 In Progress | 88% | Runtime mostly stable; platform edge cases remain possible. | Continue parity checks while fixing remaining visual diffs. |
| `bevy_asset` | `mgstudio-engine/asset` | 🟡 In Progress | 82% | Asset path/provenance parity improved; some tests blocked by native link/runtime setup. | Keep asset layout aligned with Bevy and fix test environment blockers. |
| `bevy_log` + diagnostics | `mgstudio-engine/log` + `diagnostic` + `dev_tools` | ✅ Mostly Done | 95% | Diagnostics overlay, timeline trace plugin, stress diagnostics plugin, and stress trace collection script are in mainline and checked in package builds. | Keep maintenance-level parity checks only. |
| `bevy_anti_alias` | `mgstudio-engine/anti_alias` | 🟡 In Progress | 62% | SMAA/CAS/DLSS surfaces landed; full runtime graph parity still pending. | Implement runtime path parity for enabled features. |
| `bevy_light` | `mgstudio-engine/light` | 🟡 In Progress | 82% | Most light data paths are present; behavior parity tied to pbr/render closure. | Continue with pbr/render aligned runtime work. |
| `bevy_math` | `mgstudio-engine/math` | ✅ Mostly Done | 90% | Mainline math surface aligned for current runtime needs. | Keep maintenance mode with targeted parity diffs only. |
| `bevy_mesh` | `mgstudio-engine/mesh` | ✅ Mostly Done | 89% | Mesh core surface is stable; advanced render integration still evolves. | Track only render-coupled deltas. |
| `bevy_color` | `mgstudio-engine/color` | ✅ Mostly Done | 90% | Core color authoring/runtime surface is available. | Maintain with render/pbr changes. |
| `bevy_image` | `mgstudio-engine/image` | 🟡 In Progress | 73% | Runtime is usable; environment-specific native deps still affect tests. | Stabilize native dependency path and test behavior. |
| `bevy_a11y` | `mgstudio-engine/a11y` | ✅ Mostly Done | 91% | Mainline package cleaned and aligned at surface level. | Keep parity by following upstream API evolution. |
| `bevy_rapier` examples parity | `mgstudio-engine/physics2d` + `physics3d` + examples | 🟡 In Progress | 76% | API coverage is broad; screenshot-level visual parity is still incomplete. | Continue example-by-example visual correction. |
| `bevy_remote` | Removed from mainline | ✅ Done (scope choice) | 100% | Placeholder backend removed; no fake runtime left. | Reintroduce only with real transport/protocol backend. |
| `bevy_solari` | Removed from mainline | ✅ Done (scope choice) | 100% | Placeholder runtime removed from mainline. | Reintroduce only with executable implementation. |
| Stress tests parity gate | `examples/stress_tests/*` + scripts | 🟡 In Progress | 60% | FPS and visual consistency gaps remain in 3D/text-heavy cases. | Keep parity-first refactors, then validate with profiles/screenshots. |
| Visual screenshot audit | `/tmp` captures + parity docs | 🟡 In Progress | 68% | Large batch exists, but not all cases are fully converged. | Continue full-run capture and per-case fix loop. |
| Native test environment | workspace build/test toolchain | 🟡 In Progress | 55% | `zlib` link propagation is still a known blocker in some native tests. | Close native link propagation so full test matrix is reliable. |

| Rollup | Value |
|---|---:|
| Migration focus | Bevy-first source/structure parity (not heuristic tuning) |
| Done / Mostly done rows | 13 / 39 |
| In-progress rows | 23 / 39 |
| Excluded by scope rows | 2 / 39 |
| Last updated | 2026-04-11 |
