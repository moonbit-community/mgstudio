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
// Bevy source: `bevy/crates/bevy_render/src/render_resource/buffer.rs`.

///|
pub struct Buffer {
  id : BufferId
  value : @wgpu.Buffer
}

///|
pub struct BufferSlice {
  buffer_id : BufferId
  start : BufferAddress
  end : BufferAddress
}

///|
pub fn Buffer::new(value : @wgpu.Buffer) -> Buffer {
  Buffer::{ id: next_buffer_id(), value }
}

///|
pub fn Buffer::from_wgpu(value : @wgpu.Buffer) -> Buffer {
  Buffer::new(value)
}

///|
pub fn Buffer::id(self : Buffer) -> BufferId {
  self.id
}

///|
pub fn Buffer::slice(
  self : Buffer,
  start : BufferAddress,
  end : BufferAddress,
) -> BufferSlice {
  BufferSlice::{ buffer_id: self.id, start, end }
}

///|
pub fn Buffer::unmap(self : Buffer) -> Unit {
  self.value.unmap()
}

///|
pub fn Buffer::destroy(self : Buffer) -> Unit {
  self.value.destroy()
}

///|
pub fn Buffer::into_inner(self : Buffer) -> @wgpu.Buffer {
  self.value
}

///|
pub fn BufferSlice::id(self : BufferSlice) -> BufferId {
  self.buffer_id
}

///|
pub fn BufferSlice::range(self : BufferSlice) -> (BufferAddress, BufferAddress) {
  (self.start, self.end)
}
