// Copyright 2025 International Digital Economy Academy
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

///|
// Bevy source: `bevy/crates/bevy_sprite_render/src/render/mod.rs`.
// Bridge surface to the root `sprite_render` package implementation.
pub using @sprite_render {type OverlaySpriteUvScissor}

///|
pub using @sprite_render {type SceneCullContext}

///|
pub using @sprite_render {type UiBorderRect}

///|
pub using @sprite_render {type UiCornerRadii}

///|
pub let render2d_set_execute : @app.SystemSet = @sprite_render.render2d_set_execute

///|
pub let render2d_set_extract : @app.SystemSet = @sprite_render.render2d_set_extract

///|
pub let render2d_set_prepare : @app.SystemSet = @sprite_render.render2d_set_prepare

///|
pub let render2d_set_queue : @app.SystemSet = @sprite_render.render2d_set_queue

///|
pub let render2d_set_render : @app.SystemSet = @sprite_render.render2d_set_render

///|
pub let render2d_set_transparent_2d : @app.SystemSet = @sprite_render.render2d_set_transparent_2d

///|
pub fn render2d_clear_overlay_ui_box_shadows(world : @ecs.World) -> Unit {
  @sprite_render.render2d_clear_overlay_ui_box_shadows(world)
}

///|
pub fn render2d_clear_overlay_ui_rects(world : @ecs.World) -> Unit {
  @sprite_render.render2d_clear_overlay_ui_rects(world)
}

///|
pub fn render2d_clear_overlay_ui_texture_slices(world : @ecs.World) -> Unit {
  @sprite_render.render2d_clear_overlay_ui_texture_slices(world)
}

///|
pub fn render2d_create_render_target(
  world : @ecs.World,
  width : Int,
  height : Int,
  use_hdr : Bool,
) -> @asset.Handle[@asset.Image] {
  @sprite_render.render2d_create_render_target(world, width, height, use_hdr)
}

///|
pub fn render2d_create_render_target_ecs(
  width : Int,
  height : Int,
  use_hdr : Bool,
) -> @asset.Handle[@asset.Image] {
  @sprite_render.render2d_create_render_target_ecs(width, height, use_hdr)
}

///|
pub fn render2d_diagnostic_execute_cpu_ms() -> Float {
  @sprite_render.render2d_diagnostic_execute_cpu_ms()
}

///|
pub fn render2d_diagnostic_prepared_camera_count() -> Int {
  @sprite_render.render2d_diagnostic_prepared_camera_count()
}

///|
pub fn render2d_diagnostic_queue_cpu_ms() -> Float {
  @sprite_render.render2d_diagnostic_queue_cpu_ms()
}

///|
pub fn render2d_diagnostic_queued_draw_item_count() -> Int {
  @sprite_render.render2d_diagnostic_queued_draw_item_count()
}

///|
pub fn render2d_draw_tilemap_chunk(
  world : @ecs.World,
  chunk : @sprite_render.TilemapChunk,
  tile_data : @sprite_render.TilemapChunkTileData,
  transform : @transform.Transform,
  layers : @sprite.RenderLayers,
) -> Unit {
  @sprite_render.render2d_draw_tilemap_chunk(
    world, chunk, tile_data, transform, layers,
  )
}

///|
pub fn render2d_primary_scene_cull_context(
  world : @ecs.World,
) -> @sprite_render.SceneCullContext? {
  @sprite_render.render2d_primary_scene_cull_context(world)
}

///|
pub fn render2d_push_sprite_uv_scissor_batch(
  world : @ecs.World,
  sprites : Array[@sprite_render.OverlaySpriteUvScissor],
) -> Unit {
  @sprite_render.render2d_push_sprite_uv_scissor_batch(world, sprites)
}

///|
pub fn render2d_push_ui_box_shadow_scissor(
  world : @ecs.World,
  entity : @core.Entity,
  target_camera : @core.Entity?,
  texture : @asset.Handle[@asset.Image],
  transform : @transform.Transform,
  draw_scale : @math.Vec2,
  color : @color.Color,
  layers : @sprite.RenderLayers,
  scissor : @math.Rect?,
  size : @math.Vec2,
  radius : @sprite_render.UiCornerRadii,
  blur : Float,
  samples : Int,
) -> Unit {
  @sprite_render.render2d_push_ui_box_shadow_scissor(
    world, entity, target_camera, texture, transform, draw_scale, color, layers,
    scissor, size, radius, blur, samples,
  )
}

///|
pub fn render2d_push_ui_rect_uv_scissor(
  world : @ecs.World,
  entity : @core.Entity,
  target_camera : @core.Entity?,
  texture : @asset.Handle[@asset.Image],
  transform : @transform.Transform,
  draw_scale : @math.Vec2,
  uv_min : @math.Vec2,
  uv_max : @math.Vec2,
  color : @color.Color,
  layers : @sprite.RenderLayers,
  scissor : @math.Rect?,
  flags : Int,
  radius : @sprite_render.UiCornerRadii,
  border : @sprite_render.UiBorderRect,
) -> Unit {
  @sprite_render.render2d_push_ui_rect_uv_scissor(
    world, entity, target_camera, texture, transform, draw_scale, uv_min, uv_max,
    color, layers, scissor, flags, radius, border,
  )
}

///|
pub fn render2d_push_ui_texture_slice_scissor(
  world : @ecs.World,
  entity : @core.Entity,
  target_camera : @core.Entity?,
  texture : @asset.Handle[@asset.Image],
  transform : @transform.Transform,
  draw_scale : @math.Vec2,
  color : @color.Color,
  layers : @sprite.RenderLayers,
  scissor : @math.Rect?,
  texture_slices : @math.Vec4,
  target_slices : @math.Vec4,
  repeat : @math.Vec4,
  atlas_rect : @math.Vec4,
) -> Unit {
  @sprite_render.render2d_push_ui_texture_slice_scissor(
    world, entity, target_camera, texture, transform, draw_scale, color, layers,
    scissor, texture_slices, target_slices, repeat, atlas_rect,
  )
}

///|
pub fn render2d_scene_cull_context_values(
  context : @sprite_render.SceneCullContext,
) -> (Float, Float, Float, Float, Float, Float) {
  @sprite_render.render2d_scene_cull_context_values(context)
}

///|
pub fn render2d_scene_item_visible(
  context : @sprite_render.SceneCullContext,
  x : Float,
  y : Float,
  radius : Float,
) -> Bool {
  @sprite_render.render2d_scene_item_visible(context, x, y, radius)
}

///|
pub fn render2d_upload_mesh_handle(mesh : @asset.Handle[@mesh.Mesh]) -> Int {
  @sprite_render.render2d_upload_mesh_handle(mesh)
}

///|
pub fn render2d_viewport_to_world_2d(
  world : @ecs.World,
  position : @math.Vec2,
) -> @math.Vec2? {
  @sprite_render.render2d_viewport_to_world_2d(world, position)
}

///|
pub fn render2d_camera_viewport_to_world_2d(
  viewport_position : @math.Vec2,
  camera : @sprite.Camera,
  projection : @sprite.OrthographicProjection,
  transform : @transform.Transform,
  viewport_size : @math.IVec2,
  scale_factor : Float,
) -> @math.Vec2? {
  @sprite_render.render2d_camera_viewport_to_world_2d(
    viewport_position, camera, projection, transform, viewport_size, scale_factor,
  )
}

///|
pub fn render2d_camera_world_to_viewport_2d(
  world_position : @math.Vec2,
  camera : @sprite.Camera,
  projection : @sprite.OrthographicProjection,
  transform : @transform.Transform,
  viewport_size : @math.IVec2,
  scale_factor : Float,
) -> @math.Vec2? {
  @sprite_render.render2d_camera_world_to_viewport_2d(
    world_position, camera, projection, transform, viewport_size, scale_factor,
  )
}
