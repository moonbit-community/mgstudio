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
// Bevy source: `bevy/crates/bevy_pbr/src/meshlet/persistent_buffer.rs`.

///|
pub(open) trait PersistentGpuBufferable {}

///|
pub struct PersistentGpuBuffer[T] {
  elements : Array[T]
}

///|
pub fn[T] PersistentGpuBuffer::new() -> PersistentGpuBuffer[T] {
  PersistentGpuBuffer::{ elements: [] }
}

///|
pub fn[T] PersistentGpuBuffer::len(self : PersistentGpuBuffer[T]) -> Int {
  self.elements.length()
}

///|
pub fn[T] PersistentGpuBuffer::clear(self : PersistentGpuBuffer[T]) -> Unit {
  self.elements.clear()
}

///|
pub fn[T] PersistentGpuBuffer::push(
  self : PersistentGpuBuffer[T],
  value : T,
) -> Unit {
  self.elements.push(value)
}

///|
pub fn[T] PersistentGpuBuffer::snapshot(
  self : PersistentGpuBuffer[T],
) -> Array[T] {
  self.elements
}

///|
pub fn meshlet_persistent_buffer_runtime_available() -> Bool {
  meshlet_runtime_available()
}
