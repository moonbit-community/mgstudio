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
// Bevy source: `bevy/crates/bevy_render/src/render_resource/uniform_buffer.rs`.

///|
pub struct UniformBuffer[T] {
  mut value : T?
  mut dirty : Bool
}

///|
pub fn[T] UniformBuffer::new() -> UniformBuffer[T] {
  { value: None, dirty: false }
}

///|
pub fn[T] UniformBuffer::with_value(value : T) -> UniformBuffer[T] {
  { value: Some(value), dirty: true }
}

///|
pub fn[T] UniformBuffer::set(self : UniformBuffer[T], value : T) -> Unit {
  self.value = Some(value)
  self.dirty = true
}

///|
pub fn[T] UniformBuffer::take(self : UniformBuffer[T]) -> T? {
  self.value
}

///|
pub fn[T] UniformBuffer::is_dirty(self : UniformBuffer[T]) -> Bool {
  self.dirty
}

///|
pub fn[T] UniformBuffer::clear_dirty(self : UniformBuffer[T]) -> Unit {
  self.dirty = false
}

///|
pub struct DynamicUniformBuffer[T] {
  values : Array[T]
}

///|
pub fn[T] DynamicUniformBuffer::new() -> DynamicUniformBuffer[T] {
  { values: [] }
}

///|
pub fn[T] DynamicUniformBuffer::push(
  self : DynamicUniformBuffer[T],
  value : T,
) -> Unit {
  self.values.push(value)
}

///|
pub fn[T] DynamicUniformBuffer::clear(self : DynamicUniformBuffer[T]) -> Unit {
  self.values.clear()
}

///|
pub fn[T] DynamicUniformBuffer::len(self : DynamicUniformBuffer[T]) -> Int {
  self.values.length()
}

///|
pub fn[T] DynamicUniformBuffer::values(
  self : DynamicUniformBuffer[T],
) -> Array[T] {
  self.values
}
