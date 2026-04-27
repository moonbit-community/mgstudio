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
pub fn color_material_assets_or_abort() -> @asset.Assets[ColorMaterialAsset] {
  render2d_asset_store_or_abort()
}

///|
pub fn color_material_assets_mut_or_abort() -> @ecs.ResourceMut[
  @asset.Assets[ColorMaterialAsset],
] {
  render2d_asset_store_mut_or_abort()
}

///|
pub struct ColorMaterialAsset {
  color : Color
  alpha_mode : AlphaMode2d
  texture : @asset.Handle[@asset.Image]?
  uv_offset : @math.Vec2
  uv_scale : @math.Vec2
}

///|
pub(open) trait IntoColorMaterialAsset {
  into_color_material_asset(Self) -> ColorMaterialAsset
}

///|
pub fn ColorMaterialAsset::new(
  color : Color,
  alpha_mode : AlphaMode2d,
  texture? : @asset.Handle[@asset.Image]? = None,
  uv_offset? : @math.Vec2 = @math.Vec2::new(0.0F, 0.0F),
  uv_scale? : @math.Vec2 = @math.Vec2::new(1.0F, 1.0F),
) -> ColorMaterialAsset {
  ColorMaterialAsset::{ color, alpha_mode, texture, uv_offset, uv_scale }
}

///|
pub fn ColorMaterialAsset::from_color(color : Color) -> ColorMaterialAsset {
  ColorMaterialAsset::new(
    color,
    color_material_alpha_mode_for_color(color),
    texture=None,
    uv_offset=@math.Vec2::new(0.0F, 0.0F),
    uv_scale=@math.Vec2::new(1.0F, 1.0F),
  )
}

///|
pub fn ColorMaterialAsset::from_image(
  texture : @asset.Handle[@asset.Image],
) -> ColorMaterialAsset {
  ColorMaterialAsset::new(
    Color::white(),
    AlphaMode2d::Blend,
    texture=Some(texture),
    uv_offset=@math.Vec2::new(0.0F, 0.0F),
    uv_scale=@math.Vec2::new(1.0F, 1.0F),
  )
}

///|
pub impl IntoColorMaterialAsset for Color with into_color_material_asset(self) {
  ColorMaterialAsset::from_color(self)
}

///|
pub impl IntoColorMaterialAsset for @asset.Handle[@asset.Image] with into_color_material_asset(
  self,
) {
  ColorMaterialAsset::from_image(self)
}

///|
pub fn[S : IntoColorMaterialAsset] add_material(
  assets : @asset.Assets[ColorMaterialAsset],
  value : S,
) -> @asset.Handle[ColorMaterialAsset] {
  assets.add(value.into_color_material_asset())
}

///|
pub fn ColorMaterialAsset::with_alpha_mode(
  self : ColorMaterialAsset,
  alpha_mode : AlphaMode2d,
) -> ColorMaterialAsset {
  ColorMaterialAsset::{ ..self, alpha_mode, }
}

///|
pub fn ColorMaterialAsset::with_texture(
  self : ColorMaterialAsset,
  texture : @asset.Handle[@asset.Image],
) -> ColorMaterialAsset {
  ColorMaterialAsset::{ ..self, texture: Some(texture) }
}

///|
pub fn ColorMaterialAsset::with_uv_offset(
  self : ColorMaterialAsset,
  uv_offset : @math.Vec2,
) -> ColorMaterialAsset {
  ColorMaterialAsset::{ ..self, uv_offset, }
}

///|
pub fn ColorMaterialAsset::with_uv_scale(
  self : ColorMaterialAsset,
  uv_scale : @math.Vec2,
) -> ColorMaterialAsset {
  ColorMaterialAsset::{ ..self, uv_scale, }
}

///|
fn default_color_material_asset_handle() -> @asset.Handle[ColorMaterialAsset] {
  @asset.Handle::new(0)
}

///|
fn default_color_material_asset() -> ColorMaterialAsset {
  ColorMaterialAsset::new(
    Color::srgb(1.0F, 0.0F, 1.0F),
    AlphaMode2d::Blend,
    texture=None,
    uv_offset=@math.Vec2::new(0.0F, 0.0F),
    uv_scale=@math.Vec2::new(1.0F, 1.0F),
  )
}

///|
fn color_material_alpha_mode_for_color(color : Color) -> AlphaMode2d {
  if color.alpha() < 1.0F {
    AlphaMode2d::Blend
  } else {
    AlphaMode2d::Opaque
  }
}

///|
fn color_material_get(
  handle : @asset.Handle[ColorMaterialAsset],
) -> ColorMaterialAsset? {
  color_material_assets_or_abort().get(handle)
}

///|
pub struct ColorMaterial {
  handle : @asset.Handle[ColorMaterialAsset]
}

///|
fn color_material_add(
  color : Color,
  alpha_mode : AlphaMode2d,
  texture : @asset.Handle[@asset.Image]?,
  uv_offset : @math.Vec2,
  uv_scale : @math.Vec2,
) -> ColorMaterial {
  let handle = color_material_assets_mut_or_abort().modify(fn(assets) {
    assets.add(
      ColorMaterialAsset::new(
        color,
        alpha_mode,
        texture~,
        uv_offset~,
        uv_scale~,
      ),
    )
  })
  ColorMaterial::{ handle, }
}

///|
pub fn ColorMaterial::color(self : ColorMaterial) -> Color {
  match color_material_get(self.handle) {
    Some(mat) => mat.color
    None => Color::white()
  }
}

///|
pub fn ColorMaterial::with_alpha_mode(
  self : ColorMaterial,
  alpha_mode : AlphaMode2d,
) -> ColorMaterial {
  color_material_add(
    self.color(),
    alpha_mode,
    self.texture(),
    self.uv_offset(),
    self.uv_scale(),
  )
}

///|
pub fn ColorMaterial::alpha_mode(self : ColorMaterial) -> AlphaMode2d {
  match color_material_get(self.handle) {
    Some(mat) => mat.alpha_mode
    None => AlphaMode2d::Blend
  }
}

///|
pub fn ColorMaterial::texture(
  self : ColorMaterial,
) -> @asset.Handle[@asset.Image]? {
  match color_material_get(self.handle) {
    Some(mat) => mat.texture
    None => None
  }
}

///|
pub fn ColorMaterial::uv_offset(self : ColorMaterial) -> @math.Vec2 {
  match color_material_get(self.handle) {
    Some(mat) => mat.uv_offset
    None => @math.Vec2::new(0.0F, 0.0F)
  }
}

///|
pub fn ColorMaterial::uv_scale(self : ColorMaterial) -> @math.Vec2 {
  match color_material_get(self.handle) {
    Some(mat) => mat.uv_scale
    None => @math.Vec2::new(1.0F, 1.0F)
  }
}

///|
pub impl Default for ColorMaterial with default() {
  ColorMaterial::{ handle: default_color_material_asset_handle() }
}

///|
pub fn ColorMaterial::with_texture(
  self : ColorMaterial,
  texture : @asset.Handle[@asset.Image],
) -> ColorMaterial {
  color_material_add(
    self.color(),
    self.alpha_mode(),
    Some(texture),
    self.uv_offset(),
    self.uv_scale(),
  )
}

///|
pub fn ColorMaterial::with_uv_offset(
  self : ColorMaterial,
  uv_offset : @math.Vec2,
) -> ColorMaterial {
  color_material_add(
    self.color(),
    self.alpha_mode(),
    self.texture(),
    uv_offset,
    self.uv_scale(),
  )
}

///|
pub fn ColorMaterial::with_uv_scale(
  self : ColorMaterial,
  uv_scale : @math.Vec2,
) -> ColorMaterial {
  color_material_add(
    self.color(),
    self.alpha_mode(),
    self.texture(),
    self.uv_offset(),
    uv_scale,
  )
}

///|
fn material2d_color_material_uniform_bytes(
  color : Color,
  alpha_mode : AlphaMode2d,
  texture_enabled : Bool,
  uv_offset : @math.Vec2,
  uv_scale : @math.Vec2,
) -> Bytes {
  let texture_bit = if texture_enabled { 1U } else { 0U }
  let alpha_cutoff = mesh_alpha_cutoff(alpha_mode)
  let flags = texture_bit | material2d_alpha_mode_kind_bits(alpha_mode)
  material2d_u32le_pack([
    material2d_f32_bits(color.r),
    material2d_f32_bits(color.g),
    material2d_f32_bits(color.b),
    material2d_f32_bits(color.a),
    material2d_f32_bits(uv_scale.x),
    material2d_f32_bits(0.0F),
    material2d_f32_bits(0.0F),
    material2d_f32_bits(0.0F),
    material2d_f32_bits(0.0F),
    material2d_f32_bits(uv_scale.y),
    material2d_f32_bits(0.0F),
    material2d_f32_bits(0.0F),
    material2d_f32_bits(uv_offset.x),
    material2d_f32_bits(uv_offset.y),
    material2d_f32_bits(1.0F),
    material2d_f32_bits(0.0F),
    flags,
    material2d_f32_bits(alpha_cutoff),
    0U,
    0U,
  ])
}

///|
pub fn Material2dBindGroup::color_material(
  color : Color,
  alpha_mode : AlphaMode2d,
  texture? : @asset.Handle[@asset.Image]? = None,
  uv_offset? : @math.Vec2 = @math.Vec2::new(0.0F, 0.0F),
  uv_scale? : @math.Vec2 = @math.Vec2::new(1.0F, 1.0F),
) -> Material2dBindGroup {
  let bindings : Array[Material2dBinding] = [
    Material2dBinding::uniform(
      0,
      material2d_color_material_uniform_bytes(
        color,
        alpha_mode,
        texture is Some(_),
        uv_offset,
        uv_scale,
      ),
    ),
  ]
  bindings.push(Material2dBinding::texture(1, texture))
  bindings.push(Material2dBinding::sampler(2, texture))
  Material2dBindGroup::new(bindings)
}

///|
pub impl Material2d for ColorMaterial with alpha_mode(self) {
  ColorMaterial::alpha_mode(self)
}

///|
pub impl Material2d for ColorMaterial with bind_group(self) {
  Material2dBindGroup::color_material(
    ColorMaterial::color(self),
    ColorMaterial::alpha_mode(self),
    texture=ColorMaterial::texture(self),
    uv_offset=ColorMaterial::uv_offset(self),
    uv_scale=ColorMaterial::uv_scale(self),
  )
}

///|
pub impl Material2d for ColorMaterialAsset with alpha_mode(self) {
  self.alpha_mode
}

///|
pub impl Material2d for ColorMaterialAsset with bind_group(self) {
  Material2dBindGroup::color_material(
    self.color,
    self.alpha_mode,
    texture=self.texture,
    uv_offset=self.uv_offset,
    uv_scale=self.uv_scale,
  )
}

///|
fn color_material2d_pipeline_resource() -> Material2dPipeline[
  ColorMaterialAsset,
] {
  Material2dPipeline::new(
    Some(MESH2D_SHADER_PATH),
    Some("sprite_render/mesh2d/color_material.wgsl"),
  )
}

///|
fn init_default_color_material_asset(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  let world = app.world()
  let key : @ecs.ResourceKey[@asset.Assets[ColorMaterialAsset]] = @asset.assets_resource_key()
  if (try! world.get_resource_mut(key)) is Some(assets) {
    let handle = default_color_material_asset_handle()
    assets.modify(fn(value) {
      if !value.contains(handle) {
        value.insert(handle, default_color_material_asset()) |> ignore
      }
    })
  }
  app
}

///|
pub struct ColorMaterialPlugin {}

///|
pub fn ColorMaterialPlugin::default() -> ColorMaterialPlugin {
  ColorMaterialPlugin::{  }
}

///|
pub impl @app.Plugin for ColorMaterialPlugin with name(_self) {
  "mgstudio.sprite.ColorMaterialPlugin"
}

///|
pub impl @app.Plugin for ColorMaterialPlugin with build(_self, app) {
  let plugin : Material2dPlugin[ColorMaterialAsset] = Material2dPlugin::default()
    .with_asset_init(default_color_material_asset)
    .with_vertex_shader(MESH2D_SHADER_PATH)
    .with_fragment_shader("sprite_render/mesh2d/color_material.wgsl")
  init_default_color_material_asset(app.add_plugins(plugin))
}

///|
pub fn color_material_plugin(
  plugin : ColorMaterialPlugin,
) -> ColorMaterialPlugin {
  plugin
}

///|
pub fn MeshMaterial2d::from_color_material(
  material : ColorMaterial,
) -> MeshMaterial2d[ColorMaterialAsset] {
  MeshMaterial2d::{ handle: material.handle }
}

///|
pub fn MeshMaterial2d::to_color_material(
  self : MeshMaterial2d[ColorMaterialAsset],
) -> ColorMaterial {
  ColorMaterial::{ handle: self.handle }
}

///|
pub fn MeshMaterial2d::with_alpha_mode(
  self : MeshMaterial2d[ColorMaterialAsset],
  alpha_mode : AlphaMode2d,
) -> MeshMaterial2d[ColorMaterialAsset] {
  MeshMaterial2d::from_color_material(
    self.to_color_material().with_alpha_mode(alpha_mode),
  )
}

///|
pub fn MeshMaterial2d::with_texture(
  self : MeshMaterial2d[ColorMaterialAsset],
  texture : @asset.Handle[@asset.Image],
) -> MeshMaterial2d[ColorMaterialAsset] {
  MeshMaterial2d::from_color_material(
    self.to_color_material().with_texture(texture),
  )
}

///|
pub fn MeshMaterial2d::with_uv_offset(
  self : MeshMaterial2d[ColorMaterialAsset],
  uv_offset : @math.Vec2,
) -> MeshMaterial2d[ColorMaterialAsset] {
  MeshMaterial2d::from_color_material(
    self.to_color_material().with_uv_offset(uv_offset),
  )
}

///|
pub fn MeshMaterial2d::with_uv_scale(
  self : MeshMaterial2d[ColorMaterialAsset],
  uv_scale : @math.Vec2,
) -> MeshMaterial2d[ColorMaterialAsset] {
  MeshMaterial2d::from_color_material(
    self.to_color_material().with_uv_scale(uv_scale),
  )
}

///|
pub impl Material2d for MeshMaterial2d[ColorMaterialAsset] with alpha_mode(self) {
  self.to_color_material().alpha_mode()
}

///|
pub impl Material2d for MeshMaterial2d[ColorMaterialAsset] with bind_group(self) {
  self.to_color_material().bind_group()
}

///|
fn prepared_color_material_assets_for_tests(
  materials : Array[(@asset.Handle[ColorMaterialAsset], ColorMaterialAsset)],
) -> @asset.Assets[PreparedMaterial2d[ColorMaterialAsset]] {
  let prepared : @asset.Assets[PreparedMaterial2d[ColorMaterialAsset]] = @asset.Assets::new()
  let pipeline = color_material2d_pipeline_resource()
  for material_info in materials {
    let (handle, material) = material_info
    prepared.insert(
      PreparedMaterial2d::prepared_handle(handle),
      PreparedMaterial2d::from_material(handle, material, pipeline),
    )
    |> ignore
  }
  prepared
}
