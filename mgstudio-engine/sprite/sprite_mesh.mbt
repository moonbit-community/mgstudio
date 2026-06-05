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
// Render-only sprite material and plugin ownership lives in
// `sprite_render/sprite_mesh`.

///|
type Mesh2d = @mesh.Mesh2d

///|
type MeshMaterial2d[M] = @sprite_render_mesh2d_material.MeshMaterial2d[M]

///|
type RenderLayers = @camera_render_layers.RenderLayers

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
