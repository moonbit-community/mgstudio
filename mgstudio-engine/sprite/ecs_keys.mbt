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
pub let ecs_key_sprite_mesh : @ecs.ComponentKey[SpriteMesh] = @ecs.register_component(
  debug_name="render2d.sprite_mesh",
)

///|
pub let ecs_key_anchor : @ecs.ComponentKey[Anchor] = @ecs.register_component(
  debug_name="render2d.anchor",
)

///|
let ecs_key_render_layers : @ecs.ComponentKey[RenderLayers] = @camera_render_layers.ecs_key_render_layers

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
pub let ecs_key_bloom : @ecs.ComponentKey[Bloom] = @post_process.ecs_key_bloom

///|
pub let ecs_key_tonemapping : @ecs.ComponentKey[Tonemapping] = @post_process.ecs_key_tonemapping

///|
pub let ecs_key_deband_dither : @ecs.ComponentKey[DebandDither] = @post_process.ecs_key_deband_dither

///|
pub let ecs_key_color_grading : @ecs.ComponentKey[ColorGrading] = @post_process.ecs_key_color_grading

///|
pub let ecs_key_hdr : @ecs.ComponentKey[Hdr] = @core_pipeline.ecs_key_hdr

///|
let ecs_key_mesh2d : @ecs.ComponentKey[Mesh2d] = @mesh.ecs_key_mesh2d

///|
pub let ecs_key_mesh_material2d : @ecs.ComponentKey[
  MeshMaterial2d[ColorMaterial],
] = @sprite_render_mesh2d_color_material.color_material_mesh_material2d_component()

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
pub let ecs_key_mesh2d_wireframe : @ecs.ComponentKey[Mesh2dWireframe] = @ecs.register_component(
  debug_name="render2d.mesh2d_wireframe",
)

///|
let ecs_key_tilemap_chunk : @ecs.ComponentKey[TilemapChunk] = @sprite_tilemap_chunk.ecs_key_tilemap_chunk

///|
let ecs_key_tilemap_chunk_tile_data : @ecs.ComponentKey[TilemapChunkTileData] = @sprite_tilemap_chunk.ecs_key_tilemap_chunk_tile_data

///|
pub impl @ecs.Component for Sprite with fn component() {
  ecs_key_sprite
}

///|
pub impl @ecs.Component for SpriteMesh with fn component() {
  ecs_key_sprite_mesh
}

///|
pub impl @ecs.Component for Anchor with fn component() {
  ecs_key_anchor
}

///|
pub impl @ecs.Component for Camera2d with fn component() {
  ecs_key_camera2d
}

///|
pub impl @ecs.Component for Camera with fn component() {
  ecs_key_camera
}

///|
pub impl @ecs.Component for Projection with fn component() {
  ecs_key_projection
}

///|
pub impl @ecs.Component for PanCamera with fn component() {
  ecs_key_pan_camera
}

///|
pub impl @ecs.Component for RenderTarget with fn component() {
  ecs_key_render_target
}

///|
pub impl @ecs.Component for ScissorRect with fn component() {
  ecs_key_scissor_rect
}

///|
pub impl @ecs.Component for Wireframe2d with fn component() {
  ecs_key_wireframe2d
}

///|
pub impl @ecs.Component for NoWireframe2d with fn component() {
  ecs_key_no_wireframe2d
}

///|
pub impl @ecs.Component for Wireframe2dColor with fn component() {
  ecs_key_wireframe2d_color
}

///|
pub impl @ecs.Component for Mesh2dWireframe with fn component() {
  ecs_key_mesh2d_wireframe
}

///|
pub fn register_render2d_required_components(
  world : @ecs.World,
) -> Unit raise @ecs.RequiredComponentsError {
  world.register_required_components_with(ecs_key_sprite, ecs_key_anchor, fn() {
    Anchor::Anchor()
  })
  world.register_required_components_with(
    ecs_key_sprite,
    @transform.ecs_key_transform,
    fn() { @transform.Transform::identity() },
  )
  world.register_required_components_with(
    ecs_key_sprite,
    @visibility.ecs_key_visibility,
    fn() { @visibility.Visibility::Inherited },
  )
  world.register_required_components_with(
    ecs_key_sprite,
    @render.ecs_key_sync_to_render_world,
    fn() { @render.SyncToRenderWorld::SyncToRenderWorld() },
  )
  world.register_required_components_with(ecs_key_sprite_mesh, ecs_key_anchor, fn() {
    Anchor::Anchor()
  })
  world.register_required_components_with(
    ecs_key_sprite_mesh,
    @transform.ecs_key_transform,
    fn() { @transform.Transform::identity() },
  )
  world.register_required_components_with(
    ecs_key_sprite_mesh,
    @visibility.ecs_key_visibility,
    fn() { @visibility.Visibility::Inherited },
  )
  world.register_required_components_with(
    ecs_key_camera,
    @render.ecs_key_sync_to_render_world,
    fn() { @render.SyncToRenderWorld::SyncToRenderWorld() },
  )
  world.register_required_components_with(ecs_key_camera2d, ecs_key_camera, fn() {
    Camera::Camera()
  })
  world.register_required_components_with(
    ecs_key_camera2d,
    ecs_key_projection,
    fn() { Projection::orthographic_2d() },
  )
  world.register_required_components_with(
    ecs_key_camera2d,
    @transform.ecs_key_transform,
    fn() { @transform.Transform::identity() },
  )
  world.register_required_components_with(
    ecs_key_camera2d,
    ecs_key_render_target,
    fn() { RenderTarget::Screen },
  )
  world.register_required_components_with(
    ecs_key_camera2d,
    ecs_key_render_layers,
    fn() { RenderLayers::RenderLayers() },
  )
  world.register_required_components_with(
    ecs_key_camera2d,
    ecs_key_tonemapping,
    fn() { Tonemapping::None },
  )
  world.register_required_components_with(
    ecs_key_camera2d,
    ecs_key_deband_dither,
    fn() { DebandDither::Disabled },
  )
  world.register_required_components_with(ecs_key_bloom, ecs_key_hdr, fn() {
    Hdr()
  })
}

///|
pub fn ensure_render2d_required_components(world : @ecs.World) -> Unit {
  register_render2d_required_components(world) catch {
    @ecs.RequiredComponentsError::DuplicateRegistration(_, _) => ()
    @ecs.RequiredComponentsError::ArchetypeExists(_) => ()
    _ => abort("failed to register render2d required components")
  }
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
pub let ecs_key_global_wireframe_material : @ecs.ResourceKey[
  GlobalWireframeMaterial,
] = @ecs.register_resource(debug_name="render2d.global_wireframe_material")

///|
pub let ecs_key_wireframe_entities_needing_specialization : @ecs.ResourceKey[
  WireframeEntitiesNeedingSpecialization,
] = @ecs.register_resource(
  debug_name="render2d.wireframe_entities_needing_specialization",
)

///|
/// ECS-world variant that does not depend on `RenderState` resource traits.
pub fn render2d_create_render_target_ecs(
  width : Int,
  height : Int,
  nearest : Bool,
) -> @asset.Handle[@asset.Image] {
  let id = @render.host_gpu_create_render_target(width~, height~, nearest~)
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
fn encode_rect(rect : @math.Rect) -> Json {
  (rect.min.x, rect.min.y, rect.max.x, rect.max.y).to_json()
}

///|
fn encode_image_handle(handle : @asset.Handle[@asset.Image]) -> Json {
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
fn encode_viewport(viewport : Viewport) -> Json {
  @camera_viewport.encode_viewport(viewport)
}

///|
fn encode_computed_camera_values(computed : ComputedCameraValues) -> Json {
  @camera_computed.encode_computed_camera_values(computed)
}

///|
fn encode_clear_color_config(clear_color : ClearColorConfig) -> Json {
  @camera_clear_color.encode_clear_color_config(clear_color)
}

///|
fn encode_camera(camera : Camera) -> Json {
  (
    camera.viewport.map(fn(viewport) { encode_viewport(viewport) }),
    camera.order,
    camera.is_active,
    encode_computed_camera_values(camera.computed),
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
fn decode_viewport(json : Json) -> Viewport {
  @camera_viewport.decode_viewport(json)
}

///|
fn decode_computed_camera_values(json : Json) -> ComputedCameraValues {
  @camera_computed.decode_computed_camera_values(json)
}

///|
fn decode_clear_color_config(json : Json) -> ClearColorConfig {
  @camera_clear_color.decode_clear_color_config(json)
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
    computed: decode_computed_camera_values(computed_json),
    clear_color: decode_clear_color_config(clear_color_json),
  }
}

///|
fn decode_camera2d(_json : Json) -> Camera2d {
  Camera2d::Camera2d()
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
fn decode_scissor_rect(json : Json) -> ScissorRect {
  ScissorRect::new(decode_rect(json))
}

///|
fn decode_wireframe2d(_json : Json) -> Wireframe2d {
  Wireframe2d::Wireframe2d()
}

///|
fn decode_no_wireframe2d(_json : Json) -> NoWireframe2d {
  NoWireframe2d::NoWireframe2d()
}

///|
fn decode_wireframe2d_color(json : Json) -> Wireframe2dColor {
  Wireframe2dColor::new(decode_color(json))
}

///|
pub impl ToJson for Sprite with fn to_json(self) {
  encode_sprite(self)
}

///|
pub impl @json.FromJson for Sprite with fn from_json(json, _path) {
  decode_sprite(json)
}

///|
pub impl ToJson for Anchor with fn to_json(self) {
  encode_anchor(self)
}

///|
pub impl @json.FromJson for Anchor with fn from_json(json, _path) {
  decode_anchor(json)
}

///|
pub impl ToJson for ScissorRect with fn to_json(self) {
  encode_rect(self.rect)
}

///|
pub impl @json.FromJson for ScissorRect with fn from_json(json, _path) {
  decode_scissor_rect(json)
}

///|
pub impl ToJson for Camera with fn to_json(self) {
  encode_camera(self)
}

///|
pub impl @json.FromJson for Camera with fn from_json(json, _path) {
  decode_camera(json)
}

///|
pub impl ToJson for Camera2d with fn to_json(self) {
  encode_camera2d(self)
}

///|
pub impl @json.FromJson for Camera2d with fn from_json(json, _path) {
  decode_camera2d(json)
}

///|
pub impl ToJson for Projection with fn to_json(self) {
  encode_projection(self)
}

///|
pub impl @json.FromJson for Projection with fn from_json(json, _path) {
  decode_projection(json)
}

///|
pub impl ToJson for RenderTarget with fn to_json(self) {
  encode_render_target(self)
}

///|
pub impl @json.FromJson for RenderTarget with fn from_json(json, _path) {
  decode_render_target(json)
}

///|
pub impl ToJson for Wireframe2d with fn to_json(self) {
  self |> ignore
  (0).to_json()
}

///|
pub impl @json.FromJson for Wireframe2d with fn from_json(json, _path) {
  decode_wireframe2d(json)
}

///|
pub impl ToJson for NoWireframe2d with fn to_json(self) {
  self |> ignore
  (0).to_json()
}

///|
pub impl @json.FromJson for NoWireframe2d with fn from_json(json, _path) {
  decode_no_wireframe2d(json)
}

///|
pub impl ToJson for Wireframe2dColor with fn to_json(self) {
  encode_color(self.color)
}

///|
pub impl @json.FromJson for Wireframe2dColor with fn from_json(json, _path) {
  decode_wireframe2d_color(json)
}

///|
pub let ecs_components : Array[String] = [
  "Anchor", "Camera", "Mesh2d", "Sprite", "Bloom", "Camera2d", "Projection", "PanCamera",
  "ScissorRect", "Wireframe2d", "RenderLayers", "RenderTarget", "ColorMaterial",
  "Tonemapping", "DebandDither", "ColorGrading", "NoWireframe2d", "MeshMaterial2d",
  "ClearColorConfig", "Wireframe2dColor", "TilemapChunk", "TilemapChunkTileData",
]

///|
pub let ecs_resources : Array[String] = ["RenderState", "Wireframe2dConfig"]

///|
pub fn get_render_state_resource(
  world : @ecs.World,
) -> @ecs.ResourceAccess[RenderState] {
  world.resource(ecs_key_render_state)
}

///|
pub fn get_wireframe2d_config_resource(
  world : @ecs.World,
) -> @ecs.ResourceAccess[Wireframe2dConfig] {
  world.resource(ecs_key_wireframe2d_config)
}
