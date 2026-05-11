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
  render_asset_resource_debug_name() -> String
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
fn prepare_next_frame_assets_debug_name() -> String {
  "mgstudio.render.PrepareNextFrameAssets"
}

///|
pub fn[A] PrepareNextFrameAssets::resource() -> @ecs.ResourceKey[
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
