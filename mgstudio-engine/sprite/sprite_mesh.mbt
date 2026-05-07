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
  mut color : Color
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
  color : Color
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
pub fn SpriteMaterial::default() -> SpriteMaterial {
  SpriteMaterial::{
    image: @asset.Handle::new(0),
    texture_atlas: None,
    color: Color::white(),
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
pub fn SpriteMaterialPlugin::default() -> SpriteMaterialPlugin {
  SpriteMaterialPlugin::{  }
}

///|
pub struct SpriteMeshPlugin {}

///|
pub fn SpriteMeshPlugin::default() -> SpriteMeshPlugin {
  SpriteMeshPlugin::{  }
}

///|
priv struct SpriteMeshQuad {
  mut handle : @asset.Handle[@mesh.Mesh]?
}

///|
fn SpriteMeshQuad::default() -> SpriteMeshQuad {
  SpriteMeshQuad::{ handle: None }
}

///|
priv struct SpriteMeshMaterialCache {
  handles : @hashmap.HashMap[String, @asset.Handle[SpriteMaterial]]
}

///|
fn SpriteMeshMaterialCache::default() -> SpriteMeshMaterialCache {
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
impl @app.Resource for SpriteMeshQuad with resource() {
  ecs_key_sprite_mesh_quad
}

///|
impl @app.Resource for SpriteMeshMaterialCache with resource() {
  ecs_key_sprite_mesh_material_cache
}

///|
pub fn SpriteMesh::default() -> SpriteMesh {
  SpriteMesh::from_image(@asset.Handle::new(0))
}

///|
pub fn SpriteMesh::from_image(
  image : @asset.Handle[@asset.Image],
) -> SpriteMesh {
  SpriteMesh::{
    image,
    texture_atlas: None,
    color: Color::white(),
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
  SpriteMesh::{ ..SpriteMesh::default(), custom_size: Some(custom_size) }
}

///|
pub fn SpriteMesh::from_atlas_image(
  image : @asset.Handle[@asset.Image],
  atlas : @asset.TextureAtlas,
) -> SpriteMesh {
  SpriteMesh::{ ..SpriteMesh::from_image(image), texture_atlas: Some(atlas) }
}

///|
pub fn SpriteMesh::from_color(color : Color, size : @math.Vec2) -> SpriteMesh {
  SpriteMesh::{ ..SpriteMesh::default(), color, custom_size: Some(size) }
}

///|
pub fn SpriteMesh::with_texture_atlas(
  self : SpriteMesh,
  texture_atlas : @asset.TextureAtlas?,
) -> SpriteMesh {
  SpriteMesh::{ ..self, texture_atlas, }
}

///|
pub fn SpriteMesh::with_color(self : SpriteMesh, color : Color) -> SpriteMesh {
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
) -> Result[@math.Vec2, @math.Vec2] {
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
    Some(atlas) => atlas.to_json().to_string()
    None => "none"
  }
  [
    sprite.image.id().to_string(),
    atlas_key,
    sprite.color.to_json().to_string(),
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
pub fn Material2dBindGroup::sprite_material(
  material : SpriteMaterial,
) -> Material2dBindGroup {
  Material2dBindGroup::new([
    Material2dBinding::uniform(0, sprite_material_uniform_bytes(material)),
    Material2dBinding::texture(1, Some(material.image)),
    Material2dBinding::sampler(2, Some(material.image)),
  ])
}

///|
pub impl Material2d for SpriteMaterial with alpha_mode(self) {
  self.alpha_mode
}

///|
pub impl Material2d for SpriteMaterial with bind_group(self) {
  Material2dBindGroup::sprite_material(self)
}

///|
pub impl @app.Plugin for SpriteMaterialPlugin with name(_self) {
  "mgstudio.sprite_render.SpriteMaterialPlugin"
}

///|
pub impl @app.Plugin for SpriteMaterialPlugin with build(_self, app) {
  let plugin : Material2dPlugin[SpriteMaterial] = Material2dPlugin::default()
    .with_asset_init(fn() { SpriteMaterial::default() })
    .with_vertex_shader("sprite_render/sprite_mesh/sprite_material.wgsl")
    .with_fragment_shader("sprite_render/sprite_mesh/sprite_material.wgsl")
  app.add_plugins(plugin)
}

///|
fn sprite_mesh_quad_handle(world : @ecs.World) -> @asset.Handle[@mesh.Mesh] {
  let quad_ref = (try! world.get_resource_ref_mut(ecs_key_sprite_mesh_quad)).unwrap()
  if quad_ref.val.handle is Some(handle) {
    return handle
  }
  let assets_key : @ecs.ResourceKey[@asset.Assets[@mesh.Mesh]] = @asset.assets_resource_key()
  guard (try! world.get_resource_mut(assets_key)) is Some(meshes_ref) else {
    abort("SpriteMeshPlugin requires Assets<Mesh>")
  }
  meshes_ref.set_changed()
  let mesh = @mesh.Mesh::from_2d_geometry(
    mesh2d_geometry_rectangle(
      @math.Rectangle::from_size(@math.Vec2::new(1.0F, 1.0F)),
    ),
  )
  let handle = meshes_ref.peek().add(mesh)
  quad_ref.val.handle = Some(handle)
  handle
}

///|
fn sprite_mesh_add_mesh_system(world : @ecs.World) -> Unit {
  if world.component_count(ecs_key_sprite_mesh) == 0 {
    return
  }
  let quad = sprite_mesh_quad_handle(world)
  let sequence = world.get_sequence_context().sequence()
  let entities : Array[@core.Entity] = []
  for entity in world.added_components(ecs_key_sprite_mesh, sequence).read() {
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
  let cache_ref = (try! world.get_resource_ref_mut(
    ecs_key_sprite_mesh_material_cache,
  )).unwrap()
  if cache_ref.val.handles.get(key) is Some(handle) {
    return handle
  }
  let assets_key : @ecs.ResourceKey[@asset.Assets[SpriteMaterial]] = @asset.assets_resource_key()
  let atlas_assets_key : @ecs.ResourceKey[
    @asset.Assets[@asset.TextureAtlasLayout],
  ] = @asset.assets_resource_key()
  guard (try! world.get_resource_mut(assets_key)) is Some(materials_ref) else {
    abort("SpriteMeshPlugin requires Assets<SpriteMaterial>")
  }
  let atlas_assets = (try! world.get_resource(atlas_assets_key)).unwrap_or(
    @asset.Assets::new(),
  )
  let mut material = SpriteMaterial::from_sprite_mesh(sprite).with_anchor(
    anchor.as_vec(),
  )
  material = sprite_material_with_atlas_layout(
    material,
    sprite.texture_atlas,
    atlas_assets,
  )
  materials_ref.set_changed()
  let handle = materials_ref.peek().add(material)
  cache_ref.val.handles.set(key, handle)
  handle
}

///|
fn sprite_mesh_add_material_system(world : @ecs.World) -> Unit {
  if world.component_count(ecs_key_sprite_mesh) == 0 {
    return
  }
  let sequence = world.get_sequence_context().sequence()
  let changed : @hashset.HashSet[UInt64] = @hashset.HashSet([])
  for entity in world.added_components(ecs_key_sprite_mesh, sequence).read() {
    sprite_insert_entity_key(changed, entity)
  }
  for entity in world.changed_components(ecs_key_sprite_mesh, sequence).read() {
    sprite_insert_entity_key(changed, entity)
  }
  for entity in world.changed_components(ecs_key_anchor, sequence).read() {
    sprite_insert_entity_key(changed, entity)
  }
  for entity in world.added_components(@mesh.ecs_key_mesh2d, sequence).read() {
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
pub impl @app.Plugin for SpriteMeshPlugin with name(_self) {
  "mgstudio.sprite_render.SpriteMeshPlugin"
}

///|
pub impl @app.Plugin for SpriteMeshPlugin with build(_self, app) {
  app
  .add_plugins(SpriteMaterialPlugin::default())
  .init_resource(fn() { SpriteMeshQuad::default() })
  .init_resource(fn() { SpriteMeshMaterialCache::default() })
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
pub fn render2d_upload_mesh_handle(mesh : @asset.Handle[@mesh.Mesh]) -> Int {
  mesh_upload_cache_sync_with_asset_events()
  let mesh_handle_id = mesh.id()
  if mesh_upload_cache.val.get(mesh_handle_id) is Some(mesh_id) {
    return mesh_id
  }
  let mut uploaded_mesh_radius = 1.0F
  let uploaded_mesh_id = match mesh_asset_get(mesh) {
    Some(mesh_asset) =>
      match mesh_asset.geometry {
        @mesh.MeshGeometry::Geometry2d(geometry2d) => {
          uploaded_mesh_radius = mesh2d_geometry_base_radius(geometry2d)
          match geometry2d.encode_triangle_interleaved_xy_uv_rgba_csv() {
            Some(vertices_csv) =>
              @render.host_gpu_create_mesh_triangles_xyuvrgba(
                vertices_xyuvrgba_csv=vertices_csv,
              )
            None => {
              let message = match geometry2d.validate() {
                Some(err) =>
                  "Mesh2dGeometry validation failed: \{to_repr(err).to_string()}"
                None => "Mesh2dGeometry flatten failed"
              }
              @window.host_debug_string(value=message)
              0
            }
          }
        }
        @mesh.MeshGeometry::Geometry3d(geometry3d) => {
          uploaded_mesh_radius = 64.0F
          match mesh3d_geometry_flatten_vertices_f32(geometry3d) {
            Some(vertices_f32) =>
              @render.host_gpu_create_mesh3d_xyznuvrgba(
                vertices_xyznuvrgba=vertices_f32,
                primitive_topology=geometry3d.primitive_topology().to_int(),
              )
            None => {
              let message = match geometry3d.validate() {
                Some(err) =>
                  "Mesh3dGeometry validation failed: \{to_repr(err).to_string()}"
                None => "Mesh3dGeometry flatten failed"
              }
              @window.host_debug_string(value=message)
              0
            }
          }
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
    mesh_upload_cache.val.set(mesh_handle_id, uploaded_mesh_id)
    mesh_upload_radius_cache.val.set(uploaded_mesh_id, uploaded_mesh_radius)
  }
  uploaded_mesh_id
}

///|
pub(open) trait IntoSpriteRingMeshGeometry {
  into_sprite_ring_mesh_geometry(self : Self, inner_shape : Self) -> Mesh2dGeometry
}

///|
pub fn mesh2d_geometry_capsule(capsule : Capsule2d) -> Mesh2dGeometry {
  capsule_to_mesh2d_geometry(capsule)
}

///|
pub fn mesh2d_geometry_circular_sector(
  sector : CircularSector,
) -> Mesh2dGeometry {
  circular_sector_to_mesh2d_geometry(sector)
}

///|
pub fn mesh2d_geometry_circular_segment(
  segment : CircularSegment,
) -> Mesh2dGeometry {
  circular_segment_to_mesh2d_geometry(segment)
}

///|
pub fn mesh2d_geometry_circle(circle : Circle) -> Mesh2dGeometry {
  circle_to_mesh2d_geometry(circle)
}

///|
pub fn mesh2d_geometry_ellipse(ellipse : Ellipse) -> Mesh2dGeometry {
  ellipse_to_mesh2d_geometry(ellipse)
}

///|
pub fn mesh2d_geometry_annulus(annulus : Annulus) -> Mesh2dGeometry {
  annulus_to_mesh2d_geometry(annulus)
}

///|
pub fn mesh2d_geometry_ring(ring : Ring2d) -> Mesh2dGeometry {
  ring_to_mesh2d_geometry(ring)
}

///|
pub fn mesh2d_geometry_circular_sector_ring(
  ring : CircularSectorRing,
) -> Mesh2dGeometry {
  circular_sector_ring_to_mesh2d_geometry(ring)
}

///|
pub fn mesh2d_geometry_circular_segment_ring(
  ring : CircularSegmentRing,
) -> Mesh2dGeometry {
  circular_segment_ring_to_mesh2d_geometry(ring)
}

///|
pub fn mesh2d_geometry_ellipse_ring(ring : EllipseRing) -> Mesh2dGeometry {
  ellipse_ring_to_mesh2d_geometry(ring)
}

///|
pub fn mesh2d_geometry_capsule_ring(ring : Capsule2dRing) -> Mesh2dGeometry {
  capsule_ring_to_mesh2d_geometry(ring)
}

///|
pub fn mesh2d_geometry_rhombus_ring(ring : RhombusRing) -> Mesh2dGeometry {
  rhombus_ring_to_mesh2d_geometry(ring)
}

///|
pub fn mesh2d_geometry_rectangle_ring(ring : RectangleRing) -> Mesh2dGeometry {
  rectangle_ring_to_mesh2d_geometry(ring)
}

///|
pub fn mesh2d_geometry_regular_polygon_ring(
  ring : RegularPolygonRing,
) -> Mesh2dGeometry {
  regular_polygon_ring_to_mesh2d_geometry(ring)
}

///|
pub fn mesh2d_geometry_triangle_ring(ring : Triangle2dRing) -> Mesh2dGeometry {
  triangle_ring_to_mesh2d_geometry(ring)
}

///|
pub fn mesh2d_geometry_rhombus(rhombus : Rhombus) -> Mesh2dGeometry {
  rhombus_to_mesh2d_geometry(rhombus)
}

///|
pub fn mesh2d_geometry_regular_polygon(
  polygon : RegularPolygon,
) -> Mesh2dGeometry {
  regular_polygon_to_mesh2d_geometry(polygon)
}

///|
pub fn mesh2d_geometry_triangle(triangle : Triangle2d) -> Mesh2dGeometry {
  triangle_to_mesh2d_geometry(triangle)
}

///|
pub fn mesh2d_geometry_segment(segment : Segment2d) -> Mesh2dGeometry {
  segment_to_mesh2d_geometry(segment)
}

///|
pub fn mesh2d_geometry_polyline(polyline : Polyline2d) -> Mesh2dGeometry {
  polyline_to_mesh2d_geometry(polyline)
}

///|
pub fn mesh2d_geometry_rectangle(rectangle : Rectangle) -> Mesh2dGeometry {
  rectangle_to_mesh2d_geometry(rectangle)
}

///|
pub(open) trait IntoSpriteMeshAsset {
  into_sprite_mesh_asset(Self) -> @mesh.Mesh
}

///|
pub impl IntoSpriteRingMeshGeometry for Circle with into_sprite_ring_mesh_geometry(
  self,
  inner_shape,
) {
  generic_circle_ring_to_mesh2d_geometry(Ring::new(self, inner_shape))
}

///|
pub impl IntoSpriteRingMeshGeometry for CircularSector with into_sprite_ring_mesh_geometry(
  self,
  inner_shape,
) {
  generic_circular_sector_ring_to_mesh2d_geometry(Ring::new(self, inner_shape))
}

///|
pub impl IntoSpriteRingMeshGeometry for CircularSegment with into_sprite_ring_mesh_geometry(
  self,
  inner_shape,
) {
  generic_circular_segment_ring_to_mesh2d_geometry(Ring::new(self, inner_shape))
}

///|
pub impl IntoSpriteRingMeshGeometry for Ellipse with into_sprite_ring_mesh_geometry(
  self,
  inner_shape,
) {
  generic_ellipse_ring_to_mesh2d_geometry(Ring::new(self, inner_shape))
}

///|
pub impl IntoSpriteRingMeshGeometry for Capsule2d with into_sprite_ring_mesh_geometry(
  self,
  inner_shape,
) {
  generic_capsule_ring_to_mesh2d_geometry(Ring::new(self, inner_shape))
}

///|
pub impl IntoSpriteRingMeshGeometry for Rhombus with into_sprite_ring_mesh_geometry(
  self,
  inner_shape,
) {
  generic_rhombus_ring_to_mesh2d_geometry(Ring::new(self, inner_shape))
}

///|
pub impl IntoSpriteRingMeshGeometry for Rectangle with into_sprite_ring_mesh_geometry(
  self,
  inner_shape,
) {
  generic_rectangle_ring_to_mesh2d_geometry(Ring::new(self, inner_shape))
}

///|
pub impl IntoSpriteRingMeshGeometry for RegularPolygon with into_sprite_ring_mesh_geometry(
  self,
  inner_shape,
) {
  generic_regular_polygon_ring_to_mesh2d_geometry(Ring::new(self, inner_shape))
}

///|
pub impl IntoSpriteRingMeshGeometry for Triangle2d with into_sprite_ring_mesh_geometry(
  self,
  inner_shape,
) {
  generic_triangle_ring_to_mesh2d_geometry(Ring::new(self, inner_shape))
}

///|
pub fn[S : IntoSpriteMeshAsset] add_mesh(
  assets : @asset.Assets[@mesh.Mesh],
  value : S,
) -> @asset.Handle[@mesh.Mesh] {
  assets.add(value.into_sprite_mesh_asset())
}

///|
pub impl IntoSpriteMeshAsset for Mesh2dGeometry with into_sprite_mesh_asset(
  self,
) {
  self.to_mesh()
}

///|
pub impl IntoSpriteMeshAsset for Capsule2d with into_sprite_mesh_asset(self) {
  mesh2d_geometry_capsule(self).to_mesh()
}

///|
pub impl IntoSpriteMeshAsset for CircularSector with into_sprite_mesh_asset(
  self,
) {
  mesh2d_geometry_circular_sector(self).to_mesh()
}

///|
pub impl IntoSpriteMeshAsset for CircularSegment with into_sprite_mesh_asset(
  self,
) {
  mesh2d_geometry_circular_segment(self).to_mesh()
}

///|
pub impl IntoSpriteMeshAsset for Circle with into_sprite_mesh_asset(self) {
  mesh2d_geometry_circle(self).to_mesh()
}

///|
pub impl IntoSpriteMeshAsset for Ellipse with into_sprite_mesh_asset(self) {
  mesh2d_geometry_ellipse(self).to_mesh()
}

///|
pub impl IntoSpriteMeshAsset for Annulus with into_sprite_mesh_asset(self) {
  mesh2d_geometry_annulus(self).to_mesh()
}

///|
pub impl[P : IntoSpriteRingMeshGeometry] IntoSpriteMeshAsset for Ring[P] with into_sprite_mesh_asset(
  self,
) {
  self.outer_shape.into_sprite_ring_mesh_geometry(self.inner_shape).to_mesh()
}

///|
pub impl IntoSpriteMeshAsset for Ring2d with into_sprite_mesh_asset(self) {
  mesh2d_geometry_ring(self).to_mesh()
}

///|
pub impl IntoSpriteMeshAsset for CircularSectorRing with into_sprite_mesh_asset(
  self,
) {
  mesh2d_geometry_circular_sector_ring(self).to_mesh()
}

///|
pub impl IntoSpriteMeshAsset for CircularSegmentRing with into_sprite_mesh_asset(
  self,
) {
  mesh2d_geometry_circular_segment_ring(self).to_mesh()
}

///|
pub impl IntoSpriteMeshAsset for EllipseRing with into_sprite_mesh_asset(self) {
  mesh2d_geometry_ellipse_ring(self).to_mesh()
}

///|
pub impl IntoSpriteMeshAsset for Capsule2dRing with into_sprite_mesh_asset(self) {
  mesh2d_geometry_capsule_ring(self).to_mesh()
}

///|
pub impl IntoSpriteMeshAsset for RhombusRing with into_sprite_mesh_asset(self) {
  mesh2d_geometry_rhombus_ring(self).to_mesh()
}

///|
pub impl IntoSpriteMeshAsset for RectangleRing with into_sprite_mesh_asset(self) {
  mesh2d_geometry_rectangle_ring(self).to_mesh()
}

///|
pub impl IntoSpriteMeshAsset for RegularPolygonRing with into_sprite_mesh_asset(
  self,
) {
  mesh2d_geometry_regular_polygon_ring(self).to_mesh()
}

///|
pub impl IntoSpriteMeshAsset for Triangle2dRing with into_sprite_mesh_asset(
  self,
) {
  mesh2d_geometry_triangle_ring(self).to_mesh()
}

///|
pub impl IntoSpriteMeshAsset for Rhombus with into_sprite_mesh_asset(self) {
  mesh2d_geometry_rhombus(self).to_mesh()
}

///|
pub impl IntoSpriteMeshAsset for RegularPolygon with into_sprite_mesh_asset(
  self,
) {
  mesh2d_geometry_regular_polygon(self).to_mesh()
}

///|
pub impl IntoSpriteMeshAsset for Triangle2d with into_sprite_mesh_asset(self) {
  mesh2d_geometry_triangle(self).to_mesh()
}

///|
pub impl IntoSpriteMeshAsset for Segment2d with into_sprite_mesh_asset(self) {
  mesh2d_geometry_segment(self).to_mesh()
}

///|
pub impl IntoSpriteMeshAsset for Polyline2d with into_sprite_mesh_asset(self) {
  mesh2d_geometry_polyline(self).to_mesh()
}

///|
pub impl IntoSpriteMeshAsset for Rectangle with into_sprite_mesh_asset(self) {
  mesh2d_geometry_rectangle(self).to_mesh()
}
