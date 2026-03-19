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
struct CheckerMaterialAsset {
  color : @sprite.Color
  alpha_mode : @sprite.AlphaMode2d
}

///|
fn checker_material_asset(
  color : @sprite.Color,
  alpha_mode? : @sprite.AlphaMode2d = @sprite.AlphaMode2d::Blend,
) -> CheckerMaterialAsset {
  CheckerMaterialAsset::{ color, alpha_mode }
}

///|
pub impl @sprite.Material2d for CheckerMaterialAsset with alpha_mode(self) {
  self.alpha_mode
}

///|
pub impl @sprite.Material2d for CheckerMaterialAsset with bind_group(self) {
  @sprite.Material2dBindGroup::new(self.color)
}

///|
pub impl @sprite.Material2d for CheckerMaterialAsset with bind_group_data(self) {
  self.bind_group().bind_group_data(self.alpha_mode())
}

///|
fn checker_material_plugin() -> @app.Plugin[@ecs.World] {
  let plugin : @sprite.Material2dPlugin[CheckerMaterialAsset] = @sprite.Material2dPlugin::default()
    .with_vertex_shader("shaders/bevy_sprite_render/mesh2d/mesh2d.wgsl")
    .with_fragment_shader("shaders/custom/mesh2d_checker_material.wgsl")
  @sprite.material2d_plugin(plugin)
}

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_plugins([checker_material_plugin()])
  .add_systems(@app.Startup, @app.system(mesh2d_custom_material_setup))
  .run()
}

///|
fn mesh2d_custom_material_setup(world : @ecs.World) -> Unit {
  let handle : @asset.Handle[CheckerMaterialAsset] = @asset.Handle::new(1)
  let assets_key : @ecs.ResourceKey[@asset.Assets[CheckerMaterialAsset]] = @asset.assets_resource_key()
  guard (try! world.get_resource_ref_mut(assets_key, world.read_change_tick()))
    is Some(assets_ref) else {
    abort("missing CheckerMaterialAsset store")
  }
  assets_ref.val.insert(
    handle,
    checker_material_asset(@sprite.Color::srgb(0.15F, 0.8F, 1.0F)),
  )
  |> ignore

  let mesh = @sprite.Mesh2d::from_rectangle(
    @sprite.Rectangle::new(180.0F, 180.0F),
  )
  let entity = world.spawn_empty()
  let material_key : @ecs.ComponentKey[
    @sprite.MeshMaterial2d[CheckerMaterialAsset],
  ] = @sprite.MeshMaterial2d::component()
  let gpu_mesh = @sprite.GpuMesh2d::new(
    @sprite.render2d_upload_mesh_handle(mesh.mesh),
  )
  let transform = @math.Transform::identity()
  try! (world.set(entity, @sprite.ecs_key_mesh2d, mesh) |> ignore)
  try! (world.set(entity, @sprite.ecs_key_gpu_mesh2d, gpu_mesh) |> ignore)
  try! (world.set(entity, material_key, @sprite.MeshMaterial2d::new(handle))
  |> ignore)
  try! (world.set(entity, @math.ecs_key_transform, transform) |> ignore)
  try! (world.set(
    entity,
    @sprite.ecs_key_render_layers,
    @sprite.RenderLayers::default(),
  )
  |> ignore)
  try! (world.set(
    entity,
    @visibility.ecs_key_visibility,
    @visibility.Visibility::Inherited,
  )
  |> ignore)
  try! (world.set(
    entity,
    @visibility.ecs_key_inherited_visibility,
    @visibility.InheritedVisibility::new(true),
  )
  |> ignore)
  try! (world.set(
    entity,
    @visibility.ecs_key_view_visibility,
    @visibility.ViewVisibility::new(true),
  )
  |> ignore)

  @sprite.Camera2dBundle::new(
    @sprite.Camera::default(),
    @math.Transform::identity(),
  ).spawn(world)
  |> ignore
}
