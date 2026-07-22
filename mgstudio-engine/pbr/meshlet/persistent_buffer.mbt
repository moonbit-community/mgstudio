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
pub struct PersistentBufferSliceRange {
  start : Int
  end_ : Int
} derive(Eq, Debug)

///|
fn persistent_buffer_safe_slice_range(
  start : Int,
  end_ : Int,
) -> PersistentBufferSliceRange {
  let safe_start = if start < 0 { 0 } else { start }
  let safe_end = if end_ < safe_start { safe_start } else { end_ }
  { start: safe_start, end_: safe_end }
}

///|
pub struct PersistentGpuBuffer[T] {
  label : String
  element_byte_size : Int
  mut allocated_byte_len : Int
  elements : Array[T]
  pending_write_ranges : Array[PersistentBufferSliceRange]
  free_ranges : Array[PersistentBufferSliceRange]
  mut committed_write_count : Int
}

///|
fn persistent_buffer_safe_element_byte_size(value : Int) -> Int {
  if value <= 0 {
    1
  } else {
    value
  }
}

///|
pub fn[T] PersistentGpuBuffer::new(
  label? : String = "meshlet_persistent_buffer",
  element_byte_size? : Int = 1,
) -> PersistentGpuBuffer[T] {
  {
    label,
    element_byte_size: persistent_buffer_safe_element_byte_size(
      element_byte_size,
    ),
    allocated_byte_len: 0,
    elements: [],
    pending_write_ranges: [],
    free_ranges: [],
    committed_write_count: 0,
  }
}

///|
pub fn[T] PersistentGpuBuffer::label(self : PersistentGpuBuffer[T]) -> String {
  self.label
}

///|
pub fn[T] PersistentGpuBuffer::element_byte_size(
  self : PersistentGpuBuffer[T],
) -> Int {
  self.element_byte_size
}

///|
pub fn[T] PersistentGpuBuffer::allocated_byte_len(
  self : PersistentGpuBuffer[T],
) -> Int {
  self.allocated_byte_len
}

///|
pub fn[T] PersistentGpuBuffer::len(self : PersistentGpuBuffer[T]) -> Int {
  self.elements.length()
}

///|
pub fn[T] PersistentGpuBuffer::is_empty(self : PersistentGpuBuffer[T]) -> Bool {
  self.elements.length() == 0
}

///|
pub fn[T] PersistentGpuBuffer::clear(self : PersistentGpuBuffer[T]) -> Unit {
  self.elements.clear()
  self.pending_write_ranges.clear()
  self.free_ranges.clear()
  self.allocated_byte_len = 0
}

///|
pub fn[T] PersistentGpuBuffer::push(
  self : PersistentGpuBuffer[T],
  value : T,
) -> Unit {
  ignore(self.queue_write([value], ()))
}

///|
pub fn[T] PersistentGpuBuffer::push_all(
  self : PersistentGpuBuffer[T],
  values : Array[T],
) -> Unit {
  ignore(self.queue_write(values, ()))
}

///|
pub fn[T, M] PersistentGpuBuffer::queue_write(
  self : PersistentGpuBuffer[T],
  values : Array[T],
  _metadata : M,
) -> PersistentBufferSliceRange {
  let write_len = values.length()
  let data_size = write_len * self.element_byte_size
  if write_len == 0 {
    let range = persistent_buffer_safe_slice_range(
      self.allocated_byte_len,
      self.allocated_byte_len,
    )
    self.pending_write_ranges.push(range)
    return range
  }
  let free_index = persistent_buffer_find_free_range(
    self.free_ranges,
    data_size,
  )
  let (start, end_) = match free_index {
    Some(index) => {
      let free_range = self.free_ranges[index]
      let allocated_start = free_range.start
      let allocated_end = allocated_start + data_size
      if allocated_end >= free_range.end_ {
        ignore(self.free_ranges.remove(index))
      } else {
        self.free_ranges[index] = persistent_buffer_safe_slice_range(
          allocated_end,
          free_range.end_,
        )
      }
      (allocated_start, allocated_end)
    }
    None => {
      let allocated_start = self.allocated_byte_len
      self.allocated_byte_len = self.allocated_byte_len + data_size
      (allocated_start, self.allocated_byte_len)
    }
  }
  let element_start = start / self.element_byte_size
  let required_len = element_start + write_len
  if required_len <= self.elements.length() {
    for index in 0..<write_len {
      self.elements[element_start + index] = values[index]
    }
  } else {
    let mut index = 0
    while index < write_len {
      let target = element_start + index
      if target < self.elements.length() {
        self.elements[target] = values[index]
      } else {
        self.elements.push(values[index])
      }
      index = index + 1
    }
  }
  let range = persistent_buffer_safe_slice_range(start, end_)
  self.pending_write_ranges.push(range)
  range
}

///|
pub fn[T] PersistentGpuBuffer::mark_slice_unused(
  self : PersistentGpuBuffer[T],
  slice_range : PersistentBufferSliceRange,
) -> Unit {
  let safe_range = persistent_buffer_safe_slice_range(
    slice_range.start,
    slice_range.end_,
  )
  if safe_range.start == safe_range.end_ {
    return ()
  }
  persistent_buffer_insert_free_range(self.free_ranges, safe_range)
  persistent_buffer_merge_free_ranges(self.free_ranges)
}

///|
pub fn[T] PersistentGpuBuffer::perform_writes(
  self : PersistentGpuBuffer[T],
) -> Int {
  let pending_count = self.pending_write_ranges.length()
  self.pending_write_ranges.clear()
  self.committed_write_count = self.committed_write_count + pending_count
  pending_count
}

///|
pub fn[T] PersistentGpuBuffer::pending_write_count(
  self : PersistentGpuBuffer[T],
) -> Int {
  self.pending_write_ranges.length()
}

///|
pub fn[T] PersistentGpuBuffer::committed_write_count(
  self : PersistentGpuBuffer[T],
) -> Int {
  self.committed_write_count
}

///|
pub fn[T] PersistentGpuBuffer::unused_slice_count(
  self : PersistentGpuBuffer[T],
) -> Int {
  self.free_ranges.length()
}

///|
pub fn[T] PersistentGpuBuffer::pending_ranges_snapshot(
  self : PersistentGpuBuffer[T],
) -> Array[PersistentBufferSliceRange] {
  self.pending_write_ranges
}

///|
pub fn[T] PersistentGpuBuffer::snapshot(
  self : PersistentGpuBuffer[T],
) -> Array[T] {
  self.elements
}

///|
fn persistent_buffer_find_free_range(
  free_ranges : Array[PersistentBufferSliceRange],
  write_len : Int,
) -> Int? {
  let mut index = 0
  while index < free_ranges.length() {
    let range = free_ranges[index]
    if range.end_ - range.start >= write_len {
      return Some(index)
    }
    index = index + 1
  }
  None
}

///|
fn persistent_buffer_merge_free_ranges(
  free_ranges : Array[PersistentBufferSliceRange],
) -> Unit {
  if free_ranges.length() <= 1 {
    return ()
  }
  let merged : Array[PersistentBufferSliceRange] = []
  let mut current = free_ranges[0]
  for index in 1..<free_ranges.length() {
    let next = free_ranges[index]
    if next.start <= current.end_ {
      current = persistent_buffer_safe_slice_range(
        current.start,
        if next.end_ > current.end_ {
          next.end_
        } else {
          current.end_
        },
      )
    } else {
      merged.push(current)
      current = next
    }
  }
  merged.push(current)
  free_ranges.clear()
  for range in merged {
    free_ranges.push(range)
  }
}

///|
fn persistent_buffer_insert_free_range(
  free_ranges : Array[PersistentBufferSliceRange],
  range : PersistentBufferSliceRange,
) -> Unit {
  let mut index = 0
  while index < free_ranges.length() && free_ranges[index].start < range.start {
    index = index + 1
  }
  free_ranges.insert(index, range)
}
