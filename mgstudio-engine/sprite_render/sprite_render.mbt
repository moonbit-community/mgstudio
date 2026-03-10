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
/// Runtime implementation currently lives in `Milky2018/mgstudio/sprite`.

///|
pub type AlphaMode2d = @sprite.AlphaMode2d

///|
pub type ColorMaterial = @sprite.ColorMaterial

///|
pub type ColorMaterialAsset = @sprite.ColorMaterialAsset

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
pub let camera_update_systems : @app.SystemSet = @sprite.camera_update_systems

///|
pub let render2d_set_extract : @app.SystemSet = @sprite.render2d_set_extract

///|
pub let render2d_set_prepare : @app.SystemSet = @sprite.render2d_set_prepare

///|
pub let render2d_set_queue : @app.SystemSet = @sprite.render2d_set_queue

///|
pub let render2d_set_render : @app.SystemSet = @sprite.render2d_set_render

///|
pub let render2d_set_execute : @app.SystemSet = @sprite.render2d_set_execute

///|
pub fn[W, M] material2d_plugin(plugin : Material2dPlugin[M]) -> @app.Plugin[W] {
  @sprite.material2d_plugin(plugin)
}

///|
pub fn sprite_render_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  @sprite.render2d_plugin(app)
}

///|
pub fn sprite_render_plugin_ecs(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  @sprite.render2d_plugin_ecs(app)
}

///|
pub fn wireframe2d_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  @sprite.wireframe2d_plugin(app)
}

///|
pub fn render_extract_system(world : @ecs.World) -> Unit {
  @sprite.render_extract_system(world)
}

///|
pub fn render_prepare_system(world : @ecs.World) -> Unit {
  @sprite.render_prepare_system(world)
}

///|
pub fn render_queue_system(world : @ecs.World) -> Unit {
  @sprite.render_queue_system(world)
}

///|
pub fn render_execute_system(world : @ecs.World) -> Unit {
  @sprite.render_execute_system(world)
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
pub fn render2d_diagnostic_prepared_camera_count() -> Int {
  @sprite.render2d_diagnostic_prepared_camera_count()
}

///|
pub fn render2d_diagnostic_queued_draw_item_count() -> Int {
  @sprite.render2d_diagnostic_queued_draw_item_count()
}

///|
pub fn render2d_prepared_camera_count(world : @ecs.World) -> Int? {
  @sprite.render2d_prepared_camera_count(world)
}

///|
pub fn render2d_queued_draw_item_count(world : @ecs.World) -> Int? {
  @sprite.render2d_queued_draw_item_count(world)
}

///|
pub fn render2d_viewport_to_world_2d(
  world : @ecs.World,
  screen : @math.Vec2,
) -> @math.Vec2? {
  @sprite.render2d_viewport_to_world_2d(world, screen)
}

///|
pub fn render2d_world_to_viewport(
  world : @ecs.World,
  world_position : @math.Vec2,
) -> @math.Vec2? {
  @sprite.render2d_world_to_viewport(world, world_position)
}
