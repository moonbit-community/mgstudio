This file tracks Bevy-first render source mapping and must be kept in sync with actual code layout.

- [x] `bevy/crates/bevy_render/src/lib.rs` -> `mgstudio-engine/render/lib.mbt` (`Rewrite`)
- [x] `bevy/crates/bevy_render/src/extract_plugin.rs` -> `mgstudio-engine/render/extract_plugin.mbt` (`Rewrite`)
- [x] `bevy/crates/bevy_render/src/renderer/mod.rs` -> `mgstudio-engine/render/renderer/mod.mbt` (`Rewrite`)
- [x] `bevy/crates/bevy_render/src/renderer/render_context.rs` -> `mgstudio-engine/render/renderer/render_context.mbt` (`Rewrite`)
- [x] `bevy/crates/bevy_render/src/renderer/wgpu_wrapper.rs` -> `mgstudio-engine/render/renderer/wgpu_wrapper.mbt` (`Rewrite`)
- [x] `bevy/crates/bevy_render/src/view/window/screenshot.rs` -> `mgstudio-engine/render/renderer/screenshot.mbt` (`Rewrite`)
- [x] `bevy/crates/bevy_render/src/view/window/mod.rs` -> `mgstudio-engine/render/renderer/window_surface.mbt` (`Rewrite`)
- [x] `bevy/crates/bevy_render/src/mesh/mod.rs` -> `mgstudio-engine/render/renderer/mesh.mbt` (`Rewrite`)
- [x] `bevy/crates/bevy_render/src/render_phase/draw_state.rs` -> `mgstudio-engine/render/renderer/draw_state.mbt` (`Rewrite`)
- [x] `bevy/crates/bevy_sprite_render/src/mesh2d/mesh.rs` -> `mgstudio-engine/render/renderer/mesh2d_draw.mbt` (`Rewrite`)
- [x] `bevy/crates/bevy_pbr/src/render/mesh.rs` (renderer-facing draw path) -> `mgstudio-engine/render/renderer/mesh3d_draw.mbt` (`Rewrite`)

- [x] `bevy/crates/bevy_pbr/src/render/mesh.rs` (core 3d extract/prepare/queue/execute) -> `mgstudio-engine/pbr/mesh.mbt` (`Rewrite`)
- [x] `bevy/crates/bevy_pbr/src/render/mesh.rs` (phase data helpers) -> `mgstudio-engine/pbr/phase.mbt` (`Rewrite`)
- [x] `bevy/crates/bevy_pbr/src/render/mesh.rs` (phase-state resource helpers) -> `mgstudio-engine/pbr/render3d_phase_state.mbt` (`Split`)
- [x] `bevy/crates/bevy_pbr/src/render/mesh.rs` (shared math/comparison helpers) -> `mgstudio-engine/pbr/render3d_math.mbt` (`Split`)
- [x] `bevy/crates/bevy_pbr/src/render/mesh.rs` (postprocess stack helpers) -> `mgstudio-engine/pbr/render3d_postprocess.mbt` (`Split`)
- [x] `bevy/crates/bevy_pbr/src/render/mesh.rs` (world transform cache + skinning extraction helpers) -> `mgstudio-engine/pbr/render3d_world_transform_cache.mbt` (`Split`)
- [x] `bevy/crates/bevy_pbr/src/render/mesh.rs` (scene target cache + lighting/environment/skybox helpers) -> `mgstudio-engine/pbr/render3d_scene_resources.mbt` (`Split`)
- [x] `bevy/crates/bevy_pbr/src/bundle.rs` -> `mgstudio-engine/pbr/bundles.mbt` (`Split`)
- [x] `bevy/crates/bevy_pbr/src/render/mod.rs` -> `mgstudio-engine/pbr/mod.mbt` (`Rewrite`)
- [x] `bevy/crates/bevy_pbr/src/render/mesh_bindings.rs` -> `mgstudio-engine/pbr/render3d_bindings.mbt` (`Create`)
- [x] `bevy/crates/bevy_pbr/src/render/mesh_view_bindings.rs` -> `mgstudio-engine/pbr/render3d_view_bindings.mbt` (`Create`)
- [x] `bevy/crates/bevy_pbr/src/render/skin.rs` -> `mgstudio-engine/pbr/render3d_skin.mbt` (`Create`)
- [ ] `bevy/crates/bevy_pbr/src/render/morph.rs` -> `mgstudio-engine/pbr/render3d_morph.mbt` (`Create`)
- [x] `bevy/crates/bevy_pbr/src/render/light.rs` -> `mgstudio-engine/pbr/render3d_light.mbt` (`Create`)
- [x] `bevy/crates/bevy_pbr/src/render/fog.rs` -> `mgstudio-engine/pbr/render3d_fog.mbt` (`Create`)
- [x] `bevy/crates/bevy_pbr/src/render/gpu_preprocess.rs` -> `mgstudio-engine/pbr/render3d_gpu_preprocess.mbt` (`Create`)

- [x] `bevy/crates/bevy_render/src/render_phase/mod.rs` -> `mgstudio-engine/render/render_phase.mbt` (`Create`)
- [x] `bevy/crates/bevy_render/src/texture/mod.rs` -> `mgstudio-engine/render/texture.mbt` (`Create`)

Decision rule:
- [x] parity-first closure (source/module structure + runtime behavior align with Bevy intent)
- [x] performance traces and FPS are verification artifacts, not architecture drivers
