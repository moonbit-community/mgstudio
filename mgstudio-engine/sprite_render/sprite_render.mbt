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
/// Sprite-render API boundary aligned with Bevy crate responsibilities.

///|
pub const SPRITE_RENDER_PLUGIN_ID : String = "bevy_sprite_render::SpriteRenderPlugin"

///|
pub type AlphaMode2d = @sprite.AlphaMode2d

///|
pub type ColorMaterial = @sprite.ColorMaterial

///|
pub type ColorMaterialAsset = @sprite.ColorMaterialAsset

///|
pub type ColorMaterialPlugin = @sprite.ColorMaterialPlugin

///|
pub type Material2dPlugin[M] = @sprite.Material2dPlugin[M]

///|
pub type Mesh2d = @sprite.Mesh2d

///|
pub type Mesh2dBundle = @sprite.Mesh2dBundle

///|
pub type MeshMaterial2d = @sprite.MeshMaterial2d

///|
pub type GpuMesh2d = @sprite.GpuMesh2d

///|
pub type Wireframe2d = @sprite.Wireframe2d

///|
pub type NoWireframe2d = @sprite.NoWireframe2d

///|
pub type Wireframe2dColor = @sprite.Wireframe2dColor

///|
pub type Wireframe2dConfig = @sprite.Wireframe2dConfig

///|
pub type TileData = @sprite.TileData

///|
pub type TilemapChunk = @sprite.TilemapChunk

///|
pub type TilemapChunkTileData = @sprite.TilemapChunkTileData

///|
pub let ecs_key_color_material : @ecs.ComponentKey[ColorMaterial] = @sprite.ecs_key_color_material

///|
pub let ecs_key_mesh2d : @ecs.ComponentKey[Mesh2d] = @sprite.ecs_key_mesh2d

///|
pub let ecs_key_mesh_material2d : @ecs.ComponentKey[MeshMaterial2d] = @sprite.ecs_key_mesh_material2d

///|
pub let ecs_key_gpu_mesh2d : @ecs.ComponentKey[GpuMesh2d] = @sprite.ecs_key_gpu_mesh2d

///|
pub let ecs_key_wireframe2d : @ecs.ComponentKey[Wireframe2d] = @sprite.ecs_key_wireframe2d

///|
pub let ecs_key_no_wireframe2d : @ecs.ComponentKey[NoWireframe2d] = @sprite.ecs_key_no_wireframe2d

///|
pub let ecs_key_wireframe2d_color : @ecs.ComponentKey[Wireframe2dColor] = @sprite.ecs_key_wireframe2d_color

///|
pub let ecs_key_wireframe2d_config : @ecs.ResourceKey[Wireframe2dConfig] = @sprite.ecs_key_wireframe2d_config

///|
pub type OverlaySpriteUvScissor = @sprite.OverlaySpriteUvScissor

///|
pub type UiCornerRadii = @sprite.UiCornerRadii

///|
pub type UiBorderRect = @sprite.UiBorderRect

///|
pub let render2d_set_extract : @app.SystemSet = @app.system_set(
  "bevy.render2d.extract",
)

///|
pub let render2d_set_prepare : @app.SystemSet = @app.system_set(
  "bevy.render2d.prepare",
)

///|
pub let render2d_set_queue : @app.SystemSet = @app.system_set(
  "bevy.render2d.queue",
)

///|
pub let render2d_set_render : @app.SystemSet = @app.system_set(
  "bevy.render2d.render",
)

///|
pub let render2d_set_execute : @app.SystemSet = render2d_set_render

///|
pub fn render2d_push_sprite_uv_scissor_batch(
  world : @ecs.World,
  sprites : Array[OverlaySpriteUvScissor],
) -> Unit {
  @sprite.render2d_push_sprite_uv_scissor_batch(world, sprites)
}

///|
pub fn render2d_clear_overlay_ui_rects(world : @ecs.World) -> Unit {
  @sprite.render2d_clear_overlay_ui_rects(world)
}

///|
pub fn render2d_clear_overlay_ui_box_shadows(world : @ecs.World) -> Unit {
  @sprite.render2d_clear_overlay_ui_box_shadows(world)
}

///|
pub fn render2d_clear_overlay_ui_texture_slices(world : @ecs.World) -> Unit {
  @sprite.render2d_clear_overlay_ui_texture_slices(world)
}

///|
pub fn render2d_push_ui_rect_uv_scissor(
  world : @ecs.World,
  entity : @core.Entity,
  target_camera : @core.Entity?,
  texture : @asset.Handle[@asset.Image],
  transform : @math.Transform,
  draw_scale : @math.Vec2,
  uv_min : @math.Vec2,
  uv_max : @math.Vec2,
  color : @sprite.Color,
  layers : @sprite.RenderLayers,
  scissor : @math.Rect?,
  flags : Int,
  radius : UiCornerRadii,
  border : UiBorderRect,
) -> Unit {
  @sprite.render2d_push_ui_rect_uv_scissor(
    world, entity, target_camera, texture, transform, draw_scale, uv_min, uv_max,
    color, layers, scissor, flags, radius, border,
  )
}

///|
pub fn render2d_push_ui_box_shadow_scissor(
  world : @ecs.World,
  entity : @core.Entity,
  target_camera : @core.Entity?,
  texture : @asset.Handle[@asset.Image],
  transform : @math.Transform,
  draw_scale : @math.Vec2,
  color : @sprite.Color,
  layers : @sprite.RenderLayers,
  scissor : @math.Rect?,
  size : @math.Vec2,
  radius : UiCornerRadii,
  blur : Float,
  samples : Int,
) -> Unit {
  @sprite.render2d_push_ui_box_shadow_scissor(
    world, entity, target_camera, texture, transform, draw_scale, color, layers,
    scissor, size, radius, blur, samples,
  )
}

///|
pub fn render2d_push_ui_texture_slice_scissor(
  world : @ecs.World,
  entity : @core.Entity,
  target_camera : @core.Entity?,
  texture : @asset.Handle[@asset.Image],
  transform : @math.Transform,
  draw_scale : @math.Vec2,
  color : @sprite.Color,
  layers : @sprite.RenderLayers,
  scissor : @math.Rect?,
  texture_slices : @math.Vec4,
  target_slices : @math.Vec4,
  repeat : @math.Vec4,
  atlas_rect : @math.Vec4,
) -> Unit {
  @sprite.render2d_push_ui_texture_slice_scissor(
    world, entity, target_camera, texture, transform, draw_scale, color, layers,
    scissor, texture_slices, target_slices, repeat, atlas_rect,
  )
}

///|
pub fn render2d_diagnostic_queued_draw_item_count() -> Int {
  @sprite.render2d_diagnostic_queued_draw_item_count()
}

///|
pub fn render2d_diagnostic_prepared_camera_count() -> Int {
  @sprite.render2d_diagnostic_prepared_camera_count()
}

///|
pub fn render2d_upload_mesh_handle(mesh : @asset.Handle[@mesh.Mesh]) -> Int {
  @sprite.render2d_upload_mesh_handle(mesh)
}

///|
pub fn render2d_draw_tilemap_chunk(
  world : @ecs.World,
  chunk : TilemapChunk,
  tile_data : TilemapChunkTileData,
  transform : @math.Transform,
  layers : @sprite.RenderLayers,
) -> Unit {
  @sprite.render2d_draw_tilemap_chunk(
    world, chunk, tile_data, transform, layers,
  )
}

///|
pub fn render2d_create_render_target(
  world : @ecs.World,
  width : Int,
  height : Int,
  nearest : Bool,
) -> @asset.Handle[@asset.Image] {
  @sprite.render2d_create_render_target(world, width, height, nearest)
}

///|
pub fn render2d_create_render_target_ecs(
  width : Int,
  height : Int,
  nearest : Bool,
) -> @asset.Handle[@asset.Image] {
  @sprite.render2d_create_render_target_ecs(width, height, nearest)
}

///|
pub fn render2d_viewport_to_world_2d(
  world : @ecs.World,
  screen : @math.Vec2,
) -> @math.Vec2? {
  @sprite.render2d_viewport_to_world_2d(world, screen)
}

///|
pub fn render2d_camera_viewport_to_world_2d(
  screen : @math.Vec2,
  camera : @sprite.Camera,
  projection : @sprite.OrthographicProjection,
  camera_transform : @math.Transform,
  target_size : @math.IVec2,
  scale_factor : Float,
) -> @math.Vec2? {
  @sprite.render2d_camera_viewport_to_world_2d(
    screen, camera, projection, camera_transform, target_size, scale_factor,
  )
}

///|
pub fn render2d_camera_world_to_viewport_2d(
  world : @math.Vec2,
  camera : @sprite.Camera,
  projection : @sprite.OrthographicProjection,
  camera_transform : @math.Transform,
  target_size : @math.IVec2,
  scale_factor : Float,
) -> @math.Vec2? {
  @sprite.render2d_camera_world_to_viewport_2d(
    world, camera, projection, camera_transform, target_size, scale_factor,
  )
}

///|
pub fn material2d_plugin(
  plugin : Material2dPlugin[ColorMaterial],
) -> @app.Plugin[@ecs.World] {
  @sprite.material2d_plugin(plugin)
}

///|
pub fn color_material_plugin(
  plugin : ColorMaterialPlugin,
) -> @app.Plugin[@ecs.World] {
  @sprite.color_material_plugin(plugin)
}

///|
pub fn sprite_render_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  @sprite.render2d_plugin(app)
}

///|
pub fn wireframe2d_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  @sprite.wireframe2d_plugin(app)
}

///|
pub fn render2d_plugin_ecs(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  @sprite.render2d_plugin_ecs(app)
}

///|
pub fn sprite_render_plugin_ecs(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  render2d_plugin_ecs(app)
}
