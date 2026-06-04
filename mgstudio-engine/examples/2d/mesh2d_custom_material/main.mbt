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
struct CustomMaterialAsset {
  color : @sprite.Color
  color_texture : @asset.Handle[@asset.Image]?
  alpha_mode : @sprite.AlphaMode2d
}

///|
impl @asset.Asset for CustomMaterialAsset with fn asset_debug_name() {
  "examples.2d.mesh2d_custom_material.CustomMaterialAsset"
}

///|
impl @asset.Asset for CustomMaterialAsset with fn asset_as_image(_self) {
  None
}

///|
let custom_material_asset_resource_keys : @asset.AssetResourceKeys[
  CustomMaterialAsset,
] = @asset.register_asset_resource_keys(CustomMaterialAsset::asset_debug_name())

///|
impl @asset.Asset for CustomMaterialAsset with fn asset_resource_keys() {
  custom_material_asset_resource_keys
}

///|
fn custom_material_asset(
  color : @sprite.Color,
  color_texture? : @asset.Handle[@asset.Image]? = None,
  alpha_mode? : @sprite.AlphaMode2d = @sprite.AlphaMode2d::Blend,
) -> CustomMaterialAsset {
  CustomMaterialAsset::{ color, color_texture, alpha_mode }
}

///|
fn custom_material_f32_bits(x : Float) -> UInt {
  x.reinterpret_as_uint()
}

///|
fn custom_material_uniform_bytes(color : @sprite.Color) -> Bytes {
  let words : Array[UInt] = [
    custom_material_f32_bits(color.r),
    custom_material_f32_bits(color.g),
    custom_material_f32_bits(color.b),
    custom_material_f32_bits(color.a),
  ]
  Bytes::makei(words.length() * 4, i => {
    let word = words[i / 4]
    let shift = i % 4 * 8
    ((word >> shift) & 0xFFU).reinterpret_as_int().to_byte()
  })
}

///|
pub impl @sprite.Material2d for CustomMaterialAsset with fn alpha_mode(self) {
  self.alpha_mode
}

///|
pub impl @sprite.Material2d for CustomMaterialAsset with fn material2d_debug_name() {
  "examples.2d.mesh2d_custom_material.CustomMaterialAsset"
}

///|
let custom_material_asset_material2d_keys : @sprite.Material2dKeys[
  CustomMaterialAsset,
] = @sprite.register_material2d_keys(
  CustomMaterialAsset::material2d_debug_name(),
)

///|
pub impl @sprite.Material2d for CustomMaterialAsset with fn material2d_keys() {
  custom_material_asset_material2d_keys
}

///|
pub impl @sprite.Material2d for CustomMaterialAsset with fn bind_group(self) {
  let texture = match self.color_texture {
    Some(texture) => texture
    None => @asset.asset_white_texture()
  }
  @sprite.Material2dBindGroup::new([
    @sprite.Material2dBinding::uniform(
      0,
      custom_material_uniform_bytes(self.color),
    ),
    @sprite.Material2dBinding::texture(1, Some(texture)),
    @sprite.Material2dBinding::sampler(2, Some(texture)),
  ])
}

///|
fn custom_material_plugin() -> @sprite.Material2dPlugin[CustomMaterialAsset] {
  let plugin : @sprite.Material2dPlugin[CustomMaterialAsset] = @sprite.Material2dPlugin::Material2dPlugin()
    .with_asset_init(fn() { custom_material_asset(@sprite.Color::white()) })
    .with_vertex_shader("sprite_render/mesh2d/mesh2d.wgsl")
    .with_fragment_shader("shaders/custom_material_2d.wgsl")
  @sprite.material2d_plugin(plugin)
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
  .add_plugins(custom_material_plugin())
  .add_systems(@app.Startup, @app.system(mesh2d_custom_material_setup))
  .run()
}

///|
fn mesh2d_custom_material_setup(world : @ecs.World) -> Unit {
  let handle : @asset.Handle[CustomMaterialAsset] = @asset.Handle::new(1)
  let assets_key : @ecs.ResourceKey[@asset.Assets[CustomMaterialAsset]] = @asset.assets_resource_key()
  guard world.get_resource_mut(assets_key) is Some(assets) else {
    abort("missing CustomMaterialAsset store")
  }
  assets.modify(fn(value) {
    ignore(
      value.insert(
        handle,
        custom_material_asset(@sprite.Color::srgb(0.15F, 0.8F, 1.0F)),
      ),
    )
  })

  let mesh = @sprite.Mesh2d::new(
    @sprite.mesh_assets_mut_or_abort()
    .peek()
    .add(
      @sprite.mesh2d_geometry_rectangle(@sprite.Rectangle::new(180.0F, 180.0F)).to_mesh(),
    ),
  )
  let entity = world.spawn_empty()
  let material_key : @ecs.ComponentKey[
    @sprite.MeshMaterial2d[CustomMaterialAsset],
  ] = @sprite.MeshMaterial2d::component()
  let transform = @transform.Transform::identity()
  try! (world.set_by_key(entity, @sprite.ecs_key_mesh2d, mesh) |> ignore)
  try! (world.set_by_key(
    entity,
    material_key,
    @sprite.MeshMaterial2d::new(handle),
  )
  |> ignore)
  try! (world.set_by_key(entity, @transform.ecs_key_transform, transform)
  |> ignore)
  try! (world.set_by_key(
    entity,
    @camera_render_layers.ecs_key_render_layers,
    @camera_render_layers.RenderLayers::RenderLayers(),
  )
  |> ignore)
  try! (world.set_by_key(
    entity,
    @visibility.ecs_key_visibility,
    @visibility.Visibility::Inherited,
  )
  |> ignore)
  try! (world.set_by_key(
    entity,
    @visibility.ecs_key_inherited_visibility,
    @visibility.InheritedVisibility::new(true),
  )
  |> ignore)
  try! (world.set_by_key(
    entity,
    @visibility.ecs_key_view_visibility,
    @visibility.ViewVisibility::new(true),
  )
  |> ignore)

  @sprite.Camera2dBundle::new(
    @sprite.Camera::Camera(),
    @transform.Transform::identity(),
  ).spawn(world)
  |> ignore
}
