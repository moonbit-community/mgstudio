# Bevy Example Parity Matrix

Status: Active (SoT)
Last Verified: 2026-03-08
Scope: As-Implemented
Code References:
- `bevy/examples/`
- `mgstudio-engine/examples/`
- `scripts/generate_bevy_example_parity.py`
Superseded By: N/A
Notes:
- Status vocabulary: `Exact`, `Blocked`, `N/A`.
- Baseline commit: `48ec375a3a3cdc904476ef1d13f9d71c9f2820d3`.
- Baseline describe: `v0.16.0-rc.4-1998-g48ec375a3`.

## Summary by Category

| Category | Total | Exact | Blocked | N/A |
| --- | ---: | ---: | ---: | ---: |
| `2d` | 27 | 27 | 0 | 0 |
| `3d` | 66 | 42 | 24 | 0 |
| `animation` | 13 | 2 | 11 | 0 |
| `app` | 17 | 17 | 0 | 0 |
| `asset` | 15 | 0 | 15 | 0 |
| `async_tasks` | 3 | 0 | 3 | 0 |
| `audio` | 7 | 5 | 2 | 0 |
| `camera` | 9 | 7 | 2 | 0 |
| `dev_tools` | 1 | 0 | 1 | 0 |
| `diagnostics` | 3 | 2 | 1 | 0 |
| `ecs` | 32 | 0 | 32 | 0 |
| `games` | 7 | 0 | 7 | 0 |
| `gizmos` | 8 | 0 | 8 | 0 |
| `gltf` | 9 | 0 | 9 | 0 |
| `hello_world.rs` | 1 | 0 | 1 | 0 |
| `helpers` | 1 | 0 | 1 | 0 |
| `input` | 13 | 9 | 4 | 0 |
| `large_scenes` | 6 | 0 | 6 | 0 |
| `math` | 6 | 1 | 5 | 0 |
| `mobile` | 2 | 0 | 0 | 2 |
| `movement` | 2 | 0 | 2 | 0 |
| `no_std` | 1 | 0 | 0 | 1 |
| `picking` | 5 | 0 | 5 | 0 |
| `reflection` | 10 | 0 | 10 | 0 |
| `remote` | 2 | 0 | 2 | 0 |
| `scene` | 1 | 0 | 1 | 0 |
| `shader` | 17 | 0 | 17 | 0 |
| `shader_advanced` | 11 | 0 | 11 | 0 |
| `state` | 4 | 0 | 4 | 0 |
| `stress_tests` | 19 | 0 | 19 | 0 |
| `testbed` | 5 | 0 | 5 | 0 |
| `time` | 3 | 3 | 0 | 0 |
| `tools` | 5 | 0 | 5 | 0 |
| `transforms` | 5 | 4 | 1 | 0 |
| `ui` | 52 | 1 | 51 | 0 |
| `usage` | 2 | 0 | 2 | 0 |
| `window` | 12 | 3 | 9 | 0 |
| **Total** | **402** | **119** | **280** | **3** |

## Example Inventory

| Bevy Example | Category | mgstudio Example | Status | Owner | Notes |
| --- | --- | --- | --- | --- | --- |
| `bevy/examples/2d/2d_shapes.rs` | `2d` | `mgstudio-engine/examples/2d/2d_shapes` | `Exact` | `team-render` |  |
| `bevy/examples/2d/2d_viewport_to_world.rs` | `2d` | `mgstudio-engine/examples/2d/2d_viewport_to_world` | `Exact` | `team-render` |  |
| `bevy/examples/2d/bloom_2d.rs` | `2d` | `mgstudio-engine/examples/2d/bloom_2d` | `Exact` | `team-render` |  |
| `bevy/examples/2d/cpu_draw.rs` | `2d` | `mgstudio-engine/examples/2d/cpu_draw` | `Exact` | `team-render` |  |
| `bevy/examples/2d/dynamic_mip_generation.rs` | `2d` | `mgstudio-engine/examples/2d/dynamic_mip_generation` | `Exact` | `team-render` |  |
| `bevy/examples/2d/mesh2d.rs` | `2d` | `mgstudio-engine/examples/2d/mesh2d` | `Exact` | `team-render` |  |
| `bevy/examples/2d/mesh2d_alpha_mode.rs` | `2d` | `mgstudio-engine/examples/2d/mesh2d_alpha_mode` | `Exact` | `team-render` |  |
| `bevy/examples/2d/mesh2d_arcs.rs` | `2d` | `mgstudio-engine/examples/2d/mesh2d_arcs` | `Exact` | `team-render` |  |
| `bevy/examples/2d/mesh2d_manual.rs` | `2d` | `mgstudio-engine/examples/2d/mesh2d_manual` | `Exact` | `team-render` |  |
| `bevy/examples/2d/mesh2d_repeated_texture.rs` | `2d` | `mgstudio-engine/examples/2d/mesh2d_repeated_texture` | `Exact` | `team-render` |  |
| `bevy/examples/2d/mesh2d_vertex_color_texture.rs` | `2d` | `mgstudio-engine/examples/2d/mesh2d_vertex_color_texture` | `Exact` | `team-render` |  |
| `bevy/examples/2d/move_sprite.rs` | `2d` | `mgstudio-engine/examples/2d/move_sprite` | `Exact` | `team-render` |  |
| `bevy/examples/2d/pixel_grid_snap.rs` | `2d` | `mgstudio-engine/examples/2d/pixel_grid_snap` | `Exact` | `team-render` |  |
| `bevy/examples/2d/rotate_to_cursor.rs` | `2d` | `mgstudio-engine/examples/2d/rotate_to_cursor` | `Exact` | `team-render` |  |
| `bevy/examples/2d/rotation.rs` | `2d` | `mgstudio-engine/examples/2d/rotation` | `Exact` | `team-render` |  |
| `bevy/examples/2d/sprite.rs` | `2d` | `mgstudio-engine/examples/2d/sprite` | `Exact` | `team-render` |  |
| `bevy/examples/2d/sprite_animation.rs` | `2d` | `mgstudio-engine/examples/2d/sprite_animation` | `Exact` | `team-render` |  |
| `bevy/examples/2d/sprite_flipping.rs` | `2d` | `mgstudio-engine/examples/2d/sprite_flipping` | `Exact` | `team-render` |  |
| `bevy/examples/2d/sprite_scale.rs` | `2d` | `mgstudio-engine/examples/2d/sprite_scale` | `Exact` | `team-render` |  |
| `bevy/examples/2d/sprite_sheet.rs` | `2d` | `mgstudio-engine/examples/2d/sprite_sheet` | `Exact` | `team-render` |  |
| `bevy/examples/2d/sprite_slice.rs` | `2d` | `mgstudio-engine/examples/2d/sprite_slice` | `Exact` | `team-render` |  |
| `bevy/examples/2d/sprite_tile.rs` | `2d` | `mgstudio-engine/examples/2d/sprite_tile` | `Exact` | `team-render` |  |
| `bevy/examples/2d/text2d.rs` | `2d` | `mgstudio-engine/examples/2d/text2d` | `Exact` | `team-render` |  |
| `bevy/examples/2d/texture_atlas.rs` | `2d` | `mgstudio-engine/examples/2d/texture_atlas` | `Exact` | `team-render` |  |
| `bevy/examples/2d/tilemap_chunk.rs` | `2d` | `mgstudio-engine/examples/2d/tilemap_chunk` | `Exact` | `team-render` |  |
| `bevy/examples/2d/transparency_2d.rs` | `2d` | `mgstudio-engine/examples/2d/transparency_2d` | `Exact` | `team-render` |  |
| `bevy/examples/2d/wireframe_2d.rs` | `2d` | `mgstudio-engine/examples/2d/wireframe_2d` | `Exact` | `team-render` |  |
| `bevy/examples/3d/3d_scene.rs` | `3d` | `mgstudio-engine/examples/3d/3d_scene` | `Exact` | `team-render` |  |
| `bevy/examples/3d/3d_shapes.rs` | `3d` | `mgstudio-engine/examples/3d/3d_shapes` | `Exact` | `team-render` |  |
| `bevy/examples/3d/3d_viewport_to_world.rs` | `3d` | `mgstudio-engine/examples/3d/3d_viewport_to_world` | `Exact` | `team-render` |  |
| `bevy/examples/3d/animated_material.rs` | `3d` | `mgstudio-engine/examples/3d/animated_material` | `Exact` | `team-render` |  |
| `bevy/examples/3d/anisotropy.rs` | `3d` | `mgstudio-engine/examples/3d/anisotropy` | `Exact` | `team-render` |  |
| `bevy/examples/3d/anti_aliasing.rs` | `3d` | `mgstudio-engine/examples/3d/anti_aliasing` | `Exact` | `team-render` |  |
| `bevy/examples/3d/atmosphere.rs` | `3d` | `mgstudio-engine/examples/3d/atmosphere` | `Blocked` | `team-render` | Fallback implementation exists; blocked until exact parity. |
| `bevy/examples/3d/atmospheric_fog.rs` | `3d` | `mgstudio-engine/examples/3d/atmospheric_fog` | `Exact` | `team-render` |  |
| `bevy/examples/3d/auto_exposure.rs` | `3d` | `mgstudio-engine/examples/3d/auto_exposure` | `Blocked` | `team-render` | Fallback implementation exists; blocked until exact parity. |
| `bevy/examples/3d/blend_modes.rs` | `3d` | `mgstudio-engine/examples/3d/blend_modes` | `Exact` | `team-render` |  |
| `bevy/examples/3d/bloom_3d.rs` | `3d` | `mgstudio-engine/examples/3d/bloom_3d` | `Blocked` | `team-render` | Fallback implementation exists; blocked until exact parity. |
| `bevy/examples/3d/camera_sub_view.rs` | `3d` | `mgstudio-engine/examples/3d/camera_sub_view` | `Exact` | `team-render` |  |
| `bevy/examples/3d/clearcoat.rs` | `3d` | `mgstudio-engine/examples/3d/clearcoat` | `Exact` | `team-render` |  |
| `bevy/examples/3d/clustered_decal_maps.rs` | `3d` | `mgstudio-engine/examples/3d/clustered_decal_maps` | `Blocked` | `team-render` | Fallback implementation exists; blocked until exact parity. |
| `bevy/examples/3d/clustered_decals.rs` | `3d` | `mgstudio-engine/examples/3d/clustered_decals` | `Blocked` | `team-render` | Fallback implementation exists; blocked until exact parity. |
| `bevy/examples/3d/color_grading.rs` | `3d` | `mgstudio-engine/examples/3d/color_grading` | `Blocked` | `team-render` | Fallback implementation exists; blocked until exact parity. |
| `bevy/examples/3d/contact_shadows.rs` | `3d` | `mgstudio-engine/examples/3d/contact_shadows` | `Blocked` | `team-render` | Fallback implementation exists; blocked until exact parity. |
| `bevy/examples/3d/decal.rs` | `3d` | `mgstudio-engine/examples/3d/decal` | `Blocked` | `team-render` | Fallback implementation exists; blocked until exact parity. |
| `bevy/examples/3d/deferred_rendering.rs` | `3d` | `mgstudio-engine/examples/3d/deferred_rendering` | `Blocked` | `team-render` | Fallback implementation exists; blocked until exact parity. |
| `bevy/examples/3d/depth_of_field.rs` | `3d` | `mgstudio-engine/examples/3d/depth_of_field` | `Blocked` | `team-render` | Fallback implementation exists; blocked until exact parity. |
| `bevy/examples/3d/fog.rs` | `3d` | `mgstudio-engine/examples/3d/fog` | `Blocked` | `team-render` | Fallback implementation exists; blocked until exact parity. |
| `bevy/examples/3d/fog_volumes.rs` | `3d` | `mgstudio-engine/examples/3d/fog_volumes` | `Exact` | `team-render` |  |
| `bevy/examples/3d/generate_custom_mesh.rs` | `3d` | `mgstudio-engine/examples/3d/generate_custom_mesh` | `Exact` | `team-render` |  |
| `bevy/examples/3d/irradiance_volumes.rs` | `3d` | `mgstudio-engine/examples/3d/irradiance_volumes` | `Blocked` | `team-render` | Fallback implementation exists; blocked until exact parity. |
| `bevy/examples/3d/light_probe_blending.rs` | `3d` | `mgstudio-engine/examples/3d/light_probe_blending` | `Blocked` | `team-render` | Fallback implementation exists; blocked until exact parity. |
| `bevy/examples/3d/light_textures.rs` | `3d` | `mgstudio-engine/examples/3d/light_textures` | `Blocked` | `team-render` | Fallback implementation exists; blocked until exact parity. |
| `bevy/examples/3d/lighting.rs` | `3d` | `mgstudio-engine/examples/3d/lighting` | `Exact` | `team-render` |  |
| `bevy/examples/3d/lightmaps.rs` | `3d` | `mgstudio-engine/examples/3d/lightmaps` | `Blocked` | `team-render` | Fallback implementation exists; blocked until exact parity. |
| `bevy/examples/3d/lines.rs` | `3d` | `mgstudio-engine/examples/3d/lines` | `Exact` | `team-render` |  |
| `bevy/examples/3d/mesh_ray_cast.rs` | `3d` | `mgstudio-engine/examples/3d/mesh_ray_cast` | `Exact` | `team-render` |  |
| `bevy/examples/3d/meshlet.rs` | `3d` | `mgstudio-engine/examples/3d/meshlet` | `Blocked` | `team-render` | Fallback implementation exists; blocked until exact parity. |
| `bevy/examples/3d/mirror.rs` | `3d` | `mgstudio-engine/examples/3d/mirror` | `Exact` | `team-render` |  |
| `bevy/examples/3d/mixed_lighting.rs` | `3d` | `mgstudio-engine/examples/3d/mixed_lighting` | `Blocked` | `team-render` | Fallback implementation exists; blocked until exact parity. |
| `bevy/examples/3d/motion_blur.rs` | `3d` | `mgstudio-engine/examples/3d/motion_blur` | `Exact` | `team-render` |  |
| `bevy/examples/3d/occlusion_culling.rs` | `3d` | `mgstudio-engine/examples/3d/occlusion_culling` | `Blocked` | `team-render` | Fallback implementation exists; blocked until exact parity. |
| `bevy/examples/3d/order_independent_transparency.rs` | `3d` | `mgstudio-engine/examples/3d/order_independent_transparency` | `Exact` | `team-render` |  |
| `bevy/examples/3d/orthographic.rs` | `3d` | `mgstudio-engine/examples/3d/orthographic` | `Exact` | `team-render` |  |
| `bevy/examples/3d/parallax_mapping.rs` | `3d` | `mgstudio-engine/examples/3d/parallax_mapping` | `Exact` | `team-render` |  |
| `bevy/examples/3d/parenting.rs` | `3d` | `mgstudio-engine/examples/3d/parenting` | `Exact` | `team-render` |  |
| `bevy/examples/3d/pbr.rs` | `3d` | `mgstudio-engine/examples/3d/pbr` | `Exact` | `team-render` |  |
| `bevy/examples/3d/pccm.rs` | `3d` | `mgstudio-engine/examples/3d/pccm` | `Exact` | `team-render` |  |
| `bevy/examples/3d/pcss.rs` | `3d` | `mgstudio-engine/examples/3d/pcss` | `Exact` | `team-render` |  |
| `bevy/examples/3d/post_processing.rs` | `3d` | `mgstudio-engine/examples/3d/post_processing` | `Exact` | `team-render` |  |
| `bevy/examples/3d/reflection_probes.rs` | `3d` | `mgstudio-engine/examples/3d/reflection_probes` | `Exact` | `team-render` |  |
| `bevy/examples/3d/render_to_texture.rs` | `3d` | `mgstudio-engine/examples/3d/render_to_texture` | `Exact` | `team-render` |  |
| `bevy/examples/3d/rotate_environment_map.rs` | `3d` | `mgstudio-engine/examples/3d/rotate_environment_map` | `Exact` | `team-render` |  |
| `bevy/examples/3d/scrolling_fog.rs` | `3d` | `mgstudio-engine/examples/3d/scrolling_fog` | `Exact` | `team-render` |  |
| `bevy/examples/3d/shadow_biases.rs` | `3d` | `mgstudio-engine/examples/3d/shadow_biases` | `Exact` | `team-render` |  |
| `bevy/examples/3d/shadow_caster_receiver.rs` | `3d` | `mgstudio-engine/examples/3d/shadow_caster_receiver` | `Exact` | `team-render` |  |
| `bevy/examples/3d/skybox.rs` | `3d` | `mgstudio-engine/examples/3d/skybox` | `Exact` | `team-render` |  |
| `bevy/examples/3d/solari.rs` | `3d` | `mgstudio-engine/examples/3d/solari` | `Blocked` | `team-render` | Fallback implementation exists; blocked until exact parity. |
| `bevy/examples/3d/specular_tint.rs` | `3d` | `mgstudio-engine/examples/3d/specular_tint` | `Exact` | `team-render` |  |
| `bevy/examples/3d/spherical_area_lights.rs` | `3d` | `mgstudio-engine/examples/3d/spherical_area_lights` | `Exact` | `team-render` |  |
| `bevy/examples/3d/split_screen.rs` | `3d` | `mgstudio-engine/examples/3d/split_screen` | `Exact` | `team-render` |  |
| `bevy/examples/3d/spotlight.rs` | `3d` | `mgstudio-engine/examples/3d/spotlight` | `Exact` | `team-render` |  |
| `bevy/examples/3d/ssao.rs` | `3d` | `mgstudio-engine/examples/3d/ssao` | `Blocked` | `team-render` | Fallback implementation exists; blocked until exact parity. |
| `bevy/examples/3d/ssr.rs` | `3d` | `mgstudio-engine/examples/3d/ssr` | `Blocked` | `team-render` | Fallback implementation exists; blocked until exact parity. |
| `bevy/examples/3d/texture.rs` | `3d` | `mgstudio-engine/examples/3d/texture` | `Exact` | `team-render` |  |
| `bevy/examples/3d/tonemapping.rs` | `3d` | `mgstudio-engine/examples/3d/tonemapping` | `Blocked` | `team-render` | Fallback implementation exists; blocked until exact parity. |
| `bevy/examples/3d/transmission.rs` | `3d` | `mgstudio-engine/examples/3d/transmission` | `Blocked` | `team-render` | Fallback implementation exists; blocked until exact parity. |
| `bevy/examples/3d/transparency_3d.rs` | `3d` | `mgstudio-engine/examples/3d/transparency_3d` | `Exact` | `team-render` |  |
| `bevy/examples/3d/two_passes.rs` | `3d` | `mgstudio-engine/examples/3d/two_passes` | `Exact` | `team-render` |  |
| `bevy/examples/3d/vertex_colors.rs` | `3d` | `mgstudio-engine/examples/3d/vertex_colors` | `Exact` | `team-render` |  |
| `bevy/examples/3d/visibility_range.rs` | `3d` | `mgstudio-engine/examples/3d/visibility_range` | `Exact` | `team-render` |  |
| `bevy/examples/3d/volumetric_fog.rs` | `3d` | `mgstudio-engine/examples/3d/volumetric_fog` | `Blocked` | `team-render` | Fallback implementation exists; blocked until exact parity. |
| `bevy/examples/3d/wireframe.rs` | `3d` | `mgstudio-engine/examples/3d/wireframe` | `Exact` | `team-render` |  |
| `bevy/examples/animation/animated_mesh.rs` | `animation` |  | `Blocked` | `team-asset_scene` |  |
| `bevy/examples/animation/animated_mesh_control.rs` | `animation` |  | `Blocked` | `team-asset_scene` |  |
| `bevy/examples/animation/animated_mesh_events.rs` | `animation` |  | `Blocked` | `team-asset_scene` |  |
| `bevy/examples/animation/animated_transform.rs` | `animation` |  | `Blocked` | `team-asset_scene` |  |
| `bevy/examples/animation/animated_ui.rs` | `animation` |  | `Blocked` | `team-asset_scene` |  |
| `bevy/examples/animation/animation_events.rs` | `animation` |  | `Blocked` | `team-asset_scene` |  |
| `bevy/examples/animation/animation_graph.rs` | `animation` |  | `Blocked` | `team-asset_scene` |  |
| `bevy/examples/animation/animation_masks.rs` | `animation` |  | `Blocked` | `team-asset_scene` |  |
| `bevy/examples/animation/color_animation.rs` | `animation` | `mgstudio-engine/examples/animation/color_animation` | `Exact` | `team-asset_scene` |  |
| `bevy/examples/animation/custom_skinned_mesh.rs` | `animation` |  | `Blocked` | `team-asset_scene` |  |
| `bevy/examples/animation/eased_motion.rs` | `animation` |  | `Blocked` | `team-asset_scene` |  |
| `bevy/examples/animation/easing_functions.rs` | `animation` | `mgstudio-engine/examples/animation/easing_functions` | `Exact` | `team-asset_scene` |  |
| `bevy/examples/animation/morph_targets.rs` | `animation` |  | `Blocked` | `team-asset_scene` |  |
| `bevy/examples/app/custom_loop.rs` | `app` | `mgstudio-engine/examples/app/custom_loop` | `Exact` | `team-core` |  |
| `bevy/examples/app/drag_and_drop.rs` | `app` | `mgstudio-engine/examples/app/drag_and_drop` | `Exact` | `team-core` |  |
| `bevy/examples/app/empty.rs` | `app` | `mgstudio-engine/examples/app/empty` | `Exact` | `team-core` |  |
| `bevy/examples/app/empty_defaults.rs` | `app` | `mgstudio-engine/examples/app/empty_defaults` | `Exact` | `team-core` |  |
| `bevy/examples/app/externally_driven_headless_renderer.rs` | `app` | `mgstudio-engine/examples/app/externally_driven_headless_renderer` | `Exact` | `team-core` |  |
| `bevy/examples/app/headless.rs` | `app` | `mgstudio-engine/examples/app/headless` | `Exact` | `team-core` |  |
| `bevy/examples/app/headless_renderer.rs` | `app` | `mgstudio-engine/examples/app/headless_renderer` | `Exact` | `team-core` |  |
| `bevy/examples/app/log_layers.rs` | `app` | `mgstudio-engine/examples/app/log_layers` | `Exact` | `team-core` |  |
| `bevy/examples/app/log_layers_ecs.rs` | `app` | `mgstudio-engine/examples/app/log_layers_ecs` | `Exact` | `team-core` |  |
| `bevy/examples/app/logs.rs` | `app` | `mgstudio-engine/examples/app/logs` | `Exact` | `team-core` |  |
| `bevy/examples/app/no_renderer.rs` | `app` | `mgstudio-engine/examples/app/no_renderer` | `Exact` | `team-core` |  |
| `bevy/examples/app/plugin.rs` | `app` | `mgstudio-engine/examples/app/plugin` | `Exact` | `team-core` |  |
| `bevy/examples/app/plugin_group.rs` | `app` | `mgstudio-engine/examples/app/plugin_group` | `Exact` | `team-core` |  |
| `bevy/examples/app/render_recovery.rs` | `app` | `mgstudio-engine/examples/app/render_recovery` | `Exact` | `team-core` |  |
| `bevy/examples/app/return_after_run.rs` | `app` | `mgstudio-engine/examples/app/return_after_run` | `Exact` | `team-core` |  |
| `bevy/examples/app/thread_pool_resources.rs` | `app` | `mgstudio-engine/examples/app/thread_pool_resources` | `Exact` | `team-core` |  |
| `bevy/examples/app/without_winit.rs` | `app` | `mgstudio-engine/examples/app/without_winit` | `Exact` | `team-core` |  |
| `bevy/examples/asset/alter_mesh.rs` | `asset` |  | `Blocked` | `team-asset_scene` |  |
| `bevy/examples/asset/alter_sprite.rs` | `asset` |  | `Blocked` | `team-asset_scene` |  |
| `bevy/examples/asset/asset_decompression.rs` | `asset` |  | `Blocked` | `team-asset_scene` |  |
| `bevy/examples/asset/asset_loading.rs` | `asset` |  | `Blocked` | `team-asset_scene` |  |
| `bevy/examples/asset/asset_saving.rs` | `asset` |  | `Blocked` | `team-asset_scene` |  |
| `bevy/examples/asset/asset_settings.rs` | `asset` |  | `Blocked` | `team-asset_scene` |  |
| `bevy/examples/asset/custom_asset.rs` | `asset` |  | `Blocked` | `team-asset_scene` |  |
| `bevy/examples/asset/custom_asset_reader.rs` | `asset` |  | `Blocked` | `team-asset_scene` |  |
| `bevy/examples/asset/embedded_asset.rs` | `asset` |  | `Blocked` | `team-asset_scene` |  |
| `bevy/examples/asset/extra_source.rs` | `asset` |  | `Blocked` | `team-asset_scene` |  |
| `bevy/examples/asset/hot_asset_reloading.rs` | `asset` |  | `Blocked` | `team-asset_scene` |  |
| `bevy/examples/asset/multi_asset_sync.rs` | `asset` |  | `Blocked` | `team-asset_scene` |  |
| `bevy/examples/asset/processing/asset_processing.rs` | `asset` |  | `Blocked` | `team-asset_scene` |  |
| `bevy/examples/asset/repeated_texture.rs` | `asset` |  | `Blocked` | `team-asset_scene` |  |
| `bevy/examples/asset/web_asset.rs` | `asset` |  | `Blocked` | `team-asset_scene` |  |
| `bevy/examples/async_tasks/async_channel_pattern.rs` | `async_tasks` |  | `Blocked` | `team-core` |  |
| `bevy/examples/async_tasks/async_compute.rs` | `async_tasks` |  | `Blocked` | `team-core` |  |
| `bevy/examples/async_tasks/external_source_external_thread.rs` | `async_tasks` |  | `Blocked` | `team-core` |  |
| `bevy/examples/audio/audio.rs` | `audio` | `mgstudio-engine/examples/audio/audio` | `Exact` | `team-ops` |  |
| `bevy/examples/audio/audio_control.rs` | `audio` | `mgstudio-engine/examples/audio/audio_control` | `Exact` | `team-ops` |  |
| `bevy/examples/audio/decodable.rs` | `audio` |  | `Blocked` | `team-ops` | Blocked by missing Bevy-style custom decodable source registration (`bd-bi5`). |
| `bevy/examples/audio/pitch.rs` | `audio` |  | `Blocked` | `team-ops` | Blocked by MoonBit generic component impl coherence (`bd-wds`). |
| `bevy/examples/audio/soundtrack.rs` | `audio` | `mgstudio-engine/examples/audio/soundtrack` | `Exact` | `team-ops` |  |
| `bevy/examples/audio/spatial_audio_2d.rs` | `audio` | `mgstudio-engine/examples/audio/spatial_audio_2d` | `Exact` | `team-ops` |  |
| `bevy/examples/audio/spatial_audio_3d.rs` | `audio` | `mgstudio-engine/examples/audio/spatial_audio_3d` | `Exact` | `team-ops` |  |
| `bevy/examples/camera/2d_on_ui.rs` | `camera` | `mgstudio-engine/examples/camera/2d_on_ui` | `Exact` | `team-render` |  |
| `bevy/examples/camera/2d_screen_shake.rs` | `camera` | `mgstudio-engine/examples/camera/2d_screen_shake` | `Exact` | `team-render` |  |
| `bevy/examples/camera/2d_top_down_camera.rs` | `camera` | `mgstudio-engine/examples/camera/2d_top_down_camera` | `Exact` | `team-render` |  |
| `bevy/examples/camera/camera_orbit.rs` | `camera` | `mgstudio-engine/examples/camera/camera_orbit` | `Exact` | `team-render` |  |
| `bevy/examples/camera/custom_projection.rs` | `camera` |  | `Blocked` | `team-render` | Blocked by missing custom camera projection surface (`bd-shf`). |
| `bevy/examples/camera/first_person_view_model.rs` | `camera` | `mgstudio-engine/examples/camera/first_person_view_model` | `Exact` | `team-render` |  |
| `bevy/examples/camera/free_camera_controller.rs` | `camera` | `mgstudio-engine/examples/camera/free_camera_controller` | `Exact` | `team-render` |  |
| `bevy/examples/camera/pan_camera_controller.rs` | `camera` | `mgstudio-engine/examples/camera/pan_camera_controller` | `Exact` | `team-render` |  |
| `bevy/examples/camera/projection_zoom.rs` | `camera` |  | `Blocked` | `team-render` | Blocked by missing unified `Projection` component surface (`bd-52x`). |
| `bevy/examples/dev_tools/fps_overlay.rs` | `dev_tools` |  | `Blocked` | `team-ops` |  |
| `bevy/examples/diagnostics/custom_diagnostic.rs` | `diagnostics` | `mgstudio-engine/examples/diagnostics/custom_diagnostic` | `Exact` | `team-ops` |  |
| `bevy/examples/diagnostics/enabling_disabling_diagnostic.rs` | `diagnostics` | `mgstudio-engine/examples/diagnostics/enabling_disabling_diagnostic` | `Exact` | `team-ops` |  |
| `bevy/examples/diagnostics/log_diagnostics.rs` | `diagnostics` |  | `Blocked` | `team-ops` | Blocked by `SystemInformationDiagnosticsPlugin` (`bd-2j9.18`). |
| `bevy/examples/ecs/change_detection.rs` | `ecs` |  | `Blocked` | `team-core` |  |
| `bevy/examples/ecs/component_hooks.rs` | `ecs` |  | `Blocked` | `team-core` |  |
| `bevy/examples/ecs/contiguous_query.rs` | `ecs` |  | `Blocked` | `team-core` |  |
| `bevy/examples/ecs/custom_query_param.rs` | `ecs` |  | `Blocked` | `team-core` |  |
| `bevy/examples/ecs/custom_schedule.rs` | `ecs` |  | `Blocked` | `team-core` |  |
| `bevy/examples/ecs/dynamic.rs` | `ecs` |  | `Blocked` | `team-core` |  |
| `bevy/examples/ecs/ecs_guide.rs` | `ecs` |  | `Blocked` | `team-core` |  |
| `bevy/examples/ecs/entity_disabling.rs` | `ecs` |  | `Blocked` | `team-core` |  |
| `bevy/examples/ecs/error_handling.rs` | `ecs` |  | `Blocked` | `team-core` |  |
| `bevy/examples/ecs/fallible_params.rs` | `ecs` |  | `Blocked` | `team-core` |  |
| `bevy/examples/ecs/fixed_timestep.rs` | `ecs` |  | `Blocked` | `team-core` |  |
| `bevy/examples/ecs/generic_system.rs` | `ecs` |  | `Blocked` | `team-core` |  |
| `bevy/examples/ecs/hierarchy.rs` | `ecs` |  | `Blocked` | `team-core` |  |
| `bevy/examples/ecs/hotpatching_systems.rs` | `ecs` |  | `Blocked` | `team-core` |  |
| `bevy/examples/ecs/immutable_components.rs` | `ecs` |  | `Blocked` | `team-core` |  |
| `bevy/examples/ecs/iter_combinations.rs` | `ecs` |  | `Blocked` | `team-core` |  |
| `bevy/examples/ecs/message.rs` | `ecs` |  | `Blocked` | `team-core` |  |
| `bevy/examples/ecs/nondeterministic_system_order.rs` | `ecs` |  | `Blocked` | `team-core` |  |
| `bevy/examples/ecs/observer_propagation.rs` | `ecs` |  | `Blocked` | `team-core` |  |
| `bevy/examples/ecs/observers.rs` | `ecs` |  | `Blocked` | `team-core` |  |
| `bevy/examples/ecs/one_shot_systems.rs` | `ecs` |  | `Blocked` | `team-core` |  |
| `bevy/examples/ecs/parallel_query.rs` | `ecs` |  | `Blocked` | `team-core` |  |
| `bevy/examples/ecs/relationships.rs` | `ecs` |  | `Blocked` | `team-core` |  |
| `bevy/examples/ecs/removal_detection.rs` | `ecs` |  | `Blocked` | `team-core` |  |
| `bevy/examples/ecs/run_conditions.rs` | `ecs` |  | `Blocked` | `team-core` |  |
| `bevy/examples/ecs/send_and_receive_messages.rs` | `ecs` |  | `Blocked` | `team-core` |  |
| `bevy/examples/ecs/startup_system.rs` | `ecs` |  | `Blocked` | `team-core` |  |
| `bevy/examples/ecs/state_scoped.rs` | `ecs` |  | `Blocked` | `team-core` |  |
| `bevy/examples/ecs/system_closure.rs` | `ecs` |  | `Blocked` | `team-core` |  |
| `bevy/examples/ecs/system_param.rs` | `ecs` |  | `Blocked` | `team-core` |  |
| `bevy/examples/ecs/system_piping.rs` | `ecs` |  | `Blocked` | `team-core` |  |
| `bevy/examples/ecs/system_stepping.rs` | `ecs` |  | `Blocked` | `team-core` |  |
| `bevy/examples/games/alien_cake_addict.rs` | `games` |  | `Blocked` | `team-render` |  |
| `bevy/examples/games/breakout.rs` | `games` |  | `Blocked` | `team-render` |  |
| `bevy/examples/games/contributors.rs` | `games` |  | `Blocked` | `team-render` |  |
| `bevy/examples/games/desk_toy.rs` | `games` |  | `Blocked` | `team-render` |  |
| `bevy/examples/games/game_menu.rs` | `games` |  | `Blocked` | `team-render` |  |
| `bevy/examples/games/loading_screen.rs` | `games` |  | `Blocked` | `team-render` |  |
| `bevy/examples/games/stepping.rs` | `games` |  | `Blocked` | `team-render` |  |
| `bevy/examples/gizmos/2d_gizmos.rs` | `gizmos` |  | `Blocked` | `team-render` |  |
| `bevy/examples/gizmos/2d_text_gizmos.rs` | `gizmos` |  | `Blocked` | `team-render` |  |
| `bevy/examples/gizmos/3d_gizmos.rs` | `gizmos` |  | `Blocked` | `team-render` |  |
| `bevy/examples/gizmos/3d_text_gizmos.rs` | `gizmos` |  | `Blocked` | `team-render` |  |
| `bevy/examples/gizmos/anchored_text_gizmos.rs` | `gizmos` |  | `Blocked` | `team-render` |  |
| `bevy/examples/gizmos/axes.rs` | `gizmos` |  | `Blocked` | `team-render` |  |
| `bevy/examples/gizmos/light_gizmos.rs` | `gizmos` |  | `Blocked` | `team-render` |  |
| `bevy/examples/gizmos/text_gizmos_font.rs` | `gizmos` |  | `Blocked` | `team-render` |  |
| `bevy/examples/gltf/custom_gltf_vertex_attribute.rs` | `gltf` |  | `Blocked` | `team-asset_scene` |  |
| `bevy/examples/gltf/edit_material_on_gltf.rs` | `gltf` |  | `Blocked` | `team-asset_scene` |  |
| `bevy/examples/gltf/gltf_extension_animation_graph.rs` | `gltf` |  | `Blocked` | `team-asset_scene` |  |
| `bevy/examples/gltf/gltf_extension_mesh_2d.rs` | `gltf` |  | `Blocked` | `team-asset_scene` |  |
| `bevy/examples/gltf/gltf_skinned_mesh.rs` | `gltf` |  | `Blocked` | `team-asset_scene` |  |
| `bevy/examples/gltf/load_gltf.rs` | `gltf` |  | `Blocked` | `team-asset_scene` |  |
| `bevy/examples/gltf/load_gltf_extras.rs` | `gltf` |  | `Blocked` | `team-asset_scene` |  |
| `bevy/examples/gltf/query_gltf_primitives.rs` | `gltf` |  | `Blocked` | `team-asset_scene` |  |
| `bevy/examples/gltf/update_gltf_scene.rs` | `gltf` |  | `Blocked` | `team-asset_scene` |  |
| `bevy/examples/hello_world.rs` | `hello_world.rs` |  | `Blocked` | `team-parity` |  |
| `bevy/examples/helpers/widgets.rs` | `helpers` |  | `Blocked` | `team-ops` |  |
| `bevy/examples/input/char_input_events.rs` | `input` | `mgstudio-engine/examples/input/char_input_events` | `Exact` | `team-input_window` |  |
| `bevy/examples/input/gamepad_input.rs` | `input` | `mgstudio-engine/examples/input/gamepad_input` | `Exact` | `team-input_window` |  |
| `bevy/examples/input/gamepad_input_events.rs` | `input` | `mgstudio-engine/examples/input/gamepad_input_events` | `Exact` | `team-input_window` |  |
| `bevy/examples/input/gamepad_rumble.rs` | `input` | `mgstudio-engine/examples/input/gamepad_rumble` | `Exact` | `team-input_window` |  |
| `bevy/examples/input/keyboard_input.rs` | `input` | `mgstudio-engine/examples/input/keyboard_input` | `Exact` | `team-input_window` |  |
| `bevy/examples/input/keyboard_input_events.rs` | `input` | `mgstudio-engine/examples/input/keyboard_input_events` | `Exact` | `team-input_window` |  |
| `bevy/examples/input/keyboard_modifiers.rs` | `input` | `mgstudio-engine/examples/input/keyboard_modifiers` | `Exact` | `team-input_window` |  |
| `bevy/examples/input/mouse_grab.rs` | `input` | `mgstudio-engine/examples/input/mouse_grab` | `Blocked` | `team-input_window` | Blocked by missing real cursor visibility/grab backend parity (`bd-0re`). |
| `bevy/examples/input/mouse_input.rs` | `input` | `mgstudio-engine/examples/input/mouse_input` | `Exact` | `team-input_window` |  |
| `bevy/examples/input/mouse_input_events.rs` | `input` | `mgstudio-engine/examples/input/mouse_input_events` | `Exact` | `team-input_window` |  |
| `bevy/examples/input/text_input.rs` | `input` | `mgstudio-engine/examples/input/text_input` | `Blocked` | `team-input_window` | Blocked by missing IME/window/UI editing surface (`bd-zmg`, `bd-mdu`). |
| `bevy/examples/input/touch_input.rs` | `input` | `mgstudio-engine/examples/input/touch_input` | `Blocked` | `team-input_window` | Blocked by missing native touch event backend (`bd-lek`). |
| `bevy/examples/input/touch_input_events.rs` | `input` | `mgstudio-engine/examples/input/touch_input_events` | `Blocked` | `team-input_window` | Blocked by missing native touch event backend (`bd-lek`). |
| `bevy/examples/large_scenes/bistro/src/main.rs` | `large_scenes` |  | `Blocked` | `team-render` |  |
| `bevy/examples/large_scenes/caldera_hotel/src/main.rs` | `large_scenes` |  | `Blocked` | `team-render` |  |
| `bevy/examples/large_scenes/mipmap_generator/examples/load_gltf.rs` | `large_scenes` |  | `Blocked` | `team-render` |  |
| `bevy/examples/large_scenes/mipmap_generator/examples/test_compression.rs` | `large_scenes` |  | `Blocked` | `team-render` |  |
| `bevy/examples/large_scenes/mipmap_generator/examples/test_image.rs` | `large_scenes` |  | `Blocked` | `team-render` |  |
| `bevy/examples/large_scenes/mipmap_generator/src/lib.rs` | `large_scenes` |  | `Blocked` | `team-render` |  |
| `bevy/examples/math/bounding_2d.rs` | `math` | `mgstudio-engine/examples/math/bounding_2d` | `Blocked` | `team-core` | Example package now exists, but exact parity is still blocked until engine-owned 2D bounding volume and ray cast helpers replace the example-local implementations (`bd-h4h`). |
| `bevy/examples/math/cubic_splines.rs` | `math` | `mgstudio-engine/examples/math/cubic_splines` | `Exact` | `team-core` | Engine-owned cubic spline math surface now backs the exact port; zero-argument state install blocker remains tracked separately under `bd-byr`. |
| `bevy/examples/math/custom_primitives.rs` | `math` |  | `Blocked` | `team-core` | Blocked by missing custom primitive trait stack (`bd-jpy`). |
| `bevy/examples/math/random_sampling.rs` | `math` |  | `Blocked` | `team-core` | Blocked by missing primitive shape sampling distributions and related camera helper integration (`bd-29b`, `bd-jb1`). |
| `bevy/examples/math/render_primitives.rs` | `math` |  | `Blocked` | `team-core` | Blocked by missing public primitive rendering and gizmo surface (`bd-5te`). |
| `bevy/examples/math/sampling_primitives.rs` | `math` |  | `Blocked` | `team-core` | Blocked by missing primitive shape sampling distributions (`bd-29b`). |
| `bevy/examples/mobile/src/lib.rs` | `mobile` |  | `N/A` | `team-platform_na` | WASM-first policy: platform-incompatible category. |
| `bevy/examples/mobile/src/main.rs` | `mobile` |  | `N/A` | `team-platform_na` | WASM-first policy: platform-incompatible category. |
| `bevy/examples/movement/physics_in_fixed_timestep.rs` | `movement` |  | `Blocked` | `team-core` |  |
| `bevy/examples/movement/smooth_follow.rs` | `movement` |  | `Blocked` | `team-core` |  |
| `bevy/examples/no_std/library/src/lib.rs` | `no_std` |  | `N/A` | `team-platform_na` | WASM-first policy: platform-incompatible category. |
| `bevy/examples/picking/debug_picking.rs` | `picking` |  | `Blocked` | `team-render` |  |
| `bevy/examples/picking/dragdrop_picking.rs` | `picking` |  | `Blocked` | `team-render` |  |
| `bevy/examples/picking/mesh_picking.rs` | `picking` |  | `Blocked` | `team-render` |  |
| `bevy/examples/picking/simple_picking.rs` | `picking` |  | `Blocked` | `team-render` |  |
| `bevy/examples/picking/sprite_picking.rs` | `picking` |  | `Blocked` | `team-render` |  |
| `bevy/examples/reflection/auto_register_static/src/bin/main.rs` | `reflection` |  | `Blocked` | `team-ops` |  |
| `bevy/examples/reflection/auto_register_static/src/lib.rs` | `reflection` |  | `Blocked` | `team-ops` |  |
| `bevy/examples/reflection/custom_attributes.rs` | `reflection` |  | `Blocked` | `team-ops` |  |
| `bevy/examples/reflection/dynamic_types.rs` | `reflection` |  | `Blocked` | `team-ops` |  |
| `bevy/examples/reflection/function_reflection.rs` | `reflection` |  | `Blocked` | `team-ops` |  |
| `bevy/examples/reflection/generic_reflection.rs` | `reflection` |  | `Blocked` | `team-ops` |  |
| `bevy/examples/reflection/reflection.rs` | `reflection` |  | `Blocked` | `team-ops` |  |
| `bevy/examples/reflection/reflection_types.rs` | `reflection` |  | `Blocked` | `team-ops` |  |
| `bevy/examples/reflection/serialization.rs` | `reflection` |  | `Blocked` | `team-ops` |  |
| `bevy/examples/reflection/type_data.rs` | `reflection` |  | `Blocked` | `team-ops` |  |
| `bevy/examples/remote/client.rs` | `remote` |  | `Blocked` | `team-ops` |  |
| `bevy/examples/remote/server.rs` | `remote` |  | `Blocked` | `team-ops` |  |
| `bevy/examples/scene/scene.rs` | `scene` |  | `Blocked` | `team-asset_scene` |  |
| `bevy/examples/shader/animate_shader.rs` | `shader` |  | `Blocked` | `team-render` |  |
| `bevy/examples/shader/array_texture.rs` | `shader` |  | `Blocked` | `team-render` |  |
| `bevy/examples/shader/automatic_instancing.rs` | `shader` |  | `Blocked` | `team-render` |  |
| `bevy/examples/shader/compute_shader_game_of_life.rs` | `shader` |  | `Blocked` | `team-render` |  |
| `bevy/examples/shader/extended_material.rs` | `shader` |  | `Blocked` | `team-render` |  |
| `bevy/examples/shader/extended_material_bindless.rs` | `shader` |  | `Blocked` | `team-render` |  |
| `bevy/examples/shader/fallback_image.rs` | `shader` |  | `Blocked` | `team-render` |  |
| `bevy/examples/shader/gpu_readback.rs` | `shader` |  | `Blocked` | `team-render` |  |
| `bevy/examples/shader/shader_defs.rs` | `shader` |  | `Blocked` | `team-render` |  |
| `bevy/examples/shader/shader_material.rs` | `shader` |  | `Blocked` | `team-render` |  |
| `bevy/examples/shader/shader_material_2d.rs` | `shader` |  | `Blocked` | `team-render` |  |
| `bevy/examples/shader/shader_material_bindless.rs` | `shader` |  | `Blocked` | `team-render` |  |
| `bevy/examples/shader/shader_material_glsl.rs` | `shader` |  | `Blocked` | `team-render` |  |
| `bevy/examples/shader/shader_material_screenspace_texture.rs` | `shader` |  | `Blocked` | `team-render` |  |
| `bevy/examples/shader/shader_material_wesl.rs` | `shader` |  | `Blocked` | `team-render` |  |
| `bevy/examples/shader/shader_prepass.rs` | `shader` |  | `Blocked` | `team-render` |  |
| `bevy/examples/shader/storage_buffer.rs` | `shader` |  | `Blocked` | `team-render` |  |
| `bevy/examples/shader_advanced/compute_mesh.rs` | `shader_advanced` |  | `Blocked` | `team-render` |  |
| `bevy/examples/shader_advanced/custom_phase_item.rs` | `shader_advanced` |  | `Blocked` | `team-render` |  |
| `bevy/examples/shader_advanced/custom_post_processing.rs` | `shader_advanced` |  | `Blocked` | `team-render` |  |
| `bevy/examples/shader_advanced/custom_render_phase.rs` | `shader_advanced` |  | `Blocked` | `team-render` |  |
| `bevy/examples/shader_advanced/custom_shader_instancing.rs` | `shader_advanced` |  | `Blocked` | `team-render` |  |
| `bevy/examples/shader_advanced/custom_vertex_attribute.rs` | `shader_advanced` |  | `Blocked` | `team-render` |  |
| `bevy/examples/shader_advanced/fullscreen_material.rs` | `shader_advanced` |  | `Blocked` | `team-render` |  |
| `bevy/examples/shader_advanced/manual_material.rs` | `shader_advanced` |  | `Blocked` | `team-render` |  |
| `bevy/examples/shader_advanced/render_depth_to_texture.rs` | `shader_advanced` |  | `Blocked` | `team-render` |  |
| `bevy/examples/shader_advanced/specialized_mesh_pipeline.rs` | `shader_advanced` |  | `Blocked` | `team-render` |  |
| `bevy/examples/shader_advanced/texture_binding_array.rs` | `shader_advanced` |  | `Blocked` | `team-render` |  |
| `bevy/examples/state/computed_states.rs` | `state` |  | `Blocked` | `team-core` |  |
| `bevy/examples/state/custom_transitions.rs` | `state` |  | `Blocked` | `team-core` |  |
| `bevy/examples/state/states.rs` | `state` |  | `Blocked` | `team-core` |  |
| `bevy/examples/state/sub_states.rs` | `state` |  | `Blocked` | `team-core` |  |
| `bevy/examples/stress_tests/bevymark.rs` | `stress_tests` |  | `Blocked` | `team-render` |  |
| `bevy/examples/stress_tests/bevymark_3d.rs` | `stress_tests` |  | `Blocked` | `team-render` |  |
| `bevy/examples/stress_tests/many_animated_sprite_meshes.rs` | `stress_tests` |  | `Blocked` | `team-render` |  |
| `bevy/examples/stress_tests/many_animated_sprites.rs` | `stress_tests` |  | `Blocked` | `team-render` |  |
| `bevy/examples/stress_tests/many_buttons.rs` | `stress_tests` |  | `Blocked` | `team-render` |  |
| `bevy/examples/stress_tests/many_cameras_lights.rs` | `stress_tests` |  | `Blocked` | `team-render` |  |
| `bevy/examples/stress_tests/many_components.rs` | `stress_tests` |  | `Blocked` | `team-render` |  |
| `bevy/examples/stress_tests/many_cubes.rs` | `stress_tests` |  | `Blocked` | `team-render` |  |
| `bevy/examples/stress_tests/many_foxes.rs` | `stress_tests` |  | `Blocked` | `team-render` |  |
| `bevy/examples/stress_tests/many_gizmos.rs` | `stress_tests` |  | `Blocked` | `team-render` |  |
| `bevy/examples/stress_tests/many_glyphs.rs` | `stress_tests` |  | `Blocked` | `team-render` |  |
| `bevy/examples/stress_tests/many_gradients.rs` | `stress_tests` |  | `Blocked` | `team-render` |  |
| `bevy/examples/stress_tests/many_lights.rs` | `stress_tests` |  | `Blocked` | `team-render` |  |
| `bevy/examples/stress_tests/many_materials.rs` | `stress_tests` |  | `Blocked` | `team-render` |  |
| `bevy/examples/stress_tests/many_sprite_meshes.rs` | `stress_tests` |  | `Blocked` | `team-render` |  |
| `bevy/examples/stress_tests/many_sprites.rs` | `stress_tests` |  | `Blocked` | `team-render` |  |
| `bevy/examples/stress_tests/many_text2d.rs` | `stress_tests` |  | `Blocked` | `team-render` |  |
| `bevy/examples/stress_tests/text_pipeline.rs` | `stress_tests` |  | `Blocked` | `team-render` |  |
| `bevy/examples/stress_tests/transform_hierarchy.rs` | `stress_tests` |  | `Blocked` | `team-render` |  |
| `bevy/examples/testbed/2d.rs` | `testbed` |  | `Blocked` | `team-render` |  |
| `bevy/examples/testbed/3d.rs` | `testbed` |  | `Blocked` | `team-render` |  |
| `bevy/examples/testbed/full_ui.rs` | `testbed` |  | `Blocked` | `team-render` |  |
| `bevy/examples/testbed/helpers.rs` | `testbed` |  | `Blocked` | `team-render` |  |
| `bevy/examples/testbed/ui.rs` | `testbed` |  | `Blocked` | `team-render` |  |
| `bevy/examples/time/time.rs` | `time` | `mgstudio-engine/examples/time/time` | `Exact` | `team-core` |  |
| `bevy/examples/time/timers.rs` | `time` | `mgstudio-engine/examples/time/timers` | `Exact` | `team-core` |  |
| `bevy/examples/time/virtual_time.rs` | `time` | `mgstudio-engine/examples/time/virtual_time` | `Exact` | `team-core` |  |
| `bevy/examples/tools/gamepad_viewer.rs` | `tools` |  | `Blocked` | `team-ops` |  |
| `bevy/examples/tools/scene_viewer/animation_plugin.rs` | `tools` |  | `Blocked` | `team-ops` |  |
| `bevy/examples/tools/scene_viewer/main.rs` | `tools` |  | `Blocked` | `team-ops` |  |
| `bevy/examples/tools/scene_viewer/morph_viewer_plugin.rs` | `tools` |  | `Blocked` | `team-ops` |  |
| `bevy/examples/tools/scene_viewer/scene_viewer_plugin.rs` | `tools` |  | `Blocked` | `team-ops` |  |
| `bevy/examples/transforms/3d_rotation.rs` | `transforms` | `mgstudio-engine/examples/transforms/3d_rotation` | `Exact` | `team-core` |  |
| `bevy/examples/transforms/align.rs` | `transforms` |  | `Blocked` | `team-core` | Blocked by missing 3D gizmo parity (`bd-2j9.9.3.2`) and ship GLTF asset staging (`bd-7ff`). |
| `bevy/examples/transforms/scale.rs` | `transforms` | `mgstudio-engine/examples/transforms/scale` | `Exact` | `team-core` |  |
| `bevy/examples/transforms/transform.rs` | `transforms` | `mgstudio-engine/examples/transforms/transform` | `Exact` | `team-core` |  |
| `bevy/examples/transforms/translation.rs` | `transforms` | `mgstudio-engine/examples/transforms/translation` | `Exact` | `team-core` |  |
| `bevy/examples/ui/images/image_node.rs` | `ui` |  | `Blocked` | `team-ui_text` |  |
| `bevy/examples/ui/images/image_node_resizing.rs` | `ui` |  | `Blocked` | `team-ui_text` |  |
| `bevy/examples/ui/images/ui_texture_atlas.rs` | `ui` |  | `Blocked` | `team-ui_text` |  |
| `bevy/examples/ui/images/ui_texture_atlas_slice.rs` | `ui` |  | `Blocked` | `team-ui_text` |  |
| `bevy/examples/ui/images/ui_texture_slice.rs` | `ui` |  | `Blocked` | `team-ui_text` |  |
| `bevy/examples/ui/images/ui_texture_slice_flip_and_tile.rs` | `ui` |  | `Blocked` | `team-ui_text` |  |
| `bevy/examples/ui/layout/anchor_layout.rs` | `ui` |  | `Blocked` | `team-ui_text` |  |
| `bevy/examples/ui/layout/display_and_visibility.rs` | `ui` |  | `Blocked` | `team-ui_text` |  |
| `bevy/examples/ui/layout/flex_layout.rs` | `ui` |  | `Blocked` | `team-ui_text` |  |
| `bevy/examples/ui/layout/ghost_nodes.rs` | `ui` |  | `Blocked` | `team-ui_text` |  |
| `bevy/examples/ui/layout/grid.rs` | `ui` |  | `Blocked` | `team-ui_text` |  |
| `bevy/examples/ui/layout/size_constraints.rs` | `ui` |  | `Blocked` | `team-ui_text` |  |
| `bevy/examples/ui/layout/z_index.rs` | `ui` |  | `Blocked` | `team-ui_text` |  |
| `bevy/examples/ui/navigation/directional_navigation.rs` | `ui` |  | `Blocked` | `team-ui_text` |  |
| `bevy/examples/ui/navigation/directional_navigation_overrides.rs` | `ui` |  | `Blocked` | `team-ui_text` |  |
| `bevy/examples/ui/relative_cursor_position.rs` | `ui` |  | `Blocked` | `team-ui_text` |  |
| `bevy/examples/ui/render_ui_to_texture.rs` | `ui` |  | `Blocked` | `team-ui_text` |  |
| `bevy/examples/ui/scroll_and_overflow/drag_to_scroll.rs` | `ui` |  | `Blocked` | `team-ui_text` |  |
| `bevy/examples/ui/scroll_and_overflow/overflow.rs` | `ui` |  | `Blocked` | `team-ui_text` |  |
| `bevy/examples/ui/scroll_and_overflow/overflow_clip_margin.rs` | `ui` |  | `Blocked` | `team-ui_text` |  |
| `bevy/examples/ui/scroll_and_overflow/overflow_debug.rs` | `ui` |  | `Blocked` | `team-ui_text` |  |
| `bevy/examples/ui/scroll_and_overflow/scroll.rs` | `ui` |  | `Blocked` | `team-ui_text` |  |
| `bevy/examples/ui/scroll_and_overflow/scrollbars.rs` | `ui` |  | `Blocked` | `team-ui_text` |  |
| `bevy/examples/ui/styling/borders.rs` | `ui` |  | `Blocked` | `team-ui_text` |  |
| `bevy/examples/ui/styling/box_shadow.rs` | `ui` |  | `Blocked` | `team-ui_text` |  |
| `bevy/examples/ui/styling/gradients.rs` | `ui` |  | `Blocked` | `team-ui_text` |  |
| `bevy/examples/ui/styling/stacked_gradients.rs` | `ui` |  | `Blocked` | `team-ui_text` |  |
| `bevy/examples/ui/styling/transparency_ui.rs` | `ui` |  | `Blocked` | `team-ui_text` |  |
| `bevy/examples/ui/text/font_atlas_debug.rs` | `ui` |  | `Blocked` | `team-ui_text` |  |
| `bevy/examples/ui/text/font_query.rs` | `ui` |  | `Blocked` | `team-ui_text` |  |
| `bevy/examples/ui/text/font_weights.rs` | `ui` |  | `Blocked` | `team-ui_text` |  |
| `bevy/examples/ui/text/generic_font_families.rs` | `ui` |  | `Blocked` | `team-ui_text` |  |
| `bevy/examples/ui/text/strikethrough_and_underline.rs` | `ui` |  | `Blocked` | `team-ui_text` |  |
| `bevy/examples/ui/text/system_fonts.rs` | `ui` |  | `Blocked` | `team-ui_text` |  |
| `bevy/examples/ui/text/text.rs` | `ui` |  | `Blocked` | `team-ui_text` |  |
| `bevy/examples/ui/text/text_background_colors.rs` | `ui` |  | `Blocked` | `team-ui_text` |  |
| `bevy/examples/ui/text/text_debug.rs` | `ui` |  | `Blocked` | `team-ui_text` |  |
| `bevy/examples/ui/text/text_wrap_debug.rs` | `ui` |  | `Blocked` | `team-ui_text` |  |
| `bevy/examples/ui/ui_drag_and_drop.rs` | `ui` |  | `Blocked` | `team-ui_text` |  |
| `bevy/examples/ui/ui_material.rs` | `ui` |  | `Blocked` | `team-ui_text` |  |
| `bevy/examples/ui/ui_scaling.rs` | `ui` |  | `Blocked` | `team-ui_text` |  |
| `bevy/examples/ui/ui_target_camera.rs` | `ui` |  | `Blocked` | `team-ui_text` |  |
| `bevy/examples/ui/ui_transform.rs` | `ui` |  | `Blocked` | `team-ui_text` |  |
| `bevy/examples/ui/widgets/button.rs` | `ui` | `mgstudio-engine/examples/ui/button` | `Exact` | `team-ui_text` |  |
| `bevy/examples/ui/widgets/feathers.rs` | `ui` |  | `Blocked` | `team-ui_text` |  |
| `bevy/examples/ui/widgets/standard_widgets.rs` | `ui` |  | `Blocked` | `team-ui_text` |  |
| `bevy/examples/ui/widgets/standard_widgets_observers.rs` | `ui` |  | `Blocked` | `team-ui_text` |  |
| `bevy/examples/ui/widgets/tab_navigation.rs` | `ui` |  | `Blocked` | `team-ui_text` |  |
| `bevy/examples/ui/widgets/vertical_slider.rs` | `ui` |  | `Blocked` | `team-ui_text` |  |
| `bevy/examples/ui/widgets/viewport_node.rs` | `ui` |  | `Blocked` | `team-ui_text` |  |
| `bevy/examples/ui/widgets/virtual_keyboard.rs` | `ui` |  | `Blocked` | `team-ui_text` |  |
| `bevy/examples/ui/window_fallthrough.rs` | `ui` |  | `Blocked` | `team-ui_text` |  |
| `bevy/examples/usage/context_menu.rs` | `usage` |  | `Blocked` | `team-core` |  |
| `bevy/examples/usage/cooldown.rs` | `usage` |  | `Blocked` | `team-core` |  |
| `bevy/examples/window/clear_color.rs` | `window` | `mgstudio-engine/examples/window/clear_color` | `Exact` | `team-input_window` |  |
| `bevy/examples/window/custom_cursor_image.rs` | `window` | `mgstudio-engine/examples/window/custom_cursor_image` | `Blocked` | `team-input_window` | Fallback implementation exists; blocked until exact parity. |
| `bevy/examples/window/low_power.rs` | `window` | `mgstudio-engine/examples/window/low_power` | `Blocked` | `team-input_window` | Fallback implementation exists; blocked until exact parity. |
| `bevy/examples/window/monitor_info.rs` | `window` | `mgstudio-engine/examples/window/monitor_info` | `Blocked` | `team-input_window` | Fallback implementation exists; blocked until exact parity. |
| `bevy/examples/window/multi_window_text.rs` | `window` | `mgstudio-engine/examples/window/multi_window_text` | `Blocked` | `team-input_window` | Fallback implementation exists; blocked until exact parity. |
| `bevy/examples/window/multiple_windows.rs` | `window` | `mgstudio-engine/examples/window/multiple_windows` | `Blocked` | `team-input_window` | Fallback implementation exists; blocked until exact parity. |
| `bevy/examples/window/scale_factor_override.rs` | `window` | `mgstudio-engine/examples/window/scale_factor_override` | `Exact` | `team-input_window` |  |
| `bevy/examples/window/screenshot.rs` | `window` | `mgstudio-engine/examples/window/screenshot` | `Blocked` | `team-input_window` | Fallback implementation exists; blocked until exact parity. |
| `bevy/examples/window/transparent_window.rs` | `window` | `mgstudio-engine/examples/window/transparent_window` | `Blocked` | `team-input_window` | Fallback implementation exists; blocked until exact parity. |
| `bevy/examples/window/window_drag_move.rs` | `window` | `mgstudio-engine/examples/window/window_drag_move` | `Blocked` | `team-input_window` | Fallback implementation exists; blocked until exact parity. |
| `bevy/examples/window/window_resizing.rs` | `window` | `mgstudio-engine/examples/window/window_resizing` | `Exact` | `team-input_window` |  |
| `bevy/examples/window/window_settings.rs` | `window` | `mgstudio-engine/examples/window/window_settings` | `Blocked` | `team-input_window` | Fallback implementation exists; blocked until exact parity. |
