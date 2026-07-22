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
// Bevy source: `bevy/crates/bevy_sprite_render/src/mesh2d/color_material.rs`.
pub struct ColorMaterial {
  color : @color.Color
  alpha_mode : @sprite_render_mesh2d_material.AlphaMode2d
  texture : @asset.Handle[@asset.Image]?
  uv_transform : @transform.Affine2
}

///|
pub impl @asset.Asset for ColorMaterial with fn asset_debug_name() {
  "mgstudio_sprite_render::ColorMaterial"
}

///|
pub impl @asset.Asset for ColorMaterial with fn asset_as_image(_self) {
  None
}

///|
let color_material_resource_keys : @asset.AssetResourceKeys[ColorMaterial] = @asset.register_asset_resource_keys(
  ColorMaterial::asset_debug_name(),
)

///|
pub impl @asset.Asset for ColorMaterial with fn asset_resource_keys() {
  color_material_resource_keys
}

///|
pub(open) trait IntoColorMaterial {
  fn into_color_material(Self) -> ColorMaterial
}

///|
pub fn ColorMaterial::new(
  color : @color.Color,
  alpha_mode : @sprite_render_mesh2d_material.AlphaMode2d,
  texture? : @asset.Handle[@asset.Image]? = None,
  uv_transform? : @transform.Affine2 = @transform.Affine2::identity(),
) -> ColorMaterial {
  { color, alpha_mode, texture, uv_transform }
}

///|
pub fn ColorMaterial::from_color(color : @color.Color) -> ColorMaterial {
  ColorMaterial::new(
    color,
    color_material_alpha_mode_for_color(color),
    texture=None,
    uv_transform=@transform.Affine2::identity(),
  )
}

///|
pub fn ColorMaterial::from_image(
  texture : @asset.Handle[@asset.Image],
) -> ColorMaterial {
  ColorMaterial::new(
    @color.Color::white(),
    Blend,
    texture=Some(texture),
    uv_transform=@transform.Affine2::identity(),
  )
}

///|
pub fn ColorMaterial::ColorMaterial() -> ColorMaterial {
  ColorMaterial::new(
    @color.Color::white(),
    Blend,
    texture=None,
    uv_transform=@transform.Affine2::identity(),
  )
}

///|
pub impl Default for ColorMaterial with fn default() {
  ColorMaterial()
}

///|
pub impl IntoColorMaterial for @color.Color with fn into_color_material(self) {
  ColorMaterial::from_color(self)
}

///|
pub impl IntoColorMaterial for @asset.Handle[@asset.Image] with fn into_color_material(
  self,
) {
  ColorMaterial::from_image(self)
}

///|
pub fn[S : IntoColorMaterial] add_material(
  assets : @asset.Assets[ColorMaterial],
  value : S,
) -> @asset.Handle[ColorMaterial] {
  assets.add(value.into_color_material())
}

///|
pub fn ColorMaterial::color(self : ColorMaterial) -> @color.Color {
  self.color
}

///|
pub fn ColorMaterial::alpha_mode(
  self : ColorMaterial,
) -> @sprite_render_mesh2d_material.AlphaMode2d {
  self.alpha_mode
}

///|
pub fn ColorMaterial::texture(
  self : ColorMaterial,
) -> @asset.Handle[@asset.Image]? {
  self.texture
}

///|
pub fn ColorMaterial::uv_transform(self : ColorMaterial) -> @transform.Affine2 {
  self.uv_transform
}

///|
pub fn ColorMaterial::with_alpha_mode(
  self : ColorMaterial,
  alpha_mode : @sprite_render_mesh2d_material.AlphaMode2d,
) -> ColorMaterial {
  { ..self, alpha_mode, }
}

///|
pub fn ColorMaterial::with_texture(
  self : ColorMaterial,
  texture : @asset.Handle[@asset.Image],
) -> ColorMaterial {
  { ..self, texture: Some(texture) }
}

///|
pub fn ColorMaterial::with_uv_transform(
  self : ColorMaterial,
  uv_transform : @transform.Affine2,
) -> ColorMaterial {
  { ..self, uv_transform, }
}

///|
fn default_color_material_handle() -> @asset.Handle[ColorMaterial] {
  @asset.Handle::new(0)
}

///|
fn default_color_material() -> ColorMaterial {
  ColorMaterial::new(
    @color.Color::srgb(1.0F, 0.0F, 1.0F),
    Blend,
    texture=None,
    uv_transform=@transform.Affine2::identity(),
  )
}

///|
fn color_material_alpha_mode_for_color(
  color : @color.Color,
) -> @sprite_render_mesh2d_material.AlphaMode2d {
  if color.alpha() < 1.0F {
    Blend
  } else {
    Opaque
  }
}

///|
fn color_material_uniform_bytes(
  color : @color.Color,
  alpha_mode : @sprite_render_mesh2d_material.AlphaMode2d,
  texture_enabled : Bool,
  uv_transform : @transform.Affine2,
) -> Bytes {
  let texture_bit = if texture_enabled { 1U } else { 0U }
  let alpha_cutoff = @sprite_render_mesh2d_material.mesh_alpha_cutoff(
    alpha_mode,
  )
  let flags = texture_bit |
    @sprite_render_mesh2d_material.material2d_alpha_mode_kind_bits(alpha_mode)
  @sprite_render_mesh2d_material.material2d_u32le_pack([
    @sprite_render_mesh2d_material.material2d_f32_bits(color.r),
    @sprite_render_mesh2d_material.material2d_f32_bits(color.g),
    @sprite_render_mesh2d_material.material2d_f32_bits(color.b),
    @sprite_render_mesh2d_material.material2d_f32_bits(color.a),
    @sprite_render_mesh2d_material.material2d_f32_bits(uv_transform.a),
    @sprite_render_mesh2d_material.material2d_f32_bits(uv_transform.b),
    @sprite_render_mesh2d_material.material2d_f32_bits(0.0F),
    @sprite_render_mesh2d_material.material2d_f32_bits(0.0F),
    @sprite_render_mesh2d_material.material2d_f32_bits(uv_transform.c),
    @sprite_render_mesh2d_material.material2d_f32_bits(uv_transform.d),
    @sprite_render_mesh2d_material.material2d_f32_bits(0.0F),
    @sprite_render_mesh2d_material.material2d_f32_bits(0.0F),
    @sprite_render_mesh2d_material.material2d_f32_bits(uv_transform.tx),
    @sprite_render_mesh2d_material.material2d_f32_bits(uv_transform.ty),
    @sprite_render_mesh2d_material.material2d_f32_bits(1.0F),
    @sprite_render_mesh2d_material.material2d_f32_bits(0.0F),
    flags,
    @sprite_render_mesh2d_material.material2d_f32_bits(alpha_cutoff),
    0U,
    0U,
  ])
}

///|
fn color_material_bind_group(
  color : @color.Color,
  alpha_mode : @sprite_render_mesh2d_material.AlphaMode2d,
  texture? : @asset.Handle[@asset.Image]? = None,
  uv_transform? : @transform.Affine2 = @transform.Affine2::identity(),
) -> @sprite_render_mesh2d_material.Material2dBindGroup {
  let bindings : Array[@sprite_render_mesh2d_material.Material2dBinding] = [
    @sprite_render_mesh2d_material.Material2dBinding::uniform(
      0,
      color_material_uniform_bytes(
        color,
        alpha_mode,
        texture is Some(_),
        uv_transform,
      ),
    ),
  ]
  bindings.push(
    @sprite_render_mesh2d_material.Material2dBinding::texture(1, texture),
  )
  bindings.push(
    @sprite_render_mesh2d_material.Material2dBinding::sampler(2, texture),
  )
  @sprite_render_mesh2d_material.Material2dBindGroup::new(bindings)
}

///|
pub impl @sprite_render_mesh2d_material.Material2d for ColorMaterial with fn alpha_mode(
  self,
) {
  self.alpha_mode
}

///|
pub impl @sprite_render_mesh2d_material.Material2d for ColorMaterial with fn material2d_debug_name() {
  "mgstudio_sprite_render::ColorMaterial"
}

///|
let color_material_material2d_keys : @sprite_render_mesh2d_material.Material2dKeys[
  ColorMaterial,
] = @sprite_render_mesh2d_material.register_material2d_keys(
  ColorMaterial::material2d_debug_name(),
)

///|
pub impl @sprite_render_mesh2d_material.Material2d for ColorMaterial with fn material2d_keys() {
  color_material_material2d_keys
}

///|
pub impl @sprite_render_mesh2d_material.Material2d for ColorMaterial with fn bind_group(
  self,
) {
  color_material_bind_group(
    self.color,
    self.alpha_mode,
    texture=self.texture,
    uv_transform=self.uv_transform,
  )
}

///|
pub impl @sprite_render_mesh2d_material.Material2d for ColorMaterial with fn specialize(
  descriptor,
  layout,
  key,
) {
  layout |> ignore
  key |> ignore
  descriptor
}

///|
fn color_material2d_pipeline_resource() -> @sprite_render_mesh2d_material.Material2dPipeline[
  ColorMaterial,
] {
  @sprite_render_mesh2d_material.Material2dPipeline::new(
    Some("sprite_render/mesh2d/mesh2d.wgsl"),
    Some("sprite_render/mesh2d/color_material.wgsl"),
  )
}

///|
fn init_default_color_material(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  let world = app.world()
  let key : @ecs.ResourceKey[@asset.Assets[ColorMaterial]] = @asset.assets_resource_key()
  if world.get_resource_mut(key) is Some(assets) {
    let handle = default_color_material_handle()
    assets.modify(fn(value) {
      if !value.contains(handle) {
        value.insert(handle, default_color_material()) |> ignore
      }
    })
  }
  app
}

///|
pub struct ColorMaterialPlugin {}

///|
#warnings("-unnecessary_annotation")
pub fn ColorMaterialPlugin::ColorMaterialPlugin() -> ColorMaterialPlugin {
  ColorMaterialPlugin::{  }
}

///|
pub impl @app.Plugin for ColorMaterialPlugin with fn name(_self) {
  "mgstudio.sprite_render.mesh2d.ColorMaterialPlugin"
}

///|
pub impl @app.Plugin for ColorMaterialPlugin with fn build(_self, app) {
  let plugin : @sprite_render_mesh2d_material.Material2dPlugin[ColorMaterial] = @sprite_render_mesh2d_material.Material2dPlugin::Material2dPlugin()
    .with_asset_init(default_color_material)
    .with_vertex_shader("sprite_render/mesh2d/mesh2d.wgsl")
    .with_fragment_shader("sprite_render/mesh2d/color_material.wgsl")
  init_default_color_material(app.add_plugins(plugin))
}

///|
pub fn color_material_plugin(
  plugin : ColorMaterialPlugin,
) -> ColorMaterialPlugin {
  plugin
}

///|
pub fn prepared_color_materials_for_tests(
  materials : Array[(@asset.Handle[ColorMaterial], ColorMaterial)],
) -> @render.RenderAssets[
  @sprite_render_mesh2d_material.PreparedMaterial2d[ColorMaterial],
] {
  let prepared : @render.RenderAssets[
    @sprite_render_mesh2d_material.PreparedMaterial2d[ColorMaterial],
  ] = @render.RenderAssets::new()
  let pipeline = color_material2d_pipeline_resource()
  for material_info in materials {
    let (handle, material) = material_info
    prepared.insert(
      handle.id(),
      @sprite_render_mesh2d_material.PreparedMaterial2d::from_material(
        handle, material, pipeline,
      ),
    )
  }
  prepared
}

///|
let color_material_mesh_material2d_key : @ecs.ComponentKey[
  @sprite_render_mesh2d_material.MeshMaterial2d[ColorMaterial],
] = ColorMaterial::material2d_keys().mesh_material2d_component

///|
pub fn color_material_mesh_material2d_component() -> @ecs.ComponentKey[
  @sprite_render_mesh2d_material.MeshMaterial2d[ColorMaterial],
] {
  color_material_mesh_material2d_key
}
