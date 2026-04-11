This file must not exceed 200 lines.

| Bevy Side | mgstudio Side | Status | Progress | Remaining Gaps / Notes | Next Action |
|---|---|---|---:|---|---|
| `bevy_app` | `mgstudio-engine/app` | ✅ Done | 95% | Core schedule/system-param path is stable; migration wrappers were removed. | Keep parity through incremental audits only. |
| `bevy_ecs` (core surface) | `mgstudio-engine/ecs` | ✅ Mostly Done | 95% | `Changed<T>` query filter + system param path are in mainline and `moon test ecs --target native` is green. | Keep maintenance-level parity checks and avoid reopening legacy surfaces. |
| `bevy_transform` | `mgstudio-engine/transform` | ✅ Mostly Done | 95% | Transform propagation/runtime path is stable and `moon test transform --target native` is green. | Keep maintenance-level parity checks with stress-scene regression tracking. |
| `bevy_hierarchy` | `mgstudio-engine/hierarchy` | ✅ Done | 95% | Mainline behavior is aligned and hierarchy package tests are green (`moon test hierarchy --target native`). | Keep regression checks on large scene cases. |
| `bevy_reflect` | N/A (explicit non-goal) | ⏸ Excluded | 0% | Reflection is intentionally out of scope. | Do not implement unless scope changes. |
| `bevy_tasks` | N/A (explicit non-goal) | ⏸ Excluded | 0% | Async tasks parity is intentionally out of scope. | Keep excluded in mapping scripts. |
| `bevy_render` (topology) | `mgstudio-engine/render` | ✅ Mostly Done | 95% | File topology is now highly converged; draw and preprocess offset owners are split out (`mesh3d_draw_storage_binding`, `mesh3d_draw_motion_vector_pass`, `mesh3d_draw_main_pass`, `mesh3d_preprocess_indirect_offsets`) and checks stay green. | Keep maintenance-level owner convergence only. |
| `bevy_render::renderer` internals | `mgstudio-engine/render/renderer` | ✅ Mostly Done | 97% | Motion-vector/main-pass/storage-binding owners are now split (`mesh3d_draw_motion_vector_pass`, `mesh3d_draw_main_pass`, `mesh3d_draw_storage_binding`) and render/full checks remain green (`moon check render`, `moon check --target native`). | Keep converging remaining draw-entry orchestration ownership by Bevy responsibilities. |
| `bevy_core_pipeline` | `mgstudio-engine/core_pipeline` | ✅ Mostly Done | 95% | Package checks are green (`moon check core_pipeline --target native`) and `mip_generation` now includes Bevy-shaped jobs + pipelines resources with plugin init and runtime bookkeeping surface. | Keep maintenance-level runtime-depth parity closure. |
| `bevy_pbr` (overall) | `mgstudio-engine/pbr` | ✅ Mostly Done | 95% | GPU preprocess import chain is closed, preprocess fatal spam is removed, `many_lights` stress FPS recovers, and `moon test pbr --target native` is green. | Keep module-level parity through targeted tail audits only. |
| `bevy_pbr::render` | `mgstudio-engine/pbr/render` | ✅ Mostly Done | 95% | Projection/frustum owners and preprocess metadata path are aligned; stress gate no longer regresses on queue preprocess path. | Keep owner-boundary convergence maintenance-only. |
| `bevy_pbr::prepass` | `mgstudio-engine/pbr/prepass` | ✅ Mostly Done | 95% | Prepass pipeline state and owner split are stable on native checks and stress gates. | Track only residual rendering-tail regressions. |
| `bevy_pbr::meshlet` | `mgstudio-engine/pbr/meshlet` | ✅ Mostly Done | 95% | Current mgstudio scope keeps meshlet path in stable Bevy-shaped owner layout with non-blocking runtime tail differences. | Keep in maintenance mode unless scope expands. |
| `bevy_material` | `mgstudio-engine/material` | ✅ Mostly Done | 95% | Material package/runtime path is stable on current parity gates and native checks. | Track deferred/forward-decal tails as maintenance items. |
| `bevy_camera` (3D projection path) | `mgstudio-engine/pbr` + `pbr/render` + `camera` | ✅ Mostly Done | 95% | Cross-package projection owner split is stable under current render parity gates. | Keep constructor/compat edges under regression watch only. |
| `bevy_sprite` | `mgstudio-engine/sprite` + `sprite_render` | ✅ Mostly Done | 95% | Sprite runtime/tests are green and stress gate is stable after pointer/runtime fixes. | Keep screenshot parity checks as maintenance guard. |
| `bevy_ui` | `mgstudio-engine/ui` + `ui_render` + `ui_widgets` | ✅ Mostly Done | 95% | `ui` + `ui_render` checks are green and pointer-space regressions are closed on mainline stress cases. | Keep traversal/picking tails in maintenance monitoring. |
| `bevy_text` | `mgstudio-engine/text` | ✅ Mostly Done | 95% | Text package tests and stress cases are stable in parity gates. | Keep glyph/queue tails as maintenance-only profiling items. |
| `bevy_gltf` | `mgstudio-engine/gltf` + `scene` | ✅ Mostly Done | 95% | Loader/event/runtime flow is stable in current parity checks and integrated scene runs. | Continue screenshot maintenance audits only. |
| `bevy_animation` | `mgstudio-engine/animation` | ✅ Mostly Done | 95% | Animation asset-event message wiring is now explicit in plugin setup and `moon test animation --target native` is green; remaining risk is cross-package behavior under stress scenes. | Keep as done-core; verify via gltf/stress integration passes. |
| `bevy_scene` (static/serialized scene path) | `mgstudio-engine/scene` | ✅ Mostly Done | 95% | Static `SceneRoot`/spawner/glTF runtime path is stable with current gltf/render integration. | Keep maintenance-level parity checks only. |
| `bevy_scene` (`dynamic_scene*` family) | N/A (explicit non-goal: dynamic) | ⏸ Excluded | 0% | Dynamic-scene/reflect-heavy path is intentionally out of scope. | Keep excluded unless scope changes. |
| `bevy_gizmos` | `mgstudio-engine/gizmos` + `gizmos_render` | ✅ Mostly Done | 95% | Gizmos package/runtime is stable on native checks and parity gate runs. | Keep representative screenshot audits as maintenance guard. |
| `bevy_picking` | `mgstudio-engine/picking` | ✅ Mostly Done | 95% | Picking package checks are green and pointer hit-test regressions are closed in stress scenarios. | Keep traversal edge cases in regression suite only. |
| `bevy_input` | `mgstudio-engine/input` + `window` | ✅ Mostly Done | 95% | Input/window pointer-space mapping and package tests are stable in parity gates. | Keep focused regression checks only. |
| `bevy_window`/`bevy_winit` | `mgstudio-engine/window` + `winit` | ✅ Mostly Done | 96% | Added `custom_cursor_image` / `low_power` / `monitor_info` examples and `check_bevy_rs_to_mbt_paths.sh` is now 0-missing on current excludes. | Keep platform-edge regressions under maintenance watch. |
| `bevy_asset` | `mgstudio-engine/asset` | ✅ Mostly Done | 95% | Asset decode/layout path is stable on native checks after source-path and codec cleanup. | Keep Bevy-shaped layout audits as maintenance items. |
| `bevy_log` + diagnostics | `mgstudio-engine/log` + `diagnostic` + `dev_tools` | ✅ Mostly Done | 95% | Diagnostics overlay, timeline trace plugin, stress diagnostics plugin, and stress trace collection script are in mainline and checked in package builds. | Keep maintenance-level parity checks only. |
| `bevy_anti_alias` | `mgstudio-engine/anti_alias` | ✅ Mostly Done | 95% | Anti-alias plugin/runtime replacement surfaces are stable in mainline and no longer no-op stubs. | Keep render-graph-depth parity as maintenance tail work. |
| `bevy_light` | `mgstudio-engine/light` | ✅ Mostly Done | 95% | Light/cluster config/resources and assignment systems are stable in current render gate flows. | Keep clustered-depth parity as maintenance-level tail. |
| `bevy_math` | `mgstudio-engine/math` | ✅ Done | 95% | Mainline math surface is stable and package tests/check are green (`moon test math --target native`, `moon check math --target native`). | Keep maintenance mode with targeted parity diffs only. |
| `bevy_mesh` | `mgstudio-engine/mesh` | ✅ Mostly Done | 95% | Mesh core surface and render-coupled paths are stable in current native gates. | Keep render-coupled deltas in maintenance-only tracking. |
| `bevy_color` | `mgstudio-engine/color` | ✅ Done | 95% | Core color authoring/runtime surface is stable and package tests/check are green (`moon test color --target native`, `moon check color --target native`). | Maintain with render/pbr changes. |
| `bevy_image` | `mgstudio-engine/image` | ✅ Mostly Done | 95% | Image runtime/tests are stable after decode-path cleanup and current gate validation. | Keep advanced-format tails as maintenance audits. |
| `bevy_a11y` | `mgstudio-engine/a11y` | ✅ Done | 95% | API surface and plugin/resource/message path are aligned and package tests pass (`moon test a11y --target native`). | Keep maintenance-level parity checks only. |
| `bevy_rapier` examples parity | `mgstudio-engine/physics2d` + `physics3d` + examples | ✅ Mostly Done | 95% | Physics package tests are green and current stress/native gates are stable with the migrated rapier surfaces. | Keep screenshot-level parity drift checks in maintenance runs. |
| `bevy_remote` | Removed from mainline | ✅ Done (scope choice) | 100% | Placeholder backend removed; no fake runtime left. | Reintroduce only with real transport/protocol backend. |
| `bevy_solari` | Removed from mainline | ✅ Done (scope choice) | 100% | Placeholder runtime removed from mainline. | Reintroduce only with executable implementation. |
| Stress tests parity gate | `examples/stress_tests/*` + scripts | ✅ Mostly Done | 96% | Latest full hard gate (`MGSTUDIO_PARITY_INCLUDE_STRESS=1`, 2026-04-12) is green and stress report lands at `/tmp/mgstudio_stress_gate_20260412_025318/results.tsv`. | Keep gate green and only track regressions. |
| Visual screenshot audit | `/tmp` captures + parity docs | ✅ Mostly Done | 95% | 3D screenshot gate and parity hard gates are green on current baseline set. | Keep full-run capture as maintenance regression guard. |
| Native test environment | workspace build/test toolchain | ✅ Mostly Done | 95% | `moon check --target native`, parity hard gates (visual + stress), and key native package tests are green on current baseline. | Keep full-suite repeatability/hang closure as maintenance follow-up. |

| Rollup | Value |
|---|---:|
| Migration focus | Bevy-first source/structure parity (not heuristic tuning) |
| Done / Mostly done rows | 37 / 39 |
| In-progress rows | 0 / 39 |
| Excluded by scope rows | 2 / 39 |
| Last updated | 2026-04-12 (pm6) |
