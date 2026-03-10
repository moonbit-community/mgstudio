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
pub let camera_update_systems : @app.SystemSet = @app.system_set(
  "bevy.camera.update_systems",
)

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
pub fn[W, M] material2d_plugin(plugin : Material2dPlugin[M]) -> @app.Plugin[W] {
  @sprite.material2d_plugin(plugin)
}

///|
pub fn sprite_render_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  app
  .init_resource(fn() { @sprite.ClearColor::default() })
  .init_resource(fn() {
    let assets : @asset.Assets[ColorMaterialAsset] = @asset.Assets::new()
    assets
  })
  .init_resource(fn() {
    let assets : @asset.Assets[@mesh.Mesh] = @asset.Assets::new()
    assets
  })
  .add_startup_system(@sprite.init_render_state_system)
  .add_post_update_system_config(
    @app.system(render_camera_system).in_set(camera_update_systems),
  )
  .add_post_update_system_config(
    @app.system(render_extract_system).in_set(render2d_set_extract),
  )
  .add_post_update_system_config(
    @app.system(render_prepare_system).in_set(render2d_set_prepare),
  )
  .add_post_update_system_config(
    @app.system(render_queue_system).in_set(render2d_set_queue),
  )
  .add_post_update_system_config(
    @app.system(render_execute_system).in_set(render2d_set_render),
  )
  .configure_set(@app.PostUpdate, camera_update_systems, before=[
    render2d_set_extract,
  ])
  .configure_set(@app.PostUpdate, render2d_set_extract, before=[
    render2d_set_prepare,
  ])
  .configure_set(@app.PostUpdate, render2d_set_prepare, before=[
    render2d_set_queue,
  ])
  .configure_set(@app.PostUpdate, render2d_set_queue, before=[
    render2d_set_render,
  ])
}

///|
pub fn sprite_render_plugin_ecs(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  app
  .init_resource(fn() { @sprite.ClearColor::default() })
  .init_resource(fn() {
    let assets : @asset.Assets[ColorMaterialAsset] = @asset.Assets::new()
    assets
  })
  .init_resource(fn() {
    let assets : @asset.Assets[@mesh.Mesh] = @asset.Assets::new()
    assets
  })
  .add_startup_system(@sprite.init_render_state_system)
  .add_post_update_system_config(
    @app.system(render_camera_system_ecs).in_set(camera_update_systems),
  )
  .add_post_update_system_config(
    @app.system(render_extract_system_ecs).in_set(render2d_set_extract),
  )
  .add_post_update_system_config(
    @app.system(render_prepare_system).in_set(render2d_set_prepare),
  )
  .add_post_update_system_config(
    @app.system(render_queue_system).in_set(render2d_set_queue),
  )
  .add_post_update_system_config(
    @app.system(render_execute_system).in_set(render2d_set_render),
  )
  .configure_set(@app.PostUpdate, camera_update_systems, before=[
    render2d_set_extract,
  ])
  .configure_set(@app.PostUpdate, render2d_set_extract, before=[
    render2d_set_prepare,
  ])
  .configure_set(@app.PostUpdate, render2d_set_prepare, before=[
    render2d_set_queue,
  ])
  .configure_set(@app.PostUpdate, render2d_set_queue, before=[
    render2d_set_render,
  ])
}

///|
pub fn wireframe2d_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  @sprite.wireframe2d_plugin(app)
}

///|
pub fn render_camera_system(world : @ecs.World) -> Unit {
  @sprite.render2d_camera_system(world)
}

///|
pub fn render_camera_system_ecs(world : @ecs.World) -> Unit {
  @sprite.render2d_camera_system_ecs(world)
}

///|
pub fn render_extract_system(world : @ecs.World) -> Unit {
  @sprite.render_extract_system(world)
}

///|
pub fn render_extract_system_ecs(world : @ecs.World) -> Unit {
  @sprite.render_extract_system_ecs(world)
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
