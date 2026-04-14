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
test "pbr meshlet: persistent buffer supports extend and clear" {
  let buffer = PersistentGpuBuffer::new(label="meshlet_test_buffer")
  buffer.extend([1, 2, 3])
  inspect(buffer.len(), content="3")
  inspect(buffer.is_empty(), content="false")
  buffer.clear()
  inspect(buffer.len(), content="0")
}

///|
test "pbr meshlet: persistent buffer tracks queued writes and committed writes" {
  let buffer = PersistentGpuBuffer::new()
  let slice0 = buffer.queue_write([10, 11], ())
  let slice1 = buffer.queue_write([12], ())
  debug_inspect(slice0, content="{ start: 0, end_: 2 }")
  debug_inspect(slice1, content="{ start: 2, end_: 3 }")
  inspect(buffer.pending_write_count(), content="2")
  inspect(buffer.perform_writes(), content="2")
  inspect(buffer.pending_write_count(), content="0")
  inspect(buffer.committed_write_count(), content="2")
}

///|
test "pbr meshlet: persistent buffer tracks unused slices" {
  let buffer = PersistentGpuBuffer::new()
  let slice = buffer.queue_write([1, 2, 3], ())
  buffer.mark_slice_unused(slice)
  inspect(buffer.unused_slice_count(), content="1")
}

///|
test "pbr meshlet: persistent buffer reuses free ranges" {
  let buffer = PersistentGpuBuffer::new()
  let slice0 = buffer.queue_write([1, 2, 3], ())
  let _slice1 = buffer.queue_write([4, 5], ())
  buffer.mark_slice_unused(slice0)
  let reused = buffer.queue_write([9, 9], ())
  debug_inspect(reused, content="{ start: 0, end_: 2 }")
}

///|
test "pbr meshlet: persistent buffer merges overlapping unused ranges" {
  let buffer = PersistentGpuBuffer::new()
  let a = buffer.queue_write([1, 2], ())
  let b = buffer.queue_write([3, 4], ())
  buffer.mark_slice_unused(a)
  buffer.mark_slice_unused(b)
  inspect(buffer.unused_slice_count(), content="1")
}
