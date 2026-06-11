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
pub type AlphaMode2d = @sprite_render_mesh2d_material.AlphaMode2d

///|
pub type ColorMaterial = @sprite_render_mesh2d_color_material.ColorMaterial

///|
pub type ColorMaterialPlugin = @sprite_render_mesh2d_color_material.ColorMaterialPlugin

///|
pub type Render2dPlugin = @sprite_render_render.Render2dPlugin

///|
pub type Render2dEcsPlugin = @sprite_render_render.Render2dEcsPlugin

///|
pub type SpriteMeshPlugin = @sprite_render_sprite_mesh.SpriteMeshPlugin

///|
pub type Material2dPlugin[M] = @sprite_render_mesh2d_material.Material2dPlugin[
  M,
]

///|
pub type Material2dKey[M] = @sprite_render_mesh2d_material.Material2dKey[M]

///|
pub type Material2dPipeline[M] = @sprite_render_mesh2d_material.Material2dPipeline[
  M,
]

///|
pub type Mesh2d = @mesh.Mesh2d

///|
pub type MeshMaterial2d[M] = @sprite_render_mesh2d_material.MeshMaterial2d[M]

///|
pub type Wireframe2d = @sprite_render_mesh2d_wireframe2d.Wireframe2d

///|
pub type NoWireframe2d = @sprite_render_mesh2d_wireframe2d.NoWireframe2d

///|
pub type Wireframe2dColor = @sprite_render_mesh2d_wireframe2d.Wireframe2dColor

///|
pub type Wireframe2dConfig = @sprite_render_mesh2d_wireframe2d.Wireframe2dConfig

///|
pub type Wireframe2dMaterial = @sprite_render_mesh2d_wireframe2d.Wireframe2dMaterial

///|
pub type Mesh2dWireframe = @sprite_render_mesh2d_wireframe2d.Mesh2dWireframe

///|
pub type Wireframe2dPlugin = @sprite_render_mesh2d_wireframe2d.Wireframe2dPlugin

///|
pub type TileData = @tilemap_chunk.TileData

///|
pub type TileOrientation = @tilemap_chunk.TileOrientation

///|
pub type TilemapChunk = @tilemap_chunk.TilemapChunk

///|
pub type TilemapChunkMaterial = @tilemap_chunk.TilemapChunkMaterial

///|
pub type TilemapChunkMaterialPlugin = @tilemap_chunk.TilemapChunkMaterialPlugin

///|
pub type TilemapChunkTileData = @tilemap_chunk.TilemapChunkTileData

///|
pub let ecs_key_mesh2d : @ecs.ComponentKey[Mesh2d] = @mesh.ecs_key_mesh2d

///|
pub let ecs_key_mesh_material2d : @ecs.ComponentKey[
  MeshMaterial2d[ColorMaterial],
] = @sprite_render_mesh2d_color_material.color_material_mesh_material2d_component()

///|
pub let ecs_key_wireframe2d : @ecs.ComponentKey[Wireframe2d] = @sprite_render_mesh2d_wireframe2d.ecs_key_wireframe2d

///|
pub let ecs_key_no_wireframe2d : @ecs.ComponentKey[NoWireframe2d] = @sprite_render_mesh2d_wireframe2d.ecs_key_no_wireframe2d

///|
pub let ecs_key_wireframe2d_color : @ecs.ComponentKey[Wireframe2dColor] = @sprite_render_mesh2d_wireframe2d.ecs_key_wireframe2d_color

///|
pub let ecs_key_wireframe2d_config : @ecs.ResourceKey[Wireframe2dConfig] = @sprite_render_mesh2d_wireframe2d.ecs_key_wireframe2d_config

///|
pub type OverlaySpriteUvScissor = @sprite_render_render.OverlaySpriteUvScissor

///|
pub type OverlaySpriteUvScissorSlices = @sprite_render_render.OverlaySpriteUvScissorSlices

///|
pub type BorderRect = @sprite_render_render.BorderRect

///|
pub type SceneCullContext = @sprite_render_render.SceneCullContext

///|
pub type CustomMesh2dPipelineDescriptor = @sprite_render_render.CustomMesh2dPipelineDescriptor

///|
pub type CustomMesh2dRuntimeRegistry = @sprite_render_render.CustomMesh2dRuntimeRegistry

///|
pub let render2d_set_extract : @app.SystemSet = @sprite_render_schedule.render2d_set_extract

///|
pub let render2d_set_extract_materials : @app.SystemSet = @sprite_render_schedule.render2d_set_extract_materials

///|
pub let render2d_set_prepare_materials : @app.SystemSet = @sprite_render_schedule.render2d_set_prepare_materials

///|
pub let render2d_set_prepare : @app.SystemSet = @sprite_render_schedule.render2d_set_prepare

///|
pub let render2d_set_queue : @app.SystemSet = @sprite_render_schedule.render2d_set_queue

///|
pub let render2d_set_transparent_2d : @app.SystemSet = @sprite_render_schedule.render2d_set_transparent_2d

///|
pub let render2d_set_render : @app.SystemSet = @sprite_render_schedule.render2d_set_render

///|
pub fn render2d_push_sprite_uv_scissor_batch(
  world : @ecs.World,
  sprites : Array[OverlaySpriteUvScissor],
) -> Unit {
  @sprite_render_render.render2d_push_sprite_uv_scissor_batch(world, sprites)
}

///|
pub fn render2d_push_sprite_uv_scissor_slices_batch(
  world : @ecs.World,
  sprite_batches : Array[OverlaySpriteUvScissorSlices],
) -> Unit {
  @sprite_render_render.render2d_push_sprite_uv_scissor_slices_batch(
    world, sprite_batches,
  )
}

///|
pub fn render2d_primary_scene_cull_context(
  world : @ecs.World,
) -> SceneCullContext? {
  @sprite_render_render.render2d_primary_scene_cull_context(world)
}

///|
pub fn render2d_scene_item_visible(
  context : SceneCullContext,
  x : Float,
  y : Float,
  radius : Float,
) -> Bool {
  @sprite_render_render.render2d_scene_item_visible(context, x, y, radius)
}

///|
pub fn render2d_scene_cull_context_values(
  context : SceneCullContext,
) -> (Float, Float, Float, Float, Float, Float) {
  context.values()
}

///|
pub fn render2d_diagnostic_queued_draw_item_count() -> Int {
  @sprite_render_render.render2d_diagnostic_queued_draw_item_count()
}

///|
pub fn render2d_diagnostic_prepared_camera_count() -> Int {
  @sprite_render_render.render2d_diagnostic_prepared_camera_count()
}

///|
pub fn render2d_diagnostic_queue_cpu_ms() -> Float {
  @sprite_render_render.render2d_diagnostic_queue_cpu_ms()
}

///|
pub fn render2d_diagnostic_execute_cpu_ms() -> Float {
  @sprite_render_render.render2d_diagnostic_execute_cpu_ms()
}

///|
pub fn init_render_state_system(world : @ecs.World) -> Unit {
  @sprite_render_render.init_render_state_system(world)
}

///|
pub fn render_extract_system(world : @ecs.World) -> Unit {
  @sprite_render_render.render_extract_system(world)
}

///|
pub fn render_extract_system_ecs(world : @ecs.World) -> Unit {
  @sprite_render_render.render_extract_system_ecs(world)
}

///|
pub fn render_prepare_system(world : @ecs.World) -> Unit {
  @sprite_render_render.render_prepare_system(world)
}

///|
pub fn render_queue_system(world : @ecs.World) -> Unit {
  @sprite_render_render.render_queue_system(world)
}

///|
pub fn render2d_prepared_camera_count(world : @ecs.World) -> Int? {
  @sprite_render_render.render2d_prepared_camera_count(world)
}

///|
pub fn render2d_queued_draw_item_count(world : @ecs.World) -> Int? {
  @sprite_render_render.render2d_queued_draw_item_count(world)
}

///|
pub fn[T] register_custom_mesh2d_pipeline_world(
  world : @ecs.World,
  type_name~ : String,
  component_key~ : @ecs.ComponentKey[T],
  descriptor~ : CustomMesh2dPipelineDescriptor,
) -> Unit {
  @sprite_render_render.register_custom_mesh2d_pipeline_world(
    world,
    type_name~,
    component_key~,
    descriptor~,
  )
}

///|
pub fn render2d_upload_mesh_handle(mesh : @asset.Handle[@mesh.Mesh]) -> Int {
  @sprite_render_render.render2d_upload_mesh_handle(mesh)
}

///|
pub fn render2d_create_render_target(
  world : @ecs.World,
  width : Int,
  height : Int,
  nearest : Bool,
) -> @asset.Handle[@asset.Image] {
  @sprite_render_render.render2d_create_render_target(
    world, width, height, nearest,
  )
}

///|
pub fn render2d_create_render_target_ecs(
  width : Int,
  height : Int,
  nearest : Bool,
) -> @asset.Handle[@asset.Image] {
  @sprite_render_render.render2d_create_render_target_ecs(
    width, height, nearest,
  )
}

///|
pub fn render2d_viewport_to_world_2d(
  world : @ecs.World,
  screen : @math.Vec2,
) -> @math.Vec2? {
  @sprite_render_render.render2d_viewport_to_world_2d(world, screen)
}

///|
pub fn[M] material2d_plugin(
  plugin : Material2dPlugin[M],
) -> Material2dPlugin[M] {
  @sprite_render_mesh2d_material.material2d_plugin(plugin)
}

///|
pub fn color_material_plugin(
  plugin : ColorMaterialPlugin,
) -> ColorMaterialPlugin {
  @sprite_render_mesh2d_color_material.color_material_plugin(plugin)
}

///|
