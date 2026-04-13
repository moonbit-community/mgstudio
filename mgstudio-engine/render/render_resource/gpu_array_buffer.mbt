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
// Bevy source: `bevy/crates/bevy_render/src/render_resource/gpu_array_buffer.rs`.

///|
pub struct GpuArrayBuffer[T] {
  values : Array[T]
  buffer_id : BufferId
}

///|
pub fn[T] GpuArrayBuffer::new() -> GpuArrayBuffer[T] {
  GpuArrayBuffer::{ values: [], buffer_id: 0 }
}

///|
pub fn[T] GpuArrayBuffer::push(self : GpuArrayBuffer[T], value : T) -> Unit {
  self.values.push(value)
}

///|
pub fn[T] GpuArrayBuffer::clear(self : GpuArrayBuffer[T]) -> Unit {
  self.values.clear()
}

///|
pub fn[T] GpuArrayBuffer::len(self : GpuArrayBuffer[T]) -> Int {
  self.values.length()
}

///|
pub fn[T] GpuArrayBuffer::buffer_id(self : GpuArrayBuffer[T]) -> BufferId {
  self.buffer_id
}

///|
pub fn[T] GpuArrayBuffer::values(self : GpuArrayBuffer[T]) -> Array[T] {
  self.values
}
