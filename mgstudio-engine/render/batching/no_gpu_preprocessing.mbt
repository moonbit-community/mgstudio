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
// Bevy source: `bevy/crates/bevy_render/src/batching/no_gpu_preprocessing.rs`.

///|
pub struct BatchedInstanceBuffer[T] {
  values : @render_resource.GpuArrayBuffer[T]
}

///|
pub fn[T] BatchedInstanceBuffer::new() -> BatchedInstanceBuffer[T] {
  BatchedInstanceBuffer::{ values: @render_resource.GpuArrayBuffer::new() }
}

///|
pub fn[T] BatchedInstanceBuffer::clear(self : BatchedInstanceBuffer[T]) -> Unit {
  self.values.clear()
}

///|
pub fn[T] BatchedInstanceBuffer::push(
  self : BatchedInstanceBuffer[T],
  value : T,
) -> Unit {
  self.values.push(value)
}

///|
pub fn[T] BatchedInstanceBuffer::len(self : BatchedInstanceBuffer[T]) -> Int {
  self.values.len()
}

///|
pub fn[T] BatchedInstanceBuffer::values(
  self : BatchedInstanceBuffer[T],
) -> Array[T] {
  self.values.values()
}

///|
pub fn[T] clear_batched_cpu_instance_buffers(
  buffer : BatchedInstanceBuffer[T]?,
) -> Unit {
  if buffer is Some(buffer_ref) {
    buffer_ref.clear()
  }
}

///|
pub fn[T] batch_and_prepare_sorted_render_phase(
  items : Array[BatchMeta[T]],
  same_user_data : (T, T) -> Bool,
) -> Array[BatchMeta[T]] {
  batch_meta_sort_and_merge(items, same_user_data)
}

///|
pub fn[T] batch_and_prepare_binned_render_phase(
  items : Array[BatchMeta[T]],
  same_user_data : (T, T) -> Bool,
) -> Array[BatchMeta[T]] {
  batch_meta_sort_and_merge(items, same_user_data)
}

///|
pub fn[T] write_batched_instance_buffer(
  buffer : BatchedInstanceBuffer[T],
) -> Array[T] {
  buffer.values()
}
