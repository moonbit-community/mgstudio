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
// Bevy source: `bevy/crates/bevy_render/src/render_resource/storage_buffer.rs`.

///|
pub struct StorageBuffer[T] {
  data : BufferVec[T]
  label : String?
}

///|
pub impl @asset.Asset for StorageBuffer[Float] with asset_debug_name() {
  "mgstudio_render_resource::StorageBuffer<Float>"
}

///|
pub impl @asset.Asset for StorageBuffer[Float] with asset_as_image(_self) {
  None
}

///|
let storage_buffer_float_asset_resource_keys : @asset.AssetResourceKeys[
  StorageBuffer[Float],
] = @asset.register_asset_resource_keys(
  "mgstudio_render_resource::StorageBuffer<Float>",
)

///|
pub impl @asset.Asset for StorageBuffer[Float] with asset_resource_keys() {
  storage_buffer_float_asset_resource_keys
}

///|
pub fn[T] StorageBuffer::new() -> StorageBuffer[T] {
  StorageBuffer::{ data: BufferVec::new(), label: None }
}

///|
pub fn[T] StorageBuffer::with_label(label : String) -> StorageBuffer[T] {
  StorageBuffer::{ data: BufferVec::new(), label: Some(label) }
}

///|
pub fn[T] StorageBuffer::push(self : StorageBuffer[T], value : T) -> Unit {
  self.data.push(value)
}

///|
pub fn[T] StorageBuffer::clear(self : StorageBuffer[T]) -> Unit {
  self.data.clear()
}

///|
pub fn[T] StorageBuffer::len(self : StorageBuffer[T]) -> Int {
  self.data.len()
}

///|
pub fn[T] StorageBuffer::label(self : StorageBuffer[T]) -> String? {
  self.label
}

///|
pub fn[T] StorageBuffer::values(self : StorageBuffer[T]) -> Array[T] {
  self.data.values()
}
