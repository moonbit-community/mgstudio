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
test "render_resource sparse buffer: tracks dirty pages and sparse upload plan" {
  let state = AtomicSparseBufferVecState::new(
    element_word_size=4,
    page_size_log2=2,
    label="test sparse buffer",
  )
  let mut i = 0
  while i < 64 {
    state.push() |> ignore
    i = i + 1
  }
  state.mark_uploaded(sparse_update_scheduled=false)
  state.note_changed_index(0)
  state.note_changed_index(15)
  let plan = state.upload_plan(max_storage_buffers_per_shader_stage=3)
  debug_inspect(plan.kind(), content="SparseUpload")
  debug_inspect(plan.pages().length(), content="2")
  debug_inspect(plan.metadata().updated_page_count(), content="2")
  debug_inspect(plan.workgroup_count(), content="1")
}

///|
test "render_resource sparse buffer: full upload when shader storage limit is too low" {
  let state = AtomicSparseBufferVecState::new(
    element_word_size=1,
    page_size_log2=3,
    label="limited sparse buffer",
  )
  let mut i = 0
  while i < 16 {
    state.push() |> ignore
    i = i + 1
  }
  let plan = state.upload_plan(max_storage_buffers_per_shader_stage=2)
  debug_inspect(plan.kind(), content="FullReupload")
}
