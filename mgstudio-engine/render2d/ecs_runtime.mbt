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
pub let ecs_key_sprite : @ecs.ComponentKey[Sprite] = @ecs.register_component(
  debug_name="render2d.sprite",
)

///|
pub let ecs_key_anchor : @ecs.ComponentKey[Anchor] = @ecs.register_component(
  debug_name="render2d.anchor",
)

///|
pub let ecs_key_render_layers : @ecs.ComponentKey[RenderLayers] = @ecs.register_component(
  debug_name="render2d.render_layers",
)

///|
pub let ecs_key_camera2d : @ecs.ComponentKey[Camera2d] = @ecs.register_component(
  debug_name="render2d.camera2d",
)

///|
pub let ecs_key_camera : @ecs.ComponentKey[Camera] = @ecs.register_component(
  debug_name="render2d.camera",
)

///|
pub let ecs_key_projection : @ecs.ComponentKey[Projection] = @ecs.register_component(
  debug_name="render2d.projection",
)

///|
pub let ecs_key_pan_camera : @ecs.ComponentKey[PanCamera] = @ecs.register_component(
  debug_name="render2d.pan_camera",
)

///|
pub let ecs_key_render_target : @ecs.ComponentKey[RenderTarget] = @ecs.register_component(
  debug_name="render2d.render_target",
)

///|
pub let ecs_key_bloom2d : @ecs.ComponentKey[Bloom2d] = @ecs.register_component(
  debug_name="render2d.bloom2d",
)

///|
pub let ecs_key_tonemapping : @ecs.ComponentKey[Tonemapping] = @ecs.register_component(
  debug_name="render2d.tonemapping",
)

///|
pub let ecs_key_deband_dither : @ecs.ComponentKey[DebandDither] = @ecs.register_component(
  debug_name="render2d.deband_dither",
)

///|
pub let ecs_key_mesh2d : @ecs.ComponentKey[Mesh2d] = @ecs.register_component(
  debug_name="render2d.mesh2d",
)

///|
pub let ecs_key_color_material : @ecs.ComponentKey[ColorMaterial] = @ecs.register_component(
  debug_name="render2d.color_material",
)

///|
pub let ecs_key_mesh_material2d : @ecs.ComponentKey[MeshMaterial2d] = @ecs.register_component(
  debug_name="render2d.mesh_material2d",
)

///|
pub let ecs_key_gpu_mesh2d : @ecs.ComponentKey[GpuMesh2d] = @ecs.register_component(
  debug_name="render2d.gpu_mesh2d",
)

///|
pub let ecs_key_scissor_rect : @ecs.ComponentKey[ScissorRect] = @ecs.register_component(
  debug_name="render2d.scissor_rect",
)

///|
pub let ecs_key_wireframe2d : @ecs.ComponentKey[Wireframe2d] = @ecs.register_component(
  debug_name="render2d.wireframe2d",
)

///|
pub let ecs_key_no_wireframe2d : @ecs.ComponentKey[NoWireframe2d] = @ecs.register_component(
  debug_name="render2d.no_wireframe2d",
)

///|
pub let ecs_key_wireframe2d_color : @ecs.ComponentKey[Wireframe2dColor] = @ecs.register_component(
  debug_name="render2d.wireframe2d_color",
)

///|
pub let ecs_key_clear_color_config : @ecs.ComponentKey[ClearColorConfig] = @ecs.register_component(
  debug_name="render2d.clear_color_config",
)

///|
pub impl @ecs.Component for Sprite with component() {
  ecs_key_sprite
}

///|
pub impl @ecs.Component for Anchor with component() {
  ecs_key_anchor
}

///|
pub impl @ecs.Component for RenderLayers with component() {
  ecs_key_render_layers
}

///|
pub impl @ecs.Component for Camera2d with component() {
  ecs_key_camera2d
}

///|
pub impl @ecs.Component for Camera with component() {
  ecs_key_camera
}

///|
pub impl @ecs.Component for Projection with component() {
  ecs_key_projection
}

///|
pub impl @ecs.Component for PanCamera with component() {
  ecs_key_pan_camera
}

///|
pub impl @ecs.Component for RenderTarget with component() {
  ecs_key_render_target
}

///|
pub impl @ecs.Component for Bloom2d with component() {
  ecs_key_bloom2d
}

///|
pub impl @ecs.Component for Tonemapping with component() {
  ecs_key_tonemapping
}

///|
pub impl @ecs.Component for DebandDither with component() {
  ecs_key_deband_dither
}

///|
pub impl @ecs.Component for Mesh2d with component() {
  ecs_key_mesh2d
}

///|
pub impl @ecs.Component for ColorMaterial with component() {
  ecs_key_color_material
}

///|
pub impl @ecs.Component for MeshMaterial2d with component() {
  ecs_key_mesh_material2d
}

///|
pub impl @ecs.Component for GpuMesh2d with component() {
  ecs_key_gpu_mesh2d
}

///|
pub impl @ecs.Component for ScissorRect with component() {
  ecs_key_scissor_rect
}

///|
pub impl @ecs.Component for Wireframe2d with component() {
  ecs_key_wireframe2d
}

///|
pub impl @ecs.Component for NoWireframe2d with component() {
  ecs_key_no_wireframe2d
}

///|
pub impl @ecs.Component for Wireframe2dColor with component() {
  ecs_key_wireframe2d_color
}

///|
pub impl @ecs.Component for ClearColorConfig with component() {
  ecs_key_clear_color_config
}

///|
pub let ecs_key_render_state : @ecs.ResourceKey[RenderState] = @ecs.register_resource(
  debug_name="render2d.render_state",
)

///|
pub let ecs_key_wireframe2d_config : @ecs.ResourceKey[Wireframe2dConfig] = @ecs.register_resource(
  debug_name="render2d.wireframe2d_config",
)

///|
/// ECS-world variant that does not depend on `RenderState` resource traits.
pub fn render2d_create_render_target_ecs(
  width : Int,
  height : Int,
  nearest : Bool,
) -> @asset.Handle[@asset.Image] {
  let id = @window.host_gpu_create_render_target(width~, height~, nearest~)
  @asset.Handle::new(id)
}

///|
fn encode_color(color : Color) -> Json {
  (color.r, color.g, color.b, color.a).to_json()
}

///|
fn encode_vec2(value : @math.Vec2) -> Json {
  (value.x, value.y).to_json()
}

///|
fn encode_ivec2(value : @math.IVec2) -> Json {
  (value.x, value.y).to_json()
}

///|
fn encode_rect(rect : @math.Rect) -> Json {
  (rect.min.x, rect.min.y, rect.max.x, rect.max.y).to_json()
}

///|
fn encode_image_handle(handle : @asset.Handle[@asset.Image]) -> Json {
  handle.id().to_json()
}

///|
fn encode_mesh_handle(handle : @asset.Handle[@mesh.Mesh]) -> Json {
  handle.id().to_json()
}

///|
fn encode_color_material_asset_handle(
  handle : @asset.Handle[ColorMaterialAsset],
) -> Json {
  handle.id().to_json()
}

///|
fn encode_texture_atlas(texture_atlas : @asset.TextureAtlas) -> Json {
  (texture_atlas.layout.id(), texture_atlas.index).to_json()
}

///|
fn encode_slice_scale_mode(mode : SliceScaleMode) -> Json {
  match mode {
    Stretch => (0, Json::null()).to_json()
    Tile(value) => (1, value.to_json()).to_json()
  }
}

///|
fn encode_sprite_scaling_mode(mode : SpriteScalingMode) -> Json {
  match mode {
    FillCenter => (0).to_json()
    FillStart => (1).to_json()
    FillEnd => (2).to_json()
    FitCenter => (3).to_json()
    FitStart => (4).to_json()
    FitEnd => (5).to_json()
  }
}

///|
fn encode_sprite_tiling(tiling : SpriteTiling) -> Json {
  (tiling.tile_x, tiling.tile_y, tiling.stretch_value).to_json()
}

///|
fn encode_border_rect(border : BorderRect) -> Json {
  (border.left, border.right, border.top, border.bottom).to_json()
}

///|
fn encode_texture_slicer(slicer : TextureSlicer) -> Json {
  (
    encode_border_rect(slicer.border),
    encode_slice_scale_mode(slicer.center_scale_mode),
    encode_slice_scale_mode(slicer.sides_scale_mode),
    slicer.max_corner_scale,
  ).to_json()
}

///|
fn encode_sprite_image_mode(mode : SpriteImageMode) -> Json {
  match mode {
    Auto => (0, Json::null()).to_json()
    Scale(scaling_mode) =>
      (1, encode_sprite_scaling_mode(scaling_mode)).to_json()
    Sliced(slicer) => (2, encode_texture_slicer(slicer)).to_json()
    Tiled(tiling) => (3, encode_sprite_tiling(tiling)).to_json()
  }
}

///|
fn encode_sprite(sprite : Sprite) -> Json {
  (
    encode_image_handle(sprite.image),
    sprite.texture_atlas.map(fn(texture_atlas) {
      encode_texture_atlas(texture_atlas)
    }),
    encode_color(sprite.color),
    sprite.flip_x,
    sprite.flip_y,
    sprite.custom_size.map(fn(size) { encode_vec2(size) }),
    sprite.rect.map(fn(rect) { encode_rect(rect) }),
    encode_sprite_image_mode(sprite.image_mode),
  ).to_json()
}

///|
fn encode_anchor(anchor : Anchor) -> Json {
  encode_vec2(anchor.value)
}

///|
fn encode_render_layers(layers : RenderLayers) -> Json {
  layers.mask.to_json()
}

///|
fn encode_viewport(viewport : Viewport) -> Json {
  (
    encode_ivec2(viewport.physical_position),
    encode_ivec2(viewport.physical_size),
    viewport.depth_min,
    viewport.depth_max,
  ).to_json()
}

///|
fn encode_camera_target_info(target_info : CameraTargetInfo) -> Json {
  (encode_ivec2(target_info.physical_size), target_info.scale_factor).to_json()
}

///|
fn encode_camera_computed_values(computed : CameraComputedValues) -> Json {
  (
    computed.target_info.map(fn(target_info) {
      encode_camera_target_info(target_info)
    }),
    computed.old_viewport_size.map(fn(size) { encode_ivec2(size) }),
  ).to_json()
}

///|
fn encode_clear_color_config(clear_color : ClearColorConfig) -> Json {
  match clear_color {
    Default => (0, Json::null()).to_json()
    Custom(color) => (1, encode_color(color)).to_json()
    None => (2, Json::null()).to_json()
  }
}

///|
fn encode_camera(camera : Camera) -> Json {
  (
    camera.viewport.map(fn(viewport) { encode_viewport(viewport) }),
    camera.order,
    camera.is_active,
    encode_camera_computed_values(camera.computed),
    encode_clear_color_config(camera.clear_color),
  ).to_json()
}

///|
fn encode_camera2d(_camera2d : Camera2d) -> Json {
  (0).to_json()
}

///|
fn encode_projection(projection : Projection) -> Json {
  match projection {
    Orthographic(orthographic) => (0, orthographic.scale).to_json()
  }
}

///|
fn encode_render_target(target : RenderTarget) -> Json {
  match target {
    Screen => (0, Json::null()).to_json()
    Image(image) => (1, encode_image_handle(image)).to_json()
    Window(window_ref) => (2, window_ref.to_json()).to_json()
  }
}

///|
fn encode_bloom_prefilter(prefilter : BloomPrefilter) -> Json {
  (prefilter.threshold, prefilter.threshold_softness).to_json()
}

///|
fn encode_bloom_composite_mode(mode : BloomCompositeMode) -> Json {
  match mode {
    EnergyConserving => (0).to_json()
    Additive => (1).to_json()
  }
}

///|
fn encode_bloom_settings(settings : Bloom2dSettings) -> Json {
  (
    settings.intensity,
    settings.low_frequency_boost,
    settings.low_frequency_boost_curvature,
    settings.high_pass_frequency,
    encode_bloom_prefilter(settings.prefilter),
    encode_bloom_composite_mode(settings.composite_mode),
    settings.max_mip_dimension,
    encode_vec2(settings.scale),
  ).to_json()
}

///|
fn encode_bloom2d(bloom2d : Bloom2d) -> Json {
  (
    bloom2d.source.map(fn(source) { encode_image_handle(source) }),
    bloom2d.enabled,
    encode_bloom_settings(bloom2d.settings),
  ).to_json()
}

///|
fn encode_tonemapping(mode : Tonemapping) -> Json {
  match mode {
    None => (0).to_json()
    Reinhard => (1).to_json()
    ReinhardLuminance => (2).to_json()
    AcesFitted => (3).to_json()
    AgX => (4).to_json()
    SomewhatBoringDisplayTransform => (5).to_json()
    TonyMcMapface => (6).to_json()
    BlenderFilmic => (7).to_json()
  }
}

///|
fn encode_deband_dither(mode : DebandDither) -> Json {
  match mode {
    Disabled => (0).to_json()
    Enabled => (1).to_json()
  }
}

///|
fn encode_mesh2d(mesh2d : Mesh2d) -> Json {
  encode_mesh_handle(mesh2d.mesh)
}

///|
fn encode_color_material(material : ColorMaterial) -> Json {
  encode_color_material_asset_handle(material.handle)
}

///|
fn encode_mesh_material2d(material : MeshMaterial2d) -> Json {
  encode_color_material_asset_handle(material.handle)
}

///|
fn encode_gpu_mesh2d(gpu_mesh2d : GpuMesh2d) -> Json {
  gpu_mesh2d.mesh_id.to_json()
}

///|
fn decode_color(json : Json) -> Color {
  let (r, g, b, a) : (Float, Float, Float, Float) = try! @json.from_json(json)
  Color::new(r, g, b, a)
}

///|
fn decode_vec2(json : Json) -> @math.Vec2 {
  let (x, y) : (Float, Float) = try! @json.from_json(json)
  @math.Vec2::new(x, y)
}

///|
fn decode_ivec2(json : Json) -> @math.IVec2 {
  let (x, y) : (Int, Int) = try! @json.from_json(json)
  @math.IVec2::new(x, y)
}

///|
fn decode_rect(json : Json) -> @math.Rect {
  let (min_x, min_y, max_x, max_y) : (Float, Float, Float, Float) = try! @json.from_json(
    json,
  )
  @math.Rect::new(@math.Vec2::new(min_x, min_y), @math.Vec2::new(max_x, max_y))
}

///|
fn decode_image_handle(json : Json) -> @asset.Handle[@asset.Image] {
  let id : Int = try! @json.from_json(json)
  @asset.Handle::new(id)
}

///|
fn decode_mesh_handle(json : Json) -> @asset.Handle[@mesh.Mesh] {
  let id : Int = try! @json.from_json(json)
  @asset.Handle::new(id)
}

///|
fn decode_color_material_asset_handle(
  json : Json,
) -> @asset.Handle[ColorMaterialAsset] {
  let id : Int = try! @json.from_json(json)
  @asset.Handle::new(id)
}

///|
fn decode_texture_atlas(json : Json) -> @asset.TextureAtlas {
  let (layout_id, index) : (Int, Int) = try! @json.from_json(json)
  @asset.TextureAtlas::new(@asset.Handle::new(layout_id), index)
}

///|
fn decode_slice_scale_mode(json : Json) -> SliceScaleMode {
  let (tag, payload) : (Int, Json) = try! @json.from_json(json)
  match tag {
    0 => Stretch
    1 => Tile(try! @json.from_json(payload))
    _ => Stretch
  }
}

///|
fn decode_sprite_scaling_mode(json : Json) -> SpriteScalingMode {
  let tag : Int = try! @json.from_json(json)
  match tag {
    0 => FillCenter
    1 => FillStart
    2 => FillEnd
    3 => FitCenter
    4 => FitStart
    5 => FitEnd
    _ => FillCenter
  }
}

///|
fn decode_sprite_tiling(json : Json) -> SpriteTiling {
  let (tile_x, tile_y, stretch_value) : (Bool, Bool, Float) = try! @json.from_json(
    json,
  )
  SpriteTiling::new(tile_x, tile_y, stretch_value)
}

///|
fn decode_border_rect(json : Json) -> BorderRect {
  let (left, right, top, bottom) : (Float, Float, Float, Float) = try! @json.from_json(
    json,
  )
  BorderRect::new(left, right, top, bottom)
}

///|
fn decode_texture_slicer(json : Json) -> TextureSlicer {
  let (border, center_mode, sides_mode, max_corner_scale) : (
    Json,
    Json,
    Json,
    Float,
  ) = try! @json.from_json(json)
  TextureSlicer::new(decode_border_rect(border))
  .with_center_scale_mode(decode_slice_scale_mode(center_mode))
  .with_sides_scale_mode(decode_slice_scale_mode(sides_mode))
  .with_max_corner_scale(max_corner_scale)
}

///|
fn decode_sprite_image_mode(json : Json) -> SpriteImageMode {
  let (tag, payload) : (Int, Json) = try! @json.from_json(json)
  match tag {
    0 => Auto
    1 => Scale(decode_sprite_scaling_mode(payload))
    2 => Sliced(decode_texture_slicer(payload))
    3 => Tiled(decode_sprite_tiling(payload))
    _ => Auto
  }
}

///|
fn decode_sprite(json : Json) -> Sprite {
  let (
    image_json,
    atlas_json,
    color_json,
    flip_x,
    flip_y,
    custom_size_json,
    rect_json,
    image_mode_json,
  ) : (Json, Json?, Json, Bool, Bool, Json?, Json?, Json) = try! @json.from_json(
    json,
  )
  Sprite::{
    image: decode_image_handle(image_json),
    texture_atlas: atlas_json.map(fn(value) { decode_texture_atlas(value) }),
    color: decode_color(color_json),
    flip_x,
    flip_y,
    custom_size: custom_size_json.map(fn(value) { decode_vec2(value) }),
    rect: rect_json.map(fn(value) { decode_rect(value) }),
    image_mode: decode_sprite_image_mode(image_mode_json),
  }
}

///|
fn decode_anchor(json : Json) -> Anchor {
  Anchor::new(decode_vec2(json))
}

///|
fn decode_render_layers(json : Json) -> RenderLayers {
  let mask : Int = try! @json.from_json(json)
  RenderLayers::{ mask, }
}

///|
fn decode_viewport(json : Json) -> Viewport {
  let (position, size, depth_min, depth_max) : (Json, Json, Float, Float) = try! @json.from_json(
    json,
  )
  Viewport::new(decode_ivec2(position), decode_ivec2(size)).with_depth(
    depth_min, depth_max,
  )
}

///|
fn decode_camera_target_info(json : Json) -> CameraTargetInfo {
  let (size, scale_factor) : (Json, Float) = try! @json.from_json(json)
  CameraTargetInfo::new(decode_ivec2(size), scale_factor)
}

///|
fn decode_camera_computed_values(json : Json) -> CameraComputedValues {
  let (target_info_json, old_viewport_size_json) : (Json?, Json?) = try! @json.from_json(
    json,
  )
  CameraComputedValues::{
    target_info: target_info_json.map(fn(value) {
      decode_camera_target_info(value)
    }),
    old_viewport_size: old_viewport_size_json.map(fn(value) {
      decode_ivec2(value)
    }),
  }
}

///|
fn decode_clear_color_config(json : Json) -> ClearColorConfig {
  let (tag, payload) : (Int, Json) = try! @json.from_json(json)
  match tag {
    0 => Default
    1 => Custom(decode_color(payload))
    2 => None
    _ => Default
  }
}

///|
fn decode_camera(json : Json) -> Camera {
  let (viewport_json, order, is_active, computed_json, clear_color_json) : (
    Json?,
    Int,
    Bool,
    Json,
    Json,
  ) = try! @json.from_json(json)
  Camera::{
    viewport: viewport_json.map(fn(value) { decode_viewport(value) }),
    order,
    is_active,
    computed: decode_camera_computed_values(computed_json),
    clear_color: decode_clear_color_config(clear_color_json),
  }
}

///|
fn decode_camera2d(_json : Json) -> Camera2d {
  Camera2d::default()
}

///|
fn decode_projection(json : Json) -> Projection {
  let (tag, payload) : (Int, Float) = try! @json.from_json(json)
  match tag {
    0 => Orthographic(OrthographicProjection::new(payload))
    _ => Projection::orthographic_2d()
  }
}

///|
fn decode_render_target(json : Json) -> RenderTarget {
  let (tag, payload) : (Int, Json) = try! @json.from_json(json)
  match tag {
    0 => Screen
    1 => Image(decode_image_handle(payload))
    2 => Window(try! @json.from_json(payload))
    _ => Screen
  }
}

///|
fn decode_bloom_prefilter(json : Json) -> BloomPrefilter {
  let (threshold, threshold_softness) : (Float, Float) = try! @json.from_json(
    json,
  )
  BloomPrefilter::{ threshold, threshold_softness }
}

///|
fn decode_bloom_composite_mode(json : Json) -> BloomCompositeMode {
  let tag : Int = try! @json.from_json(json)
  match tag {
    0 => EnergyConserving
    1 => Additive
    _ => EnergyConserving
  }
}

///|
fn decode_bloom_settings(json : Json) -> Bloom2dSettings {
  let (
    intensity,
    low_frequency_boost,
    low_frequency_boost_curvature,
    high_pass_frequency,
    prefilter_json,
    composite_mode_json,
    max_mip_dimension,
    scale_json,
  ) : (Float, Float, Float, Float, Json, Json, Int, Json) = try! @json.from_json(
    json,
  )
  Bloom2dSettings::{
    intensity,
    low_frequency_boost,
    low_frequency_boost_curvature,
    high_pass_frequency,
    prefilter: decode_bloom_prefilter(prefilter_json),
    composite_mode: decode_bloom_composite_mode(composite_mode_json),
    max_mip_dimension,
    scale: decode_vec2(scale_json),
  }
}

///|
fn decode_bloom2d(json : Json) -> Bloom2d {
  let (source_json, enabled, settings_json) : (Json?, Bool, Json) = try! @json.from_json(
    json,
  )
  Bloom2d::{
    source: source_json.map(fn(value) { decode_image_handle(value) }),
    enabled,
    settings: decode_bloom_settings(settings_json),
  }
}

///|
fn decode_tonemapping(json : Json) -> Tonemapping {
  let tag : Int = try! @json.from_json(json)
  match tag {
    0 => None
    1 => Reinhard
    2 => ReinhardLuminance
    3 => AcesFitted
    4 => AgX
    5 => SomewhatBoringDisplayTransform
    6 => TonyMcMapface
    7 => BlenderFilmic
    _ => None
  }
}

///|
fn decode_deband_dither(json : Json) -> DebandDither {
  let tag : Int = try! @json.from_json(json)
  match tag {
    0 => Disabled
    1 => Enabled
    _ => Disabled
  }
}

///|
fn decode_mesh2d(json : Json) -> Mesh2d {
  Mesh2d::new(decode_mesh_handle(json))
}

///|
fn decode_color_material(json : Json) -> ColorMaterial {
  ColorMaterial::{ handle: decode_color_material_asset_handle(json) }
}

///|
fn decode_mesh_material2d(json : Json) -> MeshMaterial2d {
  MeshMaterial2d::new(decode_color_material_asset_handle(json))
}

///|
fn decode_gpu_mesh2d(json : Json) -> GpuMesh2d {
  let mesh_id : Int = try! @json.from_json(json)
  GpuMesh2d::new(mesh_id)
}

///|
fn decode_scissor_rect(json : Json) -> ScissorRect {
  ScissorRect::new(decode_rect(json))
}

///|
fn decode_wireframe2d(_json : Json) -> Wireframe2d {
  Wireframe2d::default()
}

///|
fn decode_no_wireframe2d(_json : Json) -> NoWireframe2d {
  NoWireframe2d::default()
}

///|
fn decode_wireframe2d_color(json : Json) -> Wireframe2dColor {
  Wireframe2dColor::new(decode_color(json))
}

///|
pub impl ToJson for Color with to_json(self) {
  encode_color(self)
}

///|
pub impl @json.FromJson for Color with from_json(json, _path) {
  decode_color(json)
}

///|
pub impl ToJson for Sprite with to_json(self) {
  encode_sprite(self)
}

///|
pub impl @json.FromJson for Sprite with from_json(json, _path) {
  decode_sprite(json)
}

///|
pub impl ToJson for Anchor with to_json(self) {
  encode_anchor(self)
}

///|
pub impl @json.FromJson for Anchor with from_json(json, _path) {
  decode_anchor(json)
}

///|
pub impl ToJson for RenderLayers with to_json(self) {
  encode_render_layers(self)
}

///|
pub impl @json.FromJson for RenderLayers with from_json(json, _path) {
  decode_render_layers(json)
}

///|
pub impl ToJson for ScissorRect with to_json(self) {
  encode_rect(self.rect)
}

///|
pub impl @json.FromJson for ScissorRect with from_json(json, _path) {
  decode_scissor_rect(json)
}

///|
pub impl ToJson for ClearColorConfig with to_json(self) {
  encode_clear_color_config(self)
}

///|
pub impl @json.FromJson for ClearColorConfig with from_json(json, _path) {
  decode_clear_color_config(json)
}

///|
pub impl ToJson for Camera with to_json(self) {
  encode_camera(self)
}

///|
pub impl @json.FromJson for Camera with from_json(json, _path) {
  decode_camera(json)
}

///|
pub impl ToJson for Camera2d with to_json(self) {
  encode_camera2d(self)
}

///|
pub impl @json.FromJson for Camera2d with from_json(json, _path) {
  decode_camera2d(json)
}

///|
pub impl ToJson for Projection with to_json(self) {
  encode_projection(self)
}

///|
pub impl @json.FromJson for Projection with from_json(json, _path) {
  decode_projection(json)
}

///|
pub impl ToJson for RenderTarget with to_json(self) {
  encode_render_target(self)
}

///|
pub impl @json.FromJson for RenderTarget with from_json(json, _path) {
  decode_render_target(json)
}

///|
pub impl ToJson for Bloom2d with to_json(self) {
  encode_bloom2d(self)
}

///|
pub impl @json.FromJson for Bloom2d with from_json(json, _path) {
  decode_bloom2d(json)
}

///|
pub impl ToJson for Tonemapping with to_json(self) {
  encode_tonemapping(self)
}

///|
pub impl @json.FromJson for Tonemapping with from_json(json, _path) {
  decode_tonemapping(json)
}

///|
pub impl ToJson for DebandDither with to_json(self) {
  encode_deband_dither(self)
}

///|
pub impl @json.FromJson for DebandDither with from_json(json, _path) {
  decode_deband_dither(json)
}

///|
pub impl ToJson for Mesh2d with to_json(self) {
  encode_mesh2d(self)
}

///|
pub impl @json.FromJson for Mesh2d with from_json(json, _path) {
  decode_mesh2d(json)
}

///|
pub impl ToJson for ColorMaterial with to_json(self) {
  encode_color_material(self)
}

///|
pub impl @json.FromJson for ColorMaterial with from_json(json, _path) {
  decode_color_material(json)
}

///|
pub impl ToJson for MeshMaterial2d with to_json(self) {
  encode_mesh_material2d(self)
}

///|
pub impl @json.FromJson for MeshMaterial2d with from_json(json, _path) {
  decode_mesh_material2d(json)
}

///|
pub impl ToJson for GpuMesh2d with to_json(self) {
  encode_gpu_mesh2d(self)
}

///|
pub impl @json.FromJson for GpuMesh2d with from_json(json, _path) {
  decode_gpu_mesh2d(json)
}

///|
pub impl ToJson for Wireframe2d with to_json(self) {
  self |> ignore
  (0).to_json()
}

///|
pub impl @json.FromJson for Wireframe2d with from_json(json, _path) {
  decode_wireframe2d(json)
}

///|
pub impl ToJson for NoWireframe2d with to_json(self) {
  self |> ignore
  (0).to_json()
}

///|
pub impl @json.FromJson for NoWireframe2d with from_json(json, _path) {
  decode_no_wireframe2d(json)
}

///|
pub impl ToJson for Wireframe2dColor with to_json(self) {
  encode_color(self.color)
}

///|
pub impl @json.FromJson for Wireframe2dColor with from_json(json, _path) {
  decode_wireframe2d_color(json)
}
