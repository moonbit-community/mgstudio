// Copyright 2025 International Digital Economy Academy
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

// Bevy source: `bevy/crates/bevy_tasks/src/slice.rs`.

///|
pub type ParallelSlice[T] = Array[T]

///|
pub type ParallelSliceMut[T] = Array[T]

///|
fn normalize_chunk_size(
  total_len : Int,
  thread_num : Int,
  max_tasks : Int?,
) -> Int {
  let safe_threads = if thread_num <= 0 { 1 } else { thread_num }
  let task_limit = max_tasks.unwrap_or(2147483647)
  let by_threads = if safe_threads <= 0 {
    total_len
  } else {
    total_len / safe_threads
  }
  let by_limit = if task_limit <= 0 {
    total_len
  } else {
    total_len / task_limit
  }
  let raw = if by_threads > by_limit { by_threads } else { by_limit }
  if raw <= 0 {
    1
  } else {
    raw
  }
}

///|
pub fn[T, R] par_chunk_map(
  values : Array[T],
  _task_pool : TaskPool,
  chunk_size : Int,
  map : (Int, Array[T]) -> R,
) -> Array[R] {
  let size = if chunk_size <= 0 { 1 } else { chunk_size }
  let out : Array[R] = []
  let mut start = 0
  let mut index = 0
  while start < values.length() {
    let mut end = start + size
    if end > values.length() {
      end = values.length()
    }
    let chunk : Array[T] = []
    for i in start..<end {
      chunk.push(values[i])
    }
    out.push(map(index, chunk))
    start = end
    index = index + 1
  }
  out
}

///|
pub fn[T, R] par_splat_map(
  values : Array[T],
  task_pool : TaskPool,
  max_tasks : Int?,
  map : (Int, Array[T]) -> R,
) -> Array[R] {
  let chunk_size = normalize_chunk_size(
    values.length(),
    task_pool.thread_num(),
    max_tasks,
  )
  par_chunk_map(values, task_pool, chunk_size, map)
}

///|
pub fn[T, R] par_chunk_map_mut(
  values : Array[T],
  task_pool : TaskPool,
  chunk_size : Int,
  map : (Int, Array[T]) -> R,
) -> Array[R] {
  par_chunk_map(values, task_pool, chunk_size, map)
}

///|
pub fn[T, R] par_splat_map_mut(
  values : Array[T],
  task_pool : TaskPool,
  max_tasks : Int?,
  map : (Int, Array[T]) -> R,
) -> Array[R] {
  par_splat_map(values, task_pool, max_tasks, map)
}
