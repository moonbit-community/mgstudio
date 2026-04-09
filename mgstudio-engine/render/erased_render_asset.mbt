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
// Bevy source: `bevy/crates/bevy_render/src/erased_render_asset.rs`.

///|
pub type UntypedRenderAssetId = Int

///|
pub(all) suberror ErasedPrepareAssetError {
  RetryNextUpdate(String)
  AsBindGroupError(String)
}

///|
pub struct ErasedAssetExtractionSystems {}

///|
pub struct ErasedRenderAssets[A] {
  items : @hashmap.HashMap[UntypedRenderAssetId, Ref[A]]
}

///|
fn[A] erased_render_assets_debug_name() -> String {
  let probe : ErasedRenderAssets[A] = ErasedRenderAssets::new()
  "bevy_render::ErasedRenderAssets<\{@any.of(probe).type_name()}>"
}

///|
pub fn[A] ErasedRenderAssets::resource() -> @ecs.ResourceKey[
  ErasedRenderAssets[A],
] {
  @ecs.register_resource(debug_name=erased_render_assets_debug_name())
}

///|
pub impl[A] @app.Resource for ErasedRenderAssets[A] with resource() {
  ErasedRenderAssets::resource()
}

///|
pub fn[A] ErasedRenderAssets::new() -> ErasedRenderAssets[A] {
  ErasedRenderAssets::{ items: @hashmap.HashMap::new() }
}

///|
pub fn[A] ErasedRenderAssets::len(self : ErasedRenderAssets[A]) -> Int {
  self.items.length()
}

///|
pub fn[A] ErasedRenderAssets::is_empty(self : ErasedRenderAssets[A]) -> Bool {
  self.items.is_empty()
}

///|
pub fn[A] ErasedRenderAssets::contains(
  self : ErasedRenderAssets[A],
  id : UntypedRenderAssetId,
) -> Bool {
  self.items.contains(id)
}

///|
pub fn[A] ErasedRenderAssets::get(
  self : ErasedRenderAssets[A],
  id : UntypedRenderAssetId,
) -> A? {
  match self.items.get(id) {
    Some(value_ref) => Some(value_ref.val)
    None => None
  }
}

///|
pub fn[A] ErasedRenderAssets::get_mut(
  self : ErasedRenderAssets[A],
  id : UntypedRenderAssetId,
) -> Ref[A]? {
  self.items.get(id)
}

///|
pub fn[A] ErasedRenderAssets::insert(
  self : ErasedRenderAssets[A],
  id : UntypedRenderAssetId,
  value : A,
) -> Unit {
  self.items.set(id, Ref::new(value))
}

///|
pub fn[A] ErasedRenderAssets::remove(
  self : ErasedRenderAssets[A],
  id : UntypedRenderAssetId,
) -> A? {
  guard self.items.get(id) is Some(value_ref) else { return None }
  self.items.remove(id)
  Some(value_ref.val)
}

///|
pub fn[A] ErasedRenderAssets::clear(self : ErasedRenderAssets[A]) -> Unit {
  self.items.clear()
}

///|
pub fn[A] ErasedRenderAssets::to_array(
  self : ErasedRenderAssets[A],
) -> Array[(UntypedRenderAssetId, Ref[A])] {
  self.items.to_array()
}

///|
pub struct ErasedPrepareNextFrameAssets[A] {
  values : Array[(UntypedRenderAssetId, A)]
}

///|
fn[A] erased_prepare_next_frame_assets_debug_name() -> String {
  let probe : ErasedPrepareNextFrameAssets[A] = ErasedPrepareNextFrameAssets::new()
  "bevy_render::ErasedPrepareNextFrameAssets<\{@any.of(probe).type_name()}>"
}

///|
pub fn[A] ErasedPrepareNextFrameAssets::resource() -> @ecs.ResourceKey[
  ErasedPrepareNextFrameAssets[A],
] {
  @ecs.register_resource(
    debug_name=erased_prepare_next_frame_assets_debug_name(),
  )
}

///|
pub impl[A] @app.Resource for ErasedPrepareNextFrameAssets[A] with resource() {
  ErasedPrepareNextFrameAssets::resource()
}

///|
pub fn[A] ErasedPrepareNextFrameAssets::new() -> ErasedPrepareNextFrameAssets[A] {
  ErasedPrepareNextFrameAssets::{ values: [] }
}

///|
pub fn[A] ErasedPrepareNextFrameAssets::len(
  self : ErasedPrepareNextFrameAssets[A],
) -> Int {
  self.values.length()
}

///|
pub fn[A] ErasedPrepareNextFrameAssets::clear(
  self : ErasedPrepareNextFrameAssets[A],
) -> Unit {
  self.values.clear()
}

///|
pub fn[A] ErasedPrepareNextFrameAssets::push(
  self : ErasedPrepareNextFrameAssets[A],
  id : UntypedRenderAssetId,
  value : A,
) -> Unit {
  self.values.push((id, value))
}
