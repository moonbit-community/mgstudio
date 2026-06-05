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
pub let ecs_key_mesh_material2d : @ecs.ComponentKey[
  MeshMaterial2d[ColorMaterial],
] = @sprite_render_mesh2d_color_material.color_material_mesh_material2d_component()

///|
pub let ecs_key_scissor_rect : @ecs.ComponentKey[ScissorRect] = @ecs.register_component(
  debug_name="render2d.scissor_rect",
)

///|
let ecs_key_mesh2d_wireframe : @ecs.ComponentKey[Mesh2dWireframe] = @sprite_render_mesh2d_wireframe2d.ecs_key_mesh2d_wireframe

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
pub impl @ecs.Component for ScissorRect with fn component() {
  ecs_key_scissor_rect
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
    @camera_camera.ecs_key_camera,
    @render.ecs_key_sync_to_render_world,
    fn() { @render.SyncToRenderWorld::SyncToRenderWorld() },
  )
  world.register_required_components_with(
    @camera_components2d.ecs_key_camera2d,
    @camera_camera.ecs_key_camera,
    fn() { @camera_camera.Camera::Camera() },
  )
  world.register_required_components_with(
    @camera_components2d.ecs_key_camera2d,
    @camera_projection2d.ecs_key_projection,
    fn() { @camera_projection2d.Projection::orthographic_2d() },
  )
  world.register_required_components_with(
    @camera_components2d.ecs_key_camera2d,
    @transform.ecs_key_transform,
    fn() { @transform.Transform::identity() },
  )
  world.register_required_components_with(
    @camera_components2d.ecs_key_camera2d,
    @camera_camera.ecs_key_render_target,
    fn() { @camera_camera.RenderTarget::Screen },
  )
  world.register_required_components_with(
    @camera_components2d.ecs_key_camera2d,
    ecs_key_render_layers,
    fn() { RenderLayers::RenderLayers() },
  )
  world.register_required_components_with(
    @post_process.ecs_key_bloom,
    @core_pipeline.ecs_key_hdr,
    fn() { @core_pipeline.Hdr::Hdr() },
  )
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
fn encode_color(color : @color.Color) -> Json {
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
fn decode_color(json : Json) -> @color.Color {
  let (r, g, b, a) : (Float, Float, Float, Float) = try! @json.from_json(json)
  @color.Color::new(r, g, b, a)
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
fn decode_scissor_rect(json : Json) -> ScissorRect {
  ScissorRect::new(decode_rect(json))
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
pub let ecs_components : Array[String] = [
  "Anchor", "Camera", "Mesh2d", "Sprite", "Bloom", "Camera2d", "Projection", "ScissorRect",
  "Wireframe2d", "RenderLayers", "RenderTarget", "ColorMaterial", "Tonemapping",
  "DebandDither", "ColorGrading", "NoWireframe2d", "MeshMaterial2d", "ClearColorConfig",
  "Wireframe2dColor", "TilemapChunk", "TilemapChunkTileData",
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
  @sprite_render_mesh2d_wireframe2d.get_wireframe2d_config_resource(world)
}
