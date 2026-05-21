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
// Bevy source: `bevy/crates/bevy_render/src/render_resource/sparse_buffer_vec.rs`.

///|
pub const SPARSE_BUFFER_UPDATE_WORKGROUP_SIZE : Int = 256

///|
pub const SPARSE_UPLOAD_THRESHOLD : Float = 0.15F

///|
pub const MAX_WORKGROUPS : Int = 65535

///|
pub const REALLOCATION_FACTOR : Float = 1.5F

///|
pub const REALLOCATION_SIZE_MULTIPLE : Int = 256

///|
pub const PAGES_PER_DIRTY_WORD : Int = 32

///|
pub struct SparseBufferId {
  id : UInt64
} derive(Eq, Debug)

///|
pub fn SparseBufferId::new(id : UInt64) -> SparseBufferId {
  SparseBufferId::{ id, }
}

///|
pub fn SparseBufferId::id(self : SparseBufferId) -> UInt64 {
  self.id
}

///|
pub struct GpuSparseBufferUpdateMetadata {
  element_size : Int
  updated_page_count : Int
  page_size_log2 : Int
} derive(Eq, Debug)

///|
pub fn GpuSparseBufferUpdateMetadata::new(
  element_size~ : Int,
  updated_page_count~ : Int,
  page_size_log2~ : Int,
) -> GpuSparseBufferUpdateMetadata {
  if element_size <= 0 {
    abort("sparse buffer element size must be positive")
  }
  if page_size_log2 < 0 {
    abort("sparse buffer page_size_log2 must be non-negative")
  }
  GpuSparseBufferUpdateMetadata::{
    element_size,
    updated_page_count,
    page_size_log2,
  }
}

///|
pub fn GpuSparseBufferUpdateMetadata::element_size(
  self : GpuSparseBufferUpdateMetadata,
) -> Int {
  self.element_size
}

///|
pub fn GpuSparseBufferUpdateMetadata::updated_page_count(
  self : GpuSparseBufferUpdateMetadata,
) -> Int {
  self.updated_page_count
}

///|
pub fn GpuSparseBufferUpdateMetadata::page_size_log2(
  self : GpuSparseBufferUpdateMetadata,
) -> Int {
  self.page_size_log2
}

///|
pub struct SparseBufferUpdateJob {
  updated_page_count : Int
  page_size_log2 : Int
  element_word_size : Int
  label : String
} derive(Eq, Debug)

///|
pub fn SparseBufferUpdateJob::new(
  updated_page_count~ : Int,
  page_size_log2~ : Int,
  element_word_size~ : Int,
  label~ : String,
) -> SparseBufferUpdateJob {
  SparseBufferUpdateJob::{
    updated_page_count,
    page_size_log2,
    element_word_size,
    label,
  }
}

///|
pub fn SparseBufferUpdateJob::page_size(self : SparseBufferUpdateJob) -> Int {
  sparse_buffer_page_size(self.page_size_log2)
}

///|
pub fn SparseBufferUpdateJob::words_to_update(
  self : SparseBufferUpdateJob,
) -> Int {
  self.updated_page_count * self.page_size() * self.element_word_size
}

///|
pub fn SparseBufferUpdateJob::workgroup_count(
  self : SparseBufferUpdateJob,
) -> Int {
  sparse_buffer_div_ceil(
    self.words_to_update(),
    SPARSE_BUFFER_UPDATE_WORKGROUP_SIZE,
  )
}

///|
pub fn SparseBufferUpdateJob::label(self : SparseBufferUpdateJob) -> String {
  self.label
}

///|
pub(all) enum SparseBufferUploadKind {
  FullReupload
  SparseUpload
  NoUpload
} derive(Eq, Debug)

///|
pub struct SparseBufferUploadPlan {
  kind : SparseBufferUploadKind
  pages : Array[Int]
  metadata : GpuSparseBufferUpdateMetadata
  workgroup_count : Int
} derive(Eq, Debug)

///|
pub fn SparseBufferUploadPlan::kind(
  self : SparseBufferUploadPlan,
) -> SparseBufferUploadKind {
  self.kind
}

///|
pub fn SparseBufferUploadPlan::pages(
  self : SparseBufferUploadPlan,
) -> Array[Int] {
  self.pages
}

///|
pub fn SparseBufferUploadPlan::metadata(
  self : SparseBufferUploadPlan,
) -> GpuSparseBufferUpdateMetadata {
  self.metadata
}

///|
pub fn SparseBufferUploadPlan::workgroup_count(
  self : SparseBufferUploadPlan,
) -> Int {
  self.workgroup_count
}

///|
pub struct AtomicSparseBufferVecState {
  mut len : Int
  mut capacity : Int
  element_word_size : Int
  page_size_log2 : Int
  dirty_words : Array[UInt]
  mut needs_full_reupload : Bool
  mut sparse_update_scheduled : Bool
  label : String
} derive(Debug)

///|
pub fn AtomicSparseBufferVecState::new(
  element_word_size~ : Int,
  page_size_log2~ : Int,
  label~ : String,
) -> AtomicSparseBufferVecState {
  if element_word_size <= 0 {
    abort("sparse buffer element_word_size must be positive")
  }
  if page_size_log2 < 0 {
    abort("sparse buffer page_size_log2 must be non-negative")
  }
  AtomicSparseBufferVecState::{
    len: 0,
    capacity: 0,
    element_word_size,
    page_size_log2,
    dirty_words: [],
    needs_full_reupload: false,
    sparse_update_scheduled: false,
    label,
  }
}

///|
pub fn AtomicSparseBufferVecState::len(
  self : AtomicSparseBufferVecState,
) -> Int {
  self.len
}

///|
pub fn AtomicSparseBufferVecState::capacity(
  self : AtomicSparseBufferVecState,
) -> Int {
  self.capacity
}

///|
pub fn AtomicSparseBufferVecState::page_size(
  self : AtomicSparseBufferVecState,
) -> Int {
  sparse_buffer_page_size(self.page_size_log2)
}

///|
pub fn AtomicSparseBufferVecState::is_empty(
  self : AtomicSparseBufferVecState,
) -> Bool {
  self.len == 0
}

///|
pub fn AtomicSparseBufferVecState::reserve(
  self : AtomicSparseBufferVecState,
  new_capacity : Int,
) -> Unit {
  if new_capacity > self.capacity {
    self.capacity = calculate_sparse_buffer_allocation_size(new_capacity)
    self.needs_full_reupload = true
  }
}

///|
pub fn AtomicSparseBufferVecState::push(
  self : AtomicSparseBufferVecState,
) -> Int {
  let index = self.len
  self.len = self.len + 1
  self.note_changed_index(index)
  index
}

///|
pub fn AtomicSparseBufferVecState::grow(
  self : AtomicSparseBufferVecState,
  new_len : Int,
) -> Unit {
  let old_len = self.len
  if old_len >= new_len {
    return
  }
  self.len = new_len
  let mut index = old_len
  while index < new_len {
    self.note_changed_index(index)
    index = index + self.page_size()
  }
}

///|
pub fn AtomicSparseBufferVecState::truncate(
  self : AtomicSparseBufferVecState,
  len : Int,
) -> Unit {
  if len >= self.len {
    return
  }
  self.len = len.max(0)
  let page = self.index_to_page(self.len)
  self.dirty_words.truncate(sparse_buffer_div_ceil(page, PAGES_PER_DIRTY_WORD))
}

///|
pub fn AtomicSparseBufferVecState::clear(
  self : AtomicSparseBufferVecState,
) -> Unit {
  self.truncate(0)
}

///|
pub fn AtomicSparseBufferVecState::note_changed_index(
  self : AtomicSparseBufferVecState,
  index : Int,
) -> Unit {
  if index < 0 {
    abort("sparse buffer index must be non-negative")
  }
  let page = self.index_to_page(index)
  let word_index = page / PAGES_PER_DIRTY_WORD
  let bit_index = page % PAGES_PER_DIRTY_WORD
  while self.dirty_words.length() <= word_index {
    self.dirty_words.push(0U)
  }
  self.dirty_words[word_index] = self.dirty_words[word_index] |
    sparse_buffer_bit(bit_index)
}

///|
pub fn AtomicSparseBufferVecState::index_to_page(
  self : AtomicSparseBufferVecState,
  index : Int,
) -> Int {
  index / self.page_size()
}

///|
pub fn AtomicSparseBufferVecState::dirty_pages(
  self : AtomicSparseBufferVecState,
) -> Array[Int] {
  let pages : Array[Int] = []
  let mut word_index = 0
  while word_index < self.dirty_words.length() {
    let mut word = self.dirty_words[word_index]
    let mut bit_index = 0
    while word != 0U && bit_index < PAGES_PER_DIRTY_WORD {
      if (word & 1U) == 1U {
        pages.push(word_index * PAGES_PER_DIRTY_WORD + bit_index)
      }
      word = word >> 1
      bit_index = bit_index + 1
    }
    word_index = word_index + 1
  }
  pages
}

///|
pub fn AtomicSparseBufferVecState::changed_page_count(
  self : AtomicSparseBufferVecState,
) -> Int {
  self.dirty_pages().length()
}

///|
pub fn AtomicSparseBufferVecState::should_perform_full_reupload(
  self : AtomicSparseBufferVecState,
  max_storage_buffers_per_shader_stage~ : Int,
) -> Bool {
  if self.needs_full_reupload {
    return true
  }
  if max_storage_buffers_per_shader_stage < 3 {
    return true
  }
  sparse_buffer_should_perform_full_reupload(
    changed_page_count=self.changed_page_count(),
    buffer_length=self.len,
    page_size=self.page_size(),
    element_word_size=self.element_word_size,
  )
}

///|
pub fn AtomicSparseBufferVecState::upload_plan(
  self : AtomicSparseBufferVecState,
  max_storage_buffers_per_shader_stage~ : Int,
) -> SparseBufferUploadPlan {
  if self.len == 0 || self.changed_page_count() == 0 {
    return SparseBufferUploadPlan::{
      kind: NoUpload,
      pages: [],
      metadata: GpuSparseBufferUpdateMetadata::new(
        element_size=self.element_word_size,
        updated_page_count=0,
        page_size_log2=self.page_size_log2,
      ),
      workgroup_count: 0,
    }
  }
  let pages = self.dirty_pages()
  let metadata = GpuSparseBufferUpdateMetadata::new(
    element_size=self.element_word_size,
    updated_page_count=pages.length(),
    page_size_log2=self.page_size_log2,
  )
  if self.should_perform_full_reupload(max_storage_buffers_per_shader_stage~) {
    SparseBufferUploadPlan::{
      kind: FullReupload,
      pages,
      metadata,
      workgroup_count: 0,
    }
  } else {
    let job = SparseBufferUpdateJob::new(
      updated_page_count=pages.length(),
      page_size_log2=self.page_size_log2,
      element_word_size=self.element_word_size,
      label=self.label,
    )
    SparseBufferUploadPlan::{
      kind: SparseUpload,
      pages,
      metadata,
      workgroup_count: job.workgroup_count(),
    }
  }
}

///|
pub fn AtomicSparseBufferVecState::mark_uploaded(
  self : AtomicSparseBufferVecState,
  sparse_update_scheduled~ : Bool,
) -> Unit {
  let mut i = 0
  while i < self.dirty_words.length() {
    self.dirty_words[i] = 0U
    i = i + 1
  }
  self.needs_full_reupload = false
  self.sparse_update_scheduled = sparse_update_scheduled
}

///|
pub fn AtomicSparseBufferVecState::sparse_update_scheduled(
  self : AtomicSparseBufferVecState,
) -> Bool {
  self.sparse_update_scheduled
}

///|
pub fn sparse_buffer_page_size(page_size_log2 : Int) -> Int {
  if page_size_log2 < 0 {
    abort("sparse buffer page_size_log2 must be non-negative")
  }
  let mut size = 1
  let mut i = 0
  while i < page_size_log2 {
    size = size * 2
    i = i + 1
  }
  size
}

///|
pub fn sparse_buffer_div_ceil(value : Int, divisor : Int) -> Int {
  if divisor <= 0 {
    abort("sparse buffer divisor must be positive")
  }
  if value <= 0 {
    0
  } else {
    (value + divisor - 1) / divisor
  }
}

///|
pub fn calculate_sparse_buffer_allocation_size(len : Int) -> Int {
  if len <= 0 {
    return 0
  }
  let grown = @float.ceil(Float::from_int(len) * REALLOCATION_FACTOR)
    .to_double()
    .to_int()
  let rounded = sparse_buffer_div_ceil(grown, REALLOCATION_SIZE_MULTIPLE) *
    REALLOCATION_SIZE_MULTIPLE
  rounded.max(REALLOCATION_SIZE_MULTIPLE)
}

///|
pub fn sparse_buffer_should_perform_full_reupload(
  changed_page_count~ : Int,
  buffer_length~ : Int,
  page_size~ : Int,
  element_word_size~ : Int,
) -> Bool {
  let total_changed_word_count = changed_page_count *
    page_size *
    element_word_size
  if total_changed_word_count >
    MAX_WORKGROUPS * SPARSE_BUFFER_UPDATE_WORKGROUP_SIZE {
    return true
  }
  if buffer_length <= 0 {
    return false
  }
  let page_count = sparse_buffer_div_ceil(buffer_length, page_size)
  Float::from_int(changed_page_count) / Float::from_int(page_count) >
  SPARSE_UPLOAD_THRESHOLD
}

///|
fn sparse_buffer_bit(bit_index : Int) -> UInt {
  let mut bit = 1U
  let mut i = 0
  while i < bit_index {
    bit = bit << 1
    i = i + 1
  }
  bit
}
