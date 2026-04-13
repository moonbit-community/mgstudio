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
// Bevy source: `bevy/crates/bevy_render/src/render_resource/buffer_vec.rs`.

///|
pub struct BufferVec[T] {
  values : Array[T]
  buffer_id : BufferId
}

///|
pub fn[T] BufferVec::new() -> BufferVec[T] {
  BufferVec::{ values: [], buffer_id: 0 }
}

///|
pub fn[T] BufferVec::with_buffer_id(buffer_id : BufferId) -> BufferVec[T] {
  BufferVec::{ values: [], buffer_id }
}

///|
pub fn[T] BufferVec::buffer_id(self : BufferVec[T]) -> BufferId {
  self.buffer_id
}

///|
pub fn[T] BufferVec::push(self : BufferVec[T], value : T) -> Unit {
  self.values.push(value)
}

///|
pub fn[T] BufferVec::extend(self : BufferVec[T], values : Array[T]) -> Unit {
  self.values.append(values.view())
}

///|
pub fn[T] BufferVec::clear(self : BufferVec[T]) -> Unit {
  self.values.clear()
}

///|
pub fn[T] BufferVec::len(self : BufferVec[T]) -> Int {
  self.values.length()
}

///|
pub fn[T] BufferVec::is_empty(self : BufferVec[T]) -> Bool {
  self.values.is_empty()
}

///|
pub fn[T] BufferVec::values(self : BufferVec[T]) -> Array[T] {
  self.values
}
