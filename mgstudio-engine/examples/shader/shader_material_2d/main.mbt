// Copyright 2026 International Digital Economy Academy
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
struct CustomMaterial {
  color : @sprite.Color
  color_texture : @asset.Handle[@asset.Image]?
  alpha_mode : @sprite.AlphaMode2d
}

///|
impl @asset.Asset for CustomMaterial with fn asset_debug_name() {
  "examples.shader.shader_material_2d.CustomMaterial"
}

///|
impl @asset.Asset for CustomMaterial with fn asset_as_image(_self) {
  None
}

///|
let custom_material_resource_keys : @asset.AssetResourceKeys[CustomMaterial] = @asset.register_asset_resource_keys(
  CustomMaterial::asset_debug_name(),
)

///|
impl @asset.Asset for CustomMaterial with fn asset_resource_keys() {
  custom_material_resource_keys
}

///|
fn custom_material(
  color : @sprite.Color,
  color_texture : @asset.Handle[@asset.Image]?,
  alpha_mode? : @sprite.AlphaMode2d = @sprite.AlphaMode2d::Mask(0.5F),
) -> CustomMaterial {
  CustomMaterial::{ color, color_texture, alpha_mode }
}

///|
fn f32_bits(x : Float) -> UInt {
  x.reinterpret_as_uint()
}

///|
fn alpha_mode_flag(alpha_mode : @sprite.AlphaMode2d) -> UInt {
  match alpha_mode {
    Opaque => 0U
    Mask(_) => 0x40000000U
    Blend => 0x80000000U
  }
}

///|
fn alpha_cutoff(alpha_mode : @sprite.AlphaMode2d) -> Float {
  match alpha_mode {
    Mask(cutoff) => cutoff
    _ => 0.5F
  }
}

///|
fn custom_material_uniform_bytes(material : CustomMaterial) -> Bytes {
  let flags = alpha_mode_flag(material.alpha_mode) | 1U
  let words : Array[UInt] = [
    f32_bits(material.color.r),
    f32_bits(material.color.g),
    f32_bits(material.color.b),
    f32_bits(material.color.a),
    flags,
    f32_bits(alpha_cutoff(material.alpha_mode)),
    0U,
    0U,
  ]
  Bytes::makei(words.length() * 4, i => {
    let word = words[i / 4]
    let shift = i % 4 * 8
    ((word >> shift) & 0xFFU).reinterpret_as_int().to_byte()
  })
}

///|
pub impl @sprite.Material2d for CustomMaterial with fn alpha_mode(self) {
  self.alpha_mode
}

///|
pub impl @sprite.Material2d for CustomMaterial with fn material2d_debug_name() {
  "examples.shader.shader_material_2d.CustomMaterial"
}

///|
let custom_material_material2d_keys : @sprite.Material2dKeys[CustomMaterial] = @sprite.register_material2d_keys(
  CustomMaterial::material2d_debug_name(),
)

///|
pub impl @sprite.Material2d for CustomMaterial with fn material2d_keys() {
  custom_material_material2d_keys
}

///|
pub impl @sprite.Material2d for CustomMaterial with fn bind_group(self) {
  let texture = match self.color_texture {
    Some(texture) => texture
    None => @asset.asset_transparent_texture()
  }
  @sprite.Material2dBindGroup::new([
    @sprite.Material2dBinding::uniform(0, custom_material_uniform_bytes(self)),
    @sprite.Material2dBinding::texture(1, Some(texture)),
    @sprite.Material2dBinding::sampler(2, Some(texture)),
  ])
}

///|
fn shader_material_2d_plugin() -> @sprite.Material2dPlugin[CustomMaterial] {
  let plugin : @sprite.Material2dPlugin[CustomMaterial] = @sprite.Material2dPlugin::Material2dPlugin()
    .with_asset_init(fn() { custom_material(@sprite.Color::white(), None) })
    .with_vertex_shader("sprite_render/mesh2d/mesh2d.wgsl")
    .with_fragment_shader("shaders/custom_material_2d.wgsl")
  @sprite.material2d_plugin(plugin)
}

///|
fn setup(
  commands : @app.Commands,
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[CustomMaterial]],
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  ignore(
    commands.spawn((@sprite.Camera2d::Camera2d(), @sprite.Camera::Camera())),
  )

  let mesh = meshes
    .peek()
    .add(
      @sprite.mesh2d_geometry_rectangle(@sprite.Rectangle::Rectangle()).to_mesh(),
    )
  let material = materials
    .peek()
    .add(
      custom_material(
        @sprite.Color::srgb(0.0F, 0.0F, 1.0F),
        Some(asset_server.get().load_image("branding/icon.png")),
      ),
    )

  ignore(
    commands.spawn(
      (
        @mesh.Mesh2d::new(mesh),
        @sprite.MeshMaterial2d::new(material),
        @transform.Transform::identity().with_scale(@math.Vec3::splat(128.0F)),
      ),
    ),
  )
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
  .add_plugins(shader_material_2d_plugin())
  .add_systems(@app.Startup, @app.system_config_param4(setup))
  .run()
}
