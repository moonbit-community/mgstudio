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
// Bevy source: `bevy/crates/bevy_render/src/render_asset.rs`.

///|
pub(all) suberror PrepareAssetError {
  RetryNextUpdate(String)
  AsBindGroupError(String)
}

///|
pub struct AssetExtractionSystems {}

///|
pub fn AssetExtractionSystems::new() -> AssetExtractionSystems {
  AssetExtractionSystems::{  }
}

///|
pub struct ExtractedAssets[A] {
  extracted : Array[(Int, A)]
  removed : @hashset.HashSet[Int]
  modified : @hashset.HashSet[Int]
  added : @hashset.HashSet[Int]
}

///|
pub fn[A] ExtractedAssets::new() -> ExtractedAssets[A] {
  ExtractedAssets::{
    extracted: [],
    removed: @hashset.HashSet([]),
    modified: @hashset.HashSet([]),
    added: @hashset.HashSet([]),
  }
}

///|
pub struct RenderAssets[A] {
  items : @hashmap.HashMap[Int, Ref[A]]
}

///|
pub(open) trait RenderAssetResource: @ecs.EcsPayloadCodec {
  fn render_asset_resource_debug_name() -> String
}

///|
let render_assets_resource_registry : Ref[@hashmap.HashMap[String, Int]] = Ref(
  @hashmap.HashMap([]),
)

///|
pub fn[A : RenderAssetResource] RenderAssets::resource() -> @ecs.ResourceKey[
  RenderAssets[A],
] {
  let type_name = "RenderAssets<\{A::render_asset_resource_debug_name()}>"
  match render_assets_resource_registry.val.get(type_name) {
    Some(id) =>
      @ecs.resource_key_from_id(id, debug_name="mgstudio_render::\{type_name}")
    None => {
      let key : @ecs.ResourceKey[RenderAssets[A]] = @ecs.register_resource(
        debug_name="mgstudio_render::\{type_name}",
      )
      render_assets_resource_registry.val.set(type_name, key.id())
      key
    }
  }
}

///|
pub impl[A : RenderAssetResource] @app.Resource for RenderAssets[A] with resource() {
  RenderAssets::resource()
}

///|
pub fn[A] RenderAssets::new() -> RenderAssets[A] {
  RenderAssets::{ items: @hashmap.HashMap([]) }
}

///|
pub fn[A] RenderAssets::len(self : RenderAssets[A]) -> Int {
  self.items.length()
}

///|
pub fn[A] RenderAssets::is_empty(self : RenderAssets[A]) -> Bool {
  self.items.is_empty()
}

///|
pub fn[A] RenderAssets::contains(self : RenderAssets[A], id : Int) -> Bool {
  self.items.contains(id)
}

///|
pub fn[A] RenderAssets::get(self : RenderAssets[A], id : Int) -> A? {
  match self.items.get(id) {
    Some(value_ref) => Some(value_ref.val)
    None => None
  }
}

///|
pub fn[A] RenderAssets::get_mut(self : RenderAssets[A], id : Int) -> Ref[A]? {
  self.items.get(id)
}

///|
pub fn[A] RenderAssets::insert(
  self : RenderAssets[A],
  id : Int,
  value : A,
) -> Unit {
  self.items.set(id, Ref(value))
}

///|
pub fn[A] RenderAssets::remove(self : RenderAssets[A], id : Int) -> A? {
  guard self.items.get(id) is Some(value_ref) else { return None }
  self.items.remove(id)
  Some(value_ref.val)
}

///|
pub fn[A] RenderAssets::clear(self : RenderAssets[A]) -> Unit {
  self.items.clear()
}

///|
pub fn[A] RenderAssets::to_array(
  self : RenderAssets[A],
) -> Array[(Int, Ref[A])] {
  self.items.to_array()
}

///|
pub struct PrepareNextFrameAssets[A] {
  values : Array[(Int, A)]
}

///|
pub struct RenderAssetBytesPerFrame {
  max_bytes : Int?
}

///|
let ecs_key_render_asset_bytes_per_frame : @ecs.ResourceKey[
  RenderAssetBytesPerFrame,
] = @ecs.register_resource(
  debug_name="mgstudio_render::RenderAssetBytesPerFrame",
)

///|
pub impl Default for RenderAssetBytesPerFrame with default() {
  RenderAssetBytesPerFrame::{ max_bytes: None }
}

///|
pub impl @app.Resource for RenderAssetBytesPerFrame with resource() {
  ecs_key_render_asset_bytes_per_frame
}

///|
pub fn render_asset_bytes_per_frame_resource_key() -> @ecs.ResourceKey[
  RenderAssetBytesPerFrame,
] {
  ecs_key_render_asset_bytes_per_frame
}

///|
pub fn RenderAssetBytesPerFrame::new(
  max_bytes : Int,
) -> RenderAssetBytesPerFrame {
  RenderAssetBytesPerFrame::{ max_bytes: Some(max_bytes) }
}

///|
pub fn RenderAssetBytesPerFrame::max_bytes(
  self : RenderAssetBytesPerFrame,
) -> Int? {
  self.max_bytes
}

///|
pub struct RenderAssetBytesPerFrameLimiter {
  mut max_bytes : Int?
  mut bytes_written : Int
}

///|
let ecs_key_render_asset_bytes_per_frame_limiter : @ecs.ResourceKey[
  RenderAssetBytesPerFrameLimiter,
] = @ecs.register_resource(
  debug_name="mgstudio_render::RenderAssetBytesPerFrameLimiter",
)

///|
pub impl Default for RenderAssetBytesPerFrameLimiter with default() {
  RenderAssetBytesPerFrameLimiter::{ max_bytes: None, bytes_written: 0 }
}

///|
pub impl @app.Resource for RenderAssetBytesPerFrameLimiter with resource() {
  ecs_key_render_asset_bytes_per_frame_limiter
}

///|
pub fn render_asset_bytes_per_frame_limiter_resource_key() -> @ecs.ResourceKey[
  RenderAssetBytesPerFrameLimiter,
] {
  ecs_key_render_asset_bytes_per_frame_limiter
}

///|
pub fn RenderAssetBytesPerFrameLimiter::new(
  max_bytes : Int,
) -> RenderAssetBytesPerFrameLimiter {
  RenderAssetBytesPerFrameLimiter::{
    max_bytes: Some(max_bytes),
    bytes_written: 0,
  }
}

///|
pub fn RenderAssetBytesPerFrameLimiter::reset(
  self : RenderAssetBytesPerFrameLimiter,
) -> Unit {
  if self.max_bytes is Some(_) {
    self.bytes_written = 0
  }
}

///|
pub fn RenderAssetBytesPerFrameLimiter::extract(
  self : RenderAssetBytesPerFrameLimiter,
  bytes_per_frame : RenderAssetBytesPerFrame,
) -> Unit {
  self.max_bytes = bytes_per_frame.max_bytes()
}

///|
pub fn RenderAssetBytesPerFrameLimiter::bytes_written(
  self : RenderAssetBytesPerFrameLimiter,
) -> Int {
  self.bytes_written
}

///|
pub fn RenderAssetBytesPerFrameLimiter::max_bytes(
  self : RenderAssetBytesPerFrameLimiter,
) -> Int? {
  self.max_bytes
}

///|
pub fn RenderAssetBytesPerFrameLimiter::available_bytes(
  self : RenderAssetBytesPerFrameLimiter,
  required_bytes : Int,
) -> Int {
  match self.max_bytes {
    Some(max_bytes) => {
      let total_bytes = self.bytes_written
      self.bytes_written = self.bytes_written + required_bytes
      if total_bytes >= max_bytes {
        let overshot = total_bytes - max_bytes
        if required_bytes > overshot {
          required_bytes - overshot
        } else {
          0
        }
      } else {
        required_bytes
      }
    }
    None => required_bytes
  }
}

///|
pub fn RenderAssetBytesPerFrameLimiter::write_bytes(
  self : RenderAssetBytesPerFrameLimiter,
  bytes : Int,
) -> Unit {
  if self.max_bytes is Some(_) && bytes > 0 {
    self.bytes_written = self.bytes_written + bytes
  }
}

///|
pub fn RenderAssetBytesPerFrameLimiter::exhausted(
  self : RenderAssetBytesPerFrameLimiter,
) -> Bool {
  match self.max_bytes {
    Some(max_bytes) => self.bytes_written >= max_bytes
    None => false
  }
}

///|
pub fn reset_render_asset_bytes_per_frame(world : @ecs.World) -> Unit {
  match world.get_resource(ecs_key_render_asset_bytes_per_frame_limiter) {
    Some(limiter) => limiter.reset()
    None => ()
  }
}

///|
pub fn extract_render_asset_bytes_per_frame(world : @ecs.World) -> Unit {
  let main_world = render_source_world(world)
  let bytes_per_frame = main_world.get_resource(
    ecs_key_render_asset_bytes_per_frame,
  )
  let limiter = world.get_resource(ecs_key_render_asset_bytes_per_frame_limiter)
  match (bytes_per_frame, limiter) {
    (Some(bytes_per_frame), Some(limiter)) => limiter.extract(bytes_per_frame)
    _ => ()
  }
}

///|
fn prepare_next_frame_assets_debug_name() -> String {
  "mgstudio.render.PrepareNextFrameAssets"
}

///|
pub fn[A : @ecs.EcsPayloadCodec] PrepareNextFrameAssets::resource() -> @ecs.ResourceKey[
  PrepareNextFrameAssets[A],
] {
  @ecs.register_resource(debug_name=prepare_next_frame_assets_debug_name())
}

///|
pub impl[A : @ecs.EcsPayloadCodec] @app.Resource for PrepareNextFrameAssets[A] with resource() {
  PrepareNextFrameAssets::resource()
}

///|
pub fn[A] PrepareNextFrameAssets::new() -> PrepareNextFrameAssets[A] {
  PrepareNextFrameAssets::{ values: [] }
}

///|
pub fn[A] PrepareNextFrameAssets::len(self : PrepareNextFrameAssets[A]) -> Int {
  self.values.length()
}

///|
pub fn[A] PrepareNextFrameAssets::clear(
  self : PrepareNextFrameAssets[A],
) -> Unit {
  self.values.clear()
}

///|
pub fn[A] PrepareNextFrameAssets::take(
  self : PrepareNextFrameAssets[A],
) -> Array[(Int, A)] {
  let values = self.values.copy()
  self.values.clear()
  values
}

///|
pub fn[A] PrepareNextFrameAssets::push(
  self : PrepareNextFrameAssets[A],
  id : Int,
  value : A,
) -> Unit {
  self.values.push((id, value))
}

///|
pub fn[A : RenderAssetResource] prepare_render_assets_resource_key() -> @ecs.ResourceKey[
  RenderAssets[A],
] {
  RenderAssets::resource()
}

///|
pub fn[A, B] prepare_render_assets_with(
  extracted_assets : ExtractedAssets[A],
  render_assets : RenderAssets[B],
  prepare_next_frame : PrepareNextFrameAssets[A],
  prepare_asset : (A, Int, B?) -> Result[B, PrepareAssetError],
  unload_asset : (Int, B?) -> Unit,
  byte_len? : (A) -> Int? = fn(_) { None },
  bytes_per_frame? : RenderAssetBytesPerFrameLimiter = RenderAssetBytesPerFrameLimiter::default(),
) -> Unit {
  let queued_assets = prepare_next_frame.take()
  for entry in queued_assets {
    let (id, extracted_asset) = entry
    if extracted_assets.removed.contains(id) ||
      extracted_assets.added.contains(id) {
      continue
    }
    let write_bytes = match byte_len(extracted_asset) {
      Some(size) =>
        if bytes_per_frame.exhausted() {
          prepare_next_frame.push(id, extracted_asset)
          continue
        } else {
          size
        }
      None => 0
    }
    let previous_asset = render_assets.get(id)
    match prepare_asset(extracted_asset, id, previous_asset) {
      Ok(prepared_asset) => {
        render_assets.insert(id, prepared_asset)
        bytes_per_frame.write_bytes(write_bytes)
      }
      Err(RetryNextUpdate(_)) => prepare_next_frame.push(id, extracted_asset)
      Err(AsBindGroupError(_)) => ()
    }
  }

  for id in extracted_assets.removed.iter() {
    let previous_asset = render_assets.remove(id)
    unload_asset(id, previous_asset)
  }
  extracted_assets.removed.clear()

  let extracted = extracted_assets.extracted.copy()
  extracted_assets.extracted.clear()
  for entry in extracted {
    let (id, extracted_asset) = entry
    let previous_asset = render_assets.remove(id)
    let write_bytes = match byte_len(extracted_asset) {
      Some(size) =>
        if bytes_per_frame.exhausted() {
          prepare_next_frame.push(id, extracted_asset)
          continue
        } else {
          size
        }
      None => 0
    }
    match prepare_asset(extracted_asset, id, previous_asset) {
      Ok(prepared_asset) => {
        render_assets.insert(id, prepared_asset)
        bytes_per_frame.write_bytes(write_bytes)
      }
      Err(RetryNextUpdate(_)) => prepare_next_frame.push(id, extracted_asset)
      Err(AsBindGroupError(_)) => ()
    }
  }
  extracted_assets.modified.clear()
  extracted_assets.added.clear()
}
