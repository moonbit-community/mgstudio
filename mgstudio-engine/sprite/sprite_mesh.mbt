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
// Bevy source: `bevy/crates/bevy_sprite/src/sprite_mesh.rs`.
// Mesh asset and shape conversion surface split out of `render2d.mbt`.

///|
type AlphaMode2d = @sprite_render_mesh2d_material.AlphaMode2d

///|
type Material2dBinding = @sprite_render_mesh2d_material.Material2dBinding

///|
type Material2dBindGroup = @sprite_render_mesh2d_material.Material2dBindGroup

///|
type Material2dKeys[M] = @sprite_render_mesh2d_material.Material2dKeys[M]

///|
type Material2dPlugin[M] = @sprite_render_mesh2d_material.Material2dPlugin[M]

///|
type MeshMaterial2d[M] = @sprite_render_mesh2d_material.MeshMaterial2d[M]

///|
type Mesh2d = @mesh.Mesh2d

///|
type RenderLayers = @camera_render_layers.RenderLayers

///|
fn[M] register_material2d_keys(
  material_debug_name : String,
) -> Material2dKeys[M] {
  @sprite_render_mesh2d_material.register_material2d_keys(material_debug_name)
}

///|
fn material2d_u32le_pack(xs : Array[UInt]) -> Bytes {
  @sprite_render_mesh2d_material.material2d_u32le_pack(xs)
}

///|
fn material2d_f32_bits(x : Float) -> UInt {
  @sprite_render_mesh2d_material.material2d_f32_bits(x)
}

///|
fn material2d_alpha_mode_kind_bits(alpha_mode : AlphaMode2d) -> UInt {
  @sprite_render_mesh2d_material.material2d_alpha_mode_kind_bits(alpha_mode)
}

///|
fn mesh_alpha_cutoff(alpha_mode : AlphaMode2d) -> Float {
  @sprite_render_mesh2d_material.mesh_alpha_cutoff(alpha_mode)
}

///|
pub(all) enum SpriteAlphaMode {
  Opaque
  Mask(Float)
  Blend
} derive(Eq, Debug)

///|
pub fn SpriteAlphaMode::default() -> SpriteAlphaMode {
  SpriteAlphaMode::Mask(0.5F)
}

///|
pub(all) struct SpriteMesh {
  mut image : @asset.Handle[@asset.Image]
  mut texture_atlas : @asset.TextureAtlas?
  mut color : @color.Color
  mut flip_x : Bool
  mut flip_y : Bool
  mut custom_size : @math.Vec2?
  mut rect : @math.Rect?
  mut image_mode : SpriteImageMode
  mut alpha_mode : SpriteAlphaMode
}

///|
pub struct SpriteMaterial {
  image : @asset.Handle[@asset.Image]
  texture_atlas : @asset.TextureAtlas?
  color : @color.Color
  flip_x : Bool
  flip_y : Bool
  custom_size : @math.Vec2?
  rect : @math.Rect?
  image_mode : SpriteImageMode
  alpha_mode : AlphaMode2d
  anchor : @math.Vec2
  texture_atlas_layout : @asset.TextureAtlasLayout?
  texture_atlas_index : Int
}

///|
pub impl @asset.Asset for SpriteMaterial with fn asset_debug_name() {
  "mgstudio_sprite::SpriteMaterial"
}

///|
pub impl @asset.Asset for SpriteMaterial with fn asset_as_image(_self) {
  None
}

///|
let sprite_material_asset_resource_keys : @asset.AssetResourceKeys[
  SpriteMaterial,
] = @asset.register_asset_resource_keys(SpriteMaterial::asset_debug_name())

///|
pub impl @asset.Asset for SpriteMaterial with fn asset_resource_keys() {
  sprite_material_asset_resource_keys
}

///|
fn sprite_alpha_mode_to_alpha_mode2d(
  alpha_mode : SpriteAlphaMode,
) -> AlphaMode2d {
  match alpha_mode {
    SpriteAlphaMode::Opaque => AlphaMode2d::Opaque
    SpriteAlphaMode::Mask(cutoff) => AlphaMode2d::Mask(cutoff)
    SpriteAlphaMode::Blend => AlphaMode2d::Blend
  }
}

///|
pub fn SpriteMaterial::SpriteMaterial() -> SpriteMaterial {
  SpriteMaterial::{
    image: @asset.Handle::new(0),
    texture_atlas: None,
    color: @color.Color::white(),
    flip_x: false,
    flip_y: false,
    custom_size: None,
    rect: None,
    image_mode: SpriteImageMode::Auto,
    alpha_mode: AlphaMode2d::Blend,
    anchor: @math.Vec2::zero(),
    texture_atlas_layout: None,
    texture_atlas_index: 0,
  }
}

///|
pub fn SpriteMaterial::from_sprite_mesh(sprite : SpriteMesh) -> SpriteMaterial {
  SpriteMaterial::{
    image: sprite.image,
    texture_atlas: sprite.texture_atlas,
    color: sprite.color,
    flip_x: sprite.flip_x,
    flip_y: sprite.flip_y,
    custom_size: sprite.custom_size,
    rect: sprite.rect,
    image_mode: sprite.image_mode,
    alpha_mode: sprite_alpha_mode_to_alpha_mode2d(sprite.alpha_mode),
    anchor: @math.Vec2::zero(),
    texture_atlas_layout: None,
    texture_atlas_index: 0,
  }
}

///|
pub fn SpriteMaterial::with_anchor(
  self : SpriteMaterial,
  anchor : @math.Vec2,
) -> SpriteMaterial {
  SpriteMaterial::{ ..self, anchor, }
}

///|
pub fn SpriteMaterial::with_texture_atlas_layout(
  self : SpriteMaterial,
  texture_atlas_layout : @asset.TextureAtlasLayout?,
  texture_atlas_index : Int,
) -> SpriteMaterial {
  SpriteMaterial::{ ..self, texture_atlas_layout, texture_atlas_index }
}

///|
pub struct SpriteMaterialPlugin {}

///|
pub fn SpriteMaterialPlugin::SpriteMaterialPlugin() -> SpriteMaterialPlugin {
  SpriteMaterialPlugin::{  }
}

///|
pub struct SpriteMeshPlugin {}

///|
pub fn SpriteMeshPlugin::SpriteMeshPlugin() -> SpriteMeshPlugin {
  SpriteMeshPlugin::{  }
}

///|
priv struct SpriteMeshQuad {
  mut handle : @asset.Handle[@mesh.Mesh]?
}

///|
fn SpriteMeshQuad::SpriteMeshQuad() -> SpriteMeshQuad {
  SpriteMeshQuad::{ handle: None }
}

///|
priv struct SpriteMeshMaterialCache {
  handles : @hashmap.HashMap[String, @asset.Handle[SpriteMaterial]]
}

///|
fn SpriteMeshMaterialCache::SpriteMeshMaterialCache() -> SpriteMeshMaterialCache {
  SpriteMeshMaterialCache::{ handles: @hashmap.HashMap([]) }
}

///|
let ecs_key_sprite_mesh_quad : @ecs.ResourceKey[SpriteMeshQuad] = @ecs.register_resource(
  debug_name="mgstudio_sprite_render::SpriteMeshQuad",
)

///|
let ecs_key_sprite_mesh_material_cache : @ecs.ResourceKey[
  SpriteMeshMaterialCache,
] = @ecs.register_resource(
  debug_name="mgstudio_sprite_render::SpriteMeshMaterialCache",
)

///|
impl @app.Resource for SpriteMeshQuad with fn resource() {
  ecs_key_sprite_mesh_quad
}

///|
impl @app.Resource for SpriteMeshMaterialCache with fn resource() {
  ecs_key_sprite_mesh_material_cache
}

///|
pub fn SpriteMesh::SpriteMesh() -> SpriteMesh {
  SpriteMesh::from_image(@asset.Handle::new(0))
}

///|
pub fn SpriteMesh::from_image(
  image : @asset.Handle[@asset.Image],
) -> SpriteMesh {
  SpriteMesh::{
    image,
    texture_atlas: None,
    color: @color.Color::white(),
    flip_x: false,
    flip_y: false,
    custom_size: None,
    rect: None,
    image_mode: SpriteImageMode::Auto,
    alpha_mode: SpriteAlphaMode::default(),
  }
}

///|
pub fn SpriteMesh::sized(custom_size : @math.Vec2) -> SpriteMesh {
  SpriteMesh::{ ..SpriteMesh(), custom_size: Some(custom_size) }
}

///|
pub fn SpriteMesh::from_atlas_image(
  image : @asset.Handle[@asset.Image],
  atlas : @asset.TextureAtlas,
) -> SpriteMesh {
  SpriteMesh::{ ..SpriteMesh::from_image(image), texture_atlas: Some(atlas) }
}

///|
pub fn SpriteMesh::from_color(
  color : @color.Color,
  size : @math.Vec2,
) -> SpriteMesh {
  SpriteMesh::{ ..SpriteMesh(), color, custom_size: Some(size) }
}

///|
pub fn SpriteMesh::with_texture_atlas(
  self : SpriteMesh,
  texture_atlas : @asset.TextureAtlas?,
) -> SpriteMesh {
  SpriteMesh::{ ..self, texture_atlas, }
}

///|
pub fn SpriteMesh::with_color(
  self : SpriteMesh,
  color : @color.Color,
) -> SpriteMesh {
  SpriteMesh::{ ..self, color, }
}

///|
pub fn SpriteMesh::with_flip_x(self : SpriteMesh, flip_x : Bool) -> SpriteMesh {
  SpriteMesh::{ ..self, flip_x, }
}

///|
pub fn SpriteMesh::with_flip_y(self : SpriteMesh, flip_y : Bool) -> SpriteMesh {
  SpriteMesh::{ ..self, flip_y, }
}

///|
pub fn SpriteMesh::with_custom_size(
  self : SpriteMesh,
  custom_size : @math.Vec2?,
) -> SpriteMesh {
  SpriteMesh::{ ..self, custom_size, }
}

///|
pub fn SpriteMesh::with_rect(
  self : SpriteMesh,
  rect : @math.Rect?,
) -> SpriteMesh {
  SpriteMesh::{ ..self, rect, }
}

///|
pub fn SpriteMesh::with_image_mode(
  self : SpriteMesh,
  image_mode : SpriteImageMode,
) -> SpriteMesh {
  SpriteMesh::{ ..self, image_mode, }
}

///|
pub fn SpriteMesh::with_alpha_mode(
  self : SpriteMesh,
  alpha_mode : SpriteAlphaMode,
) -> SpriteMesh {
  SpriteMesh::{ ..self, alpha_mode, }
}

///|
pub fn SpriteMesh::compute_pixel_space_point(
  self : SpriteMesh,
  point_relative_to_sprite : @math.Vec2,
  anchor : Anchor,
  images : @asset.Assets[@asset.Image],
  texture_atlases : @asset.Assets[@asset.TextureAtlasLayout],
) -> SpritePixelSpacePoint {
  images |> ignore
  sprite_compute_pixel_space_point(
    self.image,
    self.texture_atlas,
    self.rect,
    self.custom_size,
    self.flip_x,
    self.flip_y,
    point_relative_to_sprite,
    anchor,
    texture_atlases,
  )
}

///|
fn sprite_material_alpha_mode_key(alpha_mode : AlphaMode2d) -> String {
  match alpha_mode {
    AlphaMode2d::Opaque => "opaque"
    AlphaMode2d::Mask(cutoff) => "mask:\{cutoff.to_double().to_string()}"
    AlphaMode2d::Blend => "blend"
  }
}

///|
fn sprite_material_vec2_key(value : @math.Vec2) -> String {
  "\{value.x.to_double().to_string()},\{value.y.to_double().to_string()}"
}

///|
fn sprite_material_rect_key(value : @math.Rect?) -> String {
  match value {
    Some(rect) =>
      "\{sprite_material_vec2_key(rect.min())};\{sprite_material_vec2_key(rect.max())}"
    None => "none"
  }
}

///|
fn sprite_material_vec2_option_key(value : @math.Vec2?) -> String {
  match value {
    Some(value) => sprite_material_vec2_key(value)
    None => "none"
  }
}

///|
fn sprite_material_image_mode_key(value : SpriteImageMode) -> String {
  match value {
    SpriteImageMode::Auto => "auto"
    SpriteImageMode::Scale(mode) => {
      let mode_key = match mode {
        SpriteScalingMode::FillCenter => "fill_center"
        SpriteScalingMode::FillStart => "fill_start"
        SpriteScalingMode::FillEnd => "fill_end"
        SpriteScalingMode::FitCenter => "fit_center"
        SpriteScalingMode::FitStart => "fit_start"
        SpriteScalingMode::FitEnd => "fit_end"
      }
      "scale:\{mode_key}"
    }
    SpriteImageMode::Sliced(_) => "sliced"
    SpriteImageMode::Tiled(tiling) =>
      "tiled:\{tiling.tile_x.to_string()}:\{tiling.tile_y.to_string()}:\{tiling.stretch_value.to_double().to_string()}"
  }
}

///|
fn sprite_mesh_material_cache_key(
  sprite : SpriteMesh,
  anchor : Anchor,
) -> String {
  let atlas_key = match sprite.texture_atlas {
    Some(atlas) => atlas.to_json().stringify()
    None => "none"
  }
  [
    sprite.image.id().to_string(),
    atlas_key,
    sprite.color.to_json().stringify(),
    sprite.flip_x.to_string(),
    sprite.flip_y.to_string(),
    sprite_material_vec2_option_key(sprite.custom_size),
    sprite_material_rect_key(sprite.rect),
    sprite_material_image_mode_key(sprite.image_mode),
    sprite_material_alpha_mode_key(
      sprite_alpha_mode_to_alpha_mode2d(sprite.alpha_mode),
    ),
    sprite_material_vec2_key(anchor.as_vec()),
  ].join("|")
}

///|
fn sprite_material_flags(material : SpriteMaterial) -> UInt {
  let mut flags = material2d_alpha_mode_kind_bits(material.alpha_mode)
  if material.flip_x {
    flags = flags | 1U
  }
  if material.flip_y {
    flags = flags | 2U
  }
  if material.image_mode is SpriteImageMode::Tiled(tiling) {
    if tiling.tile_x {
      flags = flags | 4U
    }
    if tiling.tile_y {
      flags = flags | 8U
    }
  }
  flags
}

///|
priv struct SpriteUvTransform {
  mut scale : @math.Vec2
  mut offset : @math.Vec2
}

///|
fn SpriteUvTransform::identity() -> SpriteUvTransform {
  SpriteUvTransform::{
    scale: @math.Vec2::new(1.0F, 1.0F),
    offset: @math.Vec2::zero(),
  }
}

///|
fn SpriteUvTransform::append_scale(
  self : SpriteUvTransform,
  scale : @math.Vec2,
) -> Unit {
  self.scale = @math.Vec2::new(self.scale.x * scale.x, self.scale.y * scale.y)
}

///|
fn SpriteUvTransform::append_translation(
  self : SpriteUvTransform,
  translation : @math.Vec2,
) -> Unit {
  self.offset = @math.Vec2::new(
    self.offset.x + self.scale.x * translation.x,
    self.offset.y + self.scale.y * translation.y,
  )
}

///|
fn sprite_material_vec2_mul(a : @math.Vec2, b : @math.Vec2) -> @math.Vec2 {
  @math.Vec2::new(a.x * b.x, a.y * b.y)
}

///|
fn sprite_material_vec2_div(a : @math.Vec2, b : @math.Vec2) -> @math.Vec2 {
  @math.Vec2::new(a.x / b.x, a.y / b.y)
}

///|
fn sprite_material_vec2_one() -> @math.Vec2 {
  @math.Vec2::new(1.0F, 1.0F)
}

///|
fn sprite_material_rect_from_atlas(
  layout : @asset.TextureAtlasLayout,
  index : Int,
) -> @math.Rect? {
  let clamped = if index < 0 {
    0
  } else if index >= layout.len() {
    layout.len() - 1
  } else {
    index
  }
  match layout.texture(clamped) {
    Some(rect) => Some(rect.as_rect())
    None => None
  }
}

///|
fn sprite_material_apply_sub_rect(
  transform : SpriteUvTransform,
  rect : @math.Rect,
  image_size : @math.Vec2,
) -> @math.Vec2 {
  let rect_size = rect.size()
  let ratio = sprite_material_vec2_div(rect_size, image_size)
  transform.append_scale(ratio)
  transform.append_translation(sprite_material_vec2_div(rect.min(), rect_size))
  rect_size
}

///|
fn sprite_material_image_size(material : SpriteMaterial) -> @math.Vec2 {
  @math.Vec2::new(
    Float::from_int(@asset.asset_texture_width(material.image).max(1)),
    Float::from_int(@asset.asset_texture_height(material.image).max(1)),
  )
}

///|
fn sprite_material_uniform_bytes(material : SpriteMaterial) -> Bytes {
  let mut flags = sprite_material_flags(material)
  let mut image_size = sprite_material_image_size(material)
  let mut quad_size = image_size
  let mut quad_offset = @math.Vec2::zero()
  let uv_transform = SpriteUvTransform::identity()

  if material.texture_atlas_layout is Some(layout) {
    match
      sprite_material_rect_from_atlas(layout, material.texture_atlas_index) {
      Some(rect) => {
        let rect_size = sprite_material_apply_sub_rect(
          uv_transform, rect, image_size,
        )
        quad_size = rect_size
        image_size = rect_size
      }
      None => ()
    }
  }

  if material.rect is Some(rect) {
    let rect_size = sprite_material_apply_sub_rect(
      uv_transform, rect, image_size,
    )
    quad_size = rect_size
    image_size = rect_size
  }

  let mut tile_stretch_value = @math.Vec2::zero()
  let mut scale = @math.Vec2::zero()
  let mut min_inset = @math.Vec2::zero()
  let mut max_inset = @math.Vec2::zero()
  let mut side_stretch_value = @math.Vec2::zero()
  let mut center_stretch_value = @math.Vec2::zero()

  if material.custom_size is Some(custom_size) {
    match material.image_mode {
      SpriteImageMode::Auto => quad_size = custom_size
      SpriteImageMode::Scale(scaling_mode) => {
        let quad_ratio = quad_size.x / quad_size.y
        let custom_ratio = custom_size.x / custom_size.y
        let fill_size = fn() {
          if quad_ratio > custom_ratio {
            @math.Vec2::new(custom_size.y * quad_ratio, custom_size.y)
          } else {
            @math.Vec2::new(custom_size.x, custom_size.x / quad_ratio)
          }
        }
        let fit_size = fn() {
          if quad_ratio > custom_ratio {
            @math.Vec2::new(custom_size.x, custom_size.x / quad_ratio)
          } else {
            @math.Vec2::new(custom_size.y * quad_ratio, custom_size.y)
          }
        }
        match scaling_mode {
          SpriteScalingMode::FillCenter => {
            let fill_size = fill_size()
            uv_transform.append_scale(
              sprite_material_vec2_div(custom_size, fill_size),
            )
            uv_transform.append_translation(
              sprite_material_vec2_div(
                fill_size.sub(custom_size).mul_scalar(0.5F),
                custom_size,
              ),
            )
            quad_size = custom_size
          }
          SpriteScalingMode::FillStart => {
            let fill_size = fill_size()
            uv_transform.append_scale(
              sprite_material_vec2_div(custom_size, fill_size),
            )
            quad_size = custom_size
          }
          SpriteScalingMode::FillEnd => {
            let fill_size = fill_size()
            uv_transform.append_scale(
              sprite_material_vec2_div(custom_size, fill_size),
            )
            uv_transform.append_translation(
              sprite_material_vec2_div(fill_size.sub(custom_size), custom_size),
            )
            quad_size = custom_size
          }
          SpriteScalingMode::FitCenter => quad_size = fit_size()
          SpriteScalingMode::FitStart => {
            let fit_size = fit_size()
            quad_offset = quad_offset.sub(
              custom_size.sub(fit_size).mul_scalar(0.5F),
            )
            quad_size = fit_size
          }
          SpriteScalingMode::FitEnd => {
            let fit_size = fit_size()
            quad_offset = quad_offset.add(
              custom_size.sub(fit_size).mul_scalar(0.5F),
            )
            quad_size = fit_size
          }
        }
      }
      SpriteImageMode::Tiled(tiling) => {
        if tiling.tile_x {
          flags = flags | 4U
        }
        if tiling.tile_y {
          flags = flags | 8U
        }
        tile_stretch_value = sprite_material_vec2_div(
          image_size.mul_scalar(tiling.stretch_value),
          custom_size,
        )
        quad_size = custom_size
      }
      SpriteImageMode::Sliced(slicer) => {
        let quad_ratio = quad_size.x / quad_size.y
        let custom_ratio = custom_size.x / custom_size.y
        if quad_ratio > custom_ratio {
          scale = @math.Vec2::new(1.0F, quad_ratio / custom_ratio)
        } else {
          scale = @math.Vec2::new(custom_ratio / quad_ratio, 1.0F)
        }

        min_inset = sprite_material_vec2_div(
          @math.Vec2::new(slicer.border.left, slicer.border.top),
          quad_size,
        )
        max_inset = sprite_material_vec2_div(
          @math.Vec2::new(slicer.border.right, slicer.border.bottom),
          quad_size,
        )

        let corner_scale = slicer.max_corner_scale
          .max(0.00000011920929F)
          .min(1.0F)
        scale = scale.div_scalar(corner_scale)
        let one = sprite_material_vec2_one()
        let numerator = sprite_material_vec2_mul(
          image_size,
          one.sub(max_inset).sub(min_inset),
        )
        let denominator = sprite_material_vec2_mul(
          custom_size,
          one
          .sub(sprite_material_vec2_div(max_inset, scale))
          .sub(sprite_material_vec2_div(min_inset, scale)),
        )

        match slicer.sides_scale_mode {
          SliceScaleMode::Tile(stretch_value) =>
            side_stretch_value = sprite_material_vec2_div(
              numerator.mul_scalar(stretch_value),
              denominator,
            )
          SliceScaleMode::Stretch => ()
        }
        match slicer.center_scale_mode {
          SliceScaleMode::Tile(stretch_value) =>
            center_stretch_value = sprite_material_vec2_div(
              numerator.mul_scalar(stretch_value),
              denominator,
            )
          SliceScaleMode::Stretch => ()
        }
        quad_size = custom_size
      }
    }
  }

  quad_offset = quad_offset.sub(
    @math.Vec2::new(
      quad_size.x * material.anchor.x,
      quad_size.y * material.anchor.y,
    ),
  )

  material2d_u32le_pack([
    material2d_f32_bits(material.color.r),
    material2d_f32_bits(material.color.g),
    material2d_f32_bits(material.color.b),
    material2d_f32_bits(material.color.a),
    flags,
    material2d_f32_bits(mesh_alpha_cutoff(material.alpha_mode)),
    material2d_f32_bits(quad_size.x),
    material2d_f32_bits(quad_size.y),
    material2d_f32_bits(quad_offset.x),
    material2d_f32_bits(quad_offset.y),
    0U,
    0U,
    material2d_f32_bits(uv_transform.scale.x),
    0U,
    0U,
    0U,
    0U,
    material2d_f32_bits(uv_transform.scale.y),
    0U,
    0U,
    material2d_f32_bits(uv_transform.offset.x),
    material2d_f32_bits(uv_transform.offset.y),
    material2d_f32_bits(1.0F),
    0U,
    material2d_f32_bits(tile_stretch_value.x),
    material2d_f32_bits(tile_stretch_value.y),
    material2d_f32_bits(scale.x),
    material2d_f32_bits(scale.y),
    material2d_f32_bits(min_inset.x),
    material2d_f32_bits(min_inset.y),
    material2d_f32_bits(max_inset.x),
    material2d_f32_bits(max_inset.y),
    material2d_f32_bits(side_stretch_value.x),
    material2d_f32_bits(side_stretch_value.y),
    material2d_f32_bits(center_stretch_value.x),
    material2d_f32_bits(center_stretch_value.y),
  ])
}

///|
fn sprite_material_bind_group(material : SpriteMaterial) -> Material2dBindGroup {
  Material2dBindGroup::new([
    Material2dBinding::uniform(0, sprite_material_uniform_bytes(material)),
    Material2dBinding::texture(1, Some(material.image)),
    Material2dBinding::sampler(2, Some(material.image)),
  ])
}

///|
pub impl @sprite_render_mesh2d_material.Material2d for SpriteMaterial with fn alpha_mode(
  self,
) {
  self.alpha_mode
}

///|
pub impl @sprite_render_mesh2d_material.Material2d for SpriteMaterial with fn material2d_debug_name() {
  "mgstudio_sprite::SpriteMaterial"
}

///|
let sprite_material_material2d_keys : Material2dKeys[SpriteMaterial] = register_material2d_keys(
  SpriteMaterial::material2d_debug_name(),
)

///|
pub impl @sprite_render_mesh2d_material.Material2d for SpriteMaterial with fn material2d_keys() {
  sprite_material_material2d_keys
}

///|
pub impl @sprite_render_mesh2d_material.Material2d for SpriteMaterial with fn bind_group(
  self,
) {
  sprite_material_bind_group(self)
}

///|
pub impl @app.Plugin for SpriteMaterialPlugin with fn name(_self) {
  "mgstudio.sprite_render.SpriteMaterialPlugin"
}

///|
pub impl @app.Plugin for SpriteMaterialPlugin with fn build(_self, app) {
  let plugin : Material2dPlugin[SpriteMaterial] = Material2dPlugin::Material2dPlugin()
    .with_asset_init(fn() { SpriteMaterial::SpriteMaterial() })
    .with_vertex_shader("sprite_render/sprite_mesh/sprite_material.wgsl")
    .with_fragment_shader("sprite_render/sprite_mesh/sprite_material.wgsl")
  app.add_plugins(plugin)
}

///|
fn sprite_mesh_quad_handle(world : @ecs.World) -> @asset.Handle[@mesh.Mesh] {
  let quad_mut = world.get_resource_mut(ecs_key_sprite_mesh_quad).unwrap()
  if quad_mut.peek().handle is Some(handle) {
    return handle
  }
  let assets_key : @ecs.ResourceKey[@asset.Assets[@mesh.Mesh]] = @asset.assets_resource_key()
  guard world.get_resource_mut(assets_key) is Some(meshes_ref) else {
    abort("SpriteMeshPlugin requires Assets<Mesh>")
  }
  let mesh = @mesh.Mesh::from_2d_geometry(
    @mesh_primitives.rectangle_to_mesh2d_geometry(
      @math.Rectangle::from_size(@math.Vec2::new(1.0F, 1.0F)),
    ),
  )
  let handle = meshes_ref.modify(fn(meshes) { meshes.add(mesh) })
  quad_mut.modify(fn(quad) { quad.handle = Some(handle) })
  handle
}

///|
fn sprite_mesh_add_mesh_system(world : @ecs.World) -> Unit {
  if world.component_count(ecs_key_sprite_mesh) == 0 {
    return
  }
  let quad = sprite_mesh_quad_handle(world)
  let tick = world.get_tick_context().ticks()
  let entities : Array[@core.Entity] = []
  for entity in world.added_components(ecs_key_sprite_mesh, tick).read() {
    entities.push(entity)
  }
  for entity in entities {
    try! world.set_by_key(entity, @mesh.ecs_key_mesh2d, @mesh.Mesh2d::new(quad))
  }
}

///|
fn sprite_material_with_atlas_layout(
  material : SpriteMaterial,
  texture_atlas : @asset.TextureAtlas?,
  texture_atlas_layouts : @asset.Assets[@asset.TextureAtlasLayout],
) -> SpriteMaterial {
  match texture_atlas {
    Some(atlas) =>
      match texture_atlas_layouts.get(atlas.layout()) {
        Some(layout) =>
          material.with_texture_atlas_layout(Some(layout), atlas.index())
        None => material
      }
    None => material
  }
}

///|
fn sprite_mesh_material_handle(
  world : @ecs.World,
  sprite : SpriteMesh,
  anchor : Anchor,
) -> @asset.Handle[SpriteMaterial] {
  let key = sprite_mesh_material_cache_key(sprite, anchor)
  let cache_mut = world
    .get_resource_mut(ecs_key_sprite_mesh_material_cache)
    .unwrap()
  if cache_mut.peek().handles.get(key) is Some(handle) {
    return handle
  }
  let assets_key : @ecs.ResourceKey[@asset.Assets[SpriteMaterial]] = @asset.assets_resource_key()
  let atlas_assets_key : @ecs.ResourceKey[
    @asset.Assets[@asset.TextureAtlasLayout],
  ] = @asset.assets_resource_key()
  guard world.get_resource_mut(assets_key) is Some(materials_ref) else {
    abort("SpriteMeshPlugin requires Assets<SpriteMaterial>")
  }
  let atlas_assets = world
    .get_resource(atlas_assets_key)
    .unwrap_or(@asset.Assets::new())
  let mut material = SpriteMaterial::from_sprite_mesh(sprite).with_anchor(
    anchor.as_vec(),
  )
  material = sprite_material_with_atlas_layout(
    material,
    sprite.texture_atlas,
    atlas_assets,
  )
  let handle = materials_ref.modify(fn(materials) { materials.add(material) })
  cache_mut.modify(fn(cache) { cache.handles.set(key, handle) })
  handle
}

///|
fn sprite_mesh_add_material_system(world : @ecs.World) -> Unit {
  if world.component_count(ecs_key_sprite_mesh) == 0 {
    return
  }
  let tick = world.get_tick_context().ticks()
  let changed : @hashset.HashSet[UInt64] = @hashset.HashSet([])
  for entity in world.added_components(ecs_key_sprite_mesh, tick).read() {
    sprite_insert_entity_key(changed, entity)
  }
  for entity in world.changed_components(ecs_key_sprite_mesh, tick).read() {
    sprite_insert_entity_key(changed, entity)
  }
  for entity in world.changed_components(ecs_key_anchor, tick).read() {
    sprite_insert_entity_key(changed, entity)
  }
  for entity in world.added_components(@mesh.ecs_key_mesh2d, tick).read() {
    sprite_insert_entity_key(changed, entity)
  }
  if changed.is_empty() {
    return
  }
  let material_key : @ecs.ComponentKey[MeshMaterial2d[SpriteMaterial]] = MeshMaterial2d::component()
  let query : @ecs.Query[(@ecs.Comp[SpriteMesh], @ecs.Comp[Anchor]), @ecs.All] = @ecs.query(
    world,
  )
  let updates : Array[(@core.Entity, SpriteMesh, Anchor)] = []
  try! query.view(fn(entity, data) {
    if !changed.contains(sprite_entity_key(entity)) {
      return
    }
    let (sprite_mesh_comp, anchor_comp) = data
    updates.push((entity, sprite_mesh_comp.value(), anchor_comp.value()))
  })
  for update in updates {
    let handle = sprite_mesh_material_handle(world, update.1, update.2)
    try! world.set_by_key(update.0, material_key, MeshMaterial2d::new(handle))
  }
}

///|
pub impl @app.Plugin for SpriteMeshPlugin with fn name(_self) {
  "mgstudio.sprite_render.SpriteMeshPlugin"
}

///|
pub impl @app.Plugin for SpriteMeshPlugin with fn build(_self, app) {
  app
  .add_plugins(SpriteMaterialPlugin::SpriteMaterialPlugin())
  .init_resource(fn() { SpriteMeshQuad::SpriteMeshQuad() })
  .init_resource(fn() { SpriteMeshMaterialCache::SpriteMeshMaterialCache() })
  .add_systems(
    @app.Update,
    (
      @app.system(sprite_mesh_add_mesh_system),
      @app.system(sprite_mesh_add_material_system),
    )
    |> @app.chain(),
  )
}

///|
fn render2d_current_world_or_abort() -> @ecs.World {
  match @app.current_world() {
    Some(world) => world
    None =>
      abort(
        "render2d asset helpers require an active app world; use the world-owned Assets<T> resources directly outside scheduled systems",
      )
  }
}

///|
fn[T : @asset.Asset] render2d_asset_store_or_abort() -> @asset.Assets[T] {
  let world = @render.render_source_world(render2d_current_world_or_abort())
  let key : @ecs.ResourceKey[@asset.Assets[T]] = @asset.assets_resource_key()
  match world.get_resource(key) {
    Some(assets) => assets
    None =>
      abort(
        "render2d asset resource is missing; SpriteRenderPlugin must initialize the required Assets<T> resource before use",
      )
  }
}

///|
fn[T : @asset.Asset] render2d_asset_store_mut_or_abort() -> @ecs.ResourceMut[
  @asset.Assets[T],
] {
  let world = @render.render_source_world(render2d_current_world_or_abort())
  let key : @ecs.ResourceKey[@asset.Assets[T]] = @asset.assets_resource_key()
  match world.get_resource_mut(key) {
    Some(assets) => assets
    None =>
      abort(
        "render2d asset resource is missing; SpriteRenderPlugin must initialize the required Assets<T> resource before use",
      )
  }
}

///|
pub fn mesh_assets_or_abort() -> @asset.Assets[@mesh.Mesh] {
  render2d_asset_store_or_abort()
}

///|
pub fn mesh_assets_mut_or_abort() -> @ecs.ResourceMut[@asset.Assets[@mesh.Mesh]] {
  render2d_asset_store_mut_or_abort()
}

///|
let mesh_upload_cache : @hashmap.HashMap[Int, Int] = @hashmap.HashMap([])

///|
let mesh_upload_radius_cache : @hashmap.HashMap[Int, Float] = @hashmap.HashMap([])

///|
fn mesh2d_geometry_base_radius(geometry : @mesh.Mesh2dGeometry) -> Float {
  let mut max_len_sq = 0.0F
  for position in geometry.positions {
    let len_sq = position.x * position.x + position.y * position.y
    if len_sq > max_len_sq {
      max_len_sq = len_sq
    }
  }
  if max_len_sq <= 0.0F {
    1.0F
  } else {
    @math.sqrt(max_len_sq)
  }
}

///|
fn mesh3d_geometry_base_radius(geometry : @mesh.Mesh3dGeometry) -> Float {
  let mut max_len_sq = 0.0F
  for index in 0..<geometry.vertex_count() {
    if geometry.vertex_position(index) is Some(position) {
      let len_sq = position.x * position.x + position.y * position.y
      if len_sq > max_len_sq {
        max_len_sq = len_sq
      }
    }
  }
  if max_len_sq <= 0.0F {
    1.0F
  } else {
    @math.sqrt(max_len_sq)
  }
}

///|
pub fn uploaded_mesh_base_radius(mesh_id : Int) -> Float {
  if mesh_id <= 0 {
    return 1.0F
  }
  if mesh_upload_radius_cache.get(mesh_id) is Some(radius) {
    radius
  } else {
    64.0F
  }
}

///|
fn mesh_upload_cache_sync_with_asset_events() -> Unit {
  let events = mesh_assets_mut_or_abort().modify(fn(assets) {
    assets.drain_events()
  })
  for event in events {
    match event {
      @asset.AssetEvent::Modified(handle) =>
        if mesh_upload_cache.get(handle.id()) is Some(mesh_id) {
          mesh_id |> ignore
          ignore(render2d_delete_uploaded_mesh_handle_id(handle.id()))
        }
      @asset.AssetEvent::Removed(handle) =>
        if mesh_upload_cache.get(handle.id()) is Some(_) {
          ignore(render2d_delete_uploaded_mesh_handle_id(handle.id()))
        }
      _ => ()
    }
  }
}

///|
pub fn render2d_delete_uploaded_mesh_handle_id(mesh_handle_id : Int) -> Bool {
  match mesh_upload_cache.get(mesh_handle_id) {
    Some(mesh_id) => {
      mesh_upload_cache.remove(mesh_handle_id)
      mesh_upload_radius_cache.remove(mesh_id)
      @render.host_gpu_delete_mesh(mesh_id~)
    }
    None => false
  }
}

///|
fn mesh_asset_add(mesh : @mesh.Mesh) -> @asset.Handle[@mesh.Mesh] {
  mesh_assets_mut_or_abort().modify(fn(assets) { assets.add(mesh) })
}

///|
fn mesh_asset_get(handle : @asset.Handle[@mesh.Mesh]) -> @mesh.Mesh? {
  mesh_assets_or_abort().get(handle)
}

///|
fn mesh_asset_set(
  handle : @asset.Handle[@mesh.Mesh],
  mesh : @mesh.Mesh,
) -> Bool {
  mesh_assets_mut_or_abort().modify(fn(assets) { assets.set(handle, mesh) })
}

///|
pub fn render_mesh_asset_add(mesh : @mesh.Mesh) -> @asset.Handle[@mesh.Mesh] {
  mesh_asset_add(mesh)
}

///|
pub fn render_mesh_asset_get(handle : @asset.Handle[@mesh.Mesh]) -> @mesh.Mesh? {
  mesh_asset_get(handle)
}

///|
pub fn render_mesh_asset_set(
  handle : @asset.Handle[@mesh.Mesh],
  mesh : @mesh.Mesh,
) -> Bool {
  mesh_asset_set(handle, mesh)
}

///|
fn render2d_upload_typed_mesh2d(mesh : @mesh.Mesh) -> Int {
  let layouts = @mesh.MeshVertexBufferLayouts::MeshVertexBufferLayouts()
  let mesh_vertex_layout = mesh.get_mesh_vertex_buffer_layout(layouts).layout()
  let indices = match mesh.indices() {
    Some(values) => values
    None => []
  }
  let primitive_topology = match mesh.primitive_topology() {
    Some(topology) => topology.to_int()
    None => 0
  }
  @render.host_gpu_create_mesh2d_vertex_buffer(
    vertex_bytes=mesh.create_packed_vertex_buffer_data(),
    vertex_count=mesh.count_vertices(),
    indices~,
    primitive_topology~,
    mesh_vertex_layout~,
  )
}

///|
pub fn render2d_upload_mesh_handle(mesh : @asset.Handle[@mesh.Mesh]) -> Int {
  mesh_upload_cache_sync_with_asset_events()
  let mesh_handle_id = mesh.id()
  if mesh_upload_cache.get(mesh_handle_id) is Some(mesh_id) {
    return mesh_id
  }
  let mut uploaded_mesh_radius = 1.0F
  let uploaded_mesh_id = match mesh_asset_get(mesh) {
    Some(mesh_asset) =>
      match mesh_asset.geometry {
        @mesh.MeshGeometry::Geometry2d(geometry2d) => {
          uploaded_mesh_radius = mesh2d_geometry_base_radius(geometry2d)
          render2d_upload_typed_mesh2d(mesh_asset)
        }
        @mesh.MeshGeometry::Geometry3d(geometry3d) => {
          uploaded_mesh_radius = mesh3d_geometry_base_radius(geometry3d)
          render2d_upload_typed_mesh2d(mesh_asset)
        }
      }
    None => {
      @window.host_debug_string(
        value="Mesh2d upload failed: mesh handle not found",
      )
      0
    }
  }
  if uploaded_mesh_id > 0 {
    mesh_upload_cache.set(mesh_handle_id, uploaded_mesh_id)
    mesh_upload_radius_cache.set(uploaded_mesh_id, uploaded_mesh_radius)
  }
  uploaded_mesh_id
}
