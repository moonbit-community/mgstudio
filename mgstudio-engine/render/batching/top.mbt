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
// Bevy source: `bevy/crates/bevy_render/src/batching/mod.rs`.

///|
pub struct NoAutomaticBatching {}

///|
pub fn NoAutomaticBatching::default() -> NoAutomaticBatching {
  NoAutomaticBatching::{  }
}

///|
pub struct BatchMeta[T] {
  pipeline_id : Int
  draw_function_id : Int
  dynamic_offset : Int?
  user_data : T
}

///|
pub fn[T] BatchMeta::new(
  pipeline_id : Int,
  draw_function_id : Int,
  dynamic_offset : Int?,
  user_data : T,
) -> BatchMeta[T] {
  BatchMeta::{ pipeline_id, draw_function_id, dynamic_offset, user_data }
}

///|
fn compare_optional_int(left : Int?, right : Int?) -> Int {
  match (left, right) {
    (None, None) => 0
    (None, Some(_)) => -1
    (Some(_), None) => 1
    (Some(left_value), Some(right_value)) => left_value - right_value
  }
}

///|
pub fn[T] BatchMeta::can_merge(
  self : BatchMeta[T],
  other : BatchMeta[T],
  same_user_data : (T, T) -> Bool,
) -> Bool {
  self.pipeline_id == other.pipeline_id &&
  self.draw_function_id == other.draw_function_id &&
  self.dynamic_offset == other.dynamic_offset &&
  same_user_data(self.user_data, other.user_data)
}

///|
pub fn[T] batch_meta_sort(items : Array[BatchMeta[T]]) -> Array[BatchMeta[T]] {
  items.sort_by(fn(left, right) {
    let pipeline_cmp = left.pipeline_id - right.pipeline_id
    if pipeline_cmp != 0 {
      return pipeline_cmp
    }
    let draw_function_cmp = left.draw_function_id - right.draw_function_id
    if draw_function_cmp != 0 {
      return draw_function_cmp
    }
    compare_optional_int(left.dynamic_offset, right.dynamic_offset)
  })
  items
}

///|
pub fn[T] batch_meta_merge_adjacent(
  items : Array[BatchMeta[T]],
  same_user_data : (T, T) -> Bool,
) -> Array[BatchMeta[T]] {
  let merged : Array[BatchMeta[T]] = []
  for item in items {
    if merged.length() == 0 {
      merged.push(item)
      continue
    }
    let last_index = merged.length() - 1
    let last = merged[last_index]
    if last.can_merge(item, same_user_data) {
      merged[last_index] = item
    } else {
      merged.push(item)
    }
  }
  merged
}

///|
pub fn[T] batch_meta_sort_and_merge(
  items : Array[BatchMeta[T]],
  same_user_data : (T, T) -> Bool,
) -> Array[BatchMeta[T]] {
  batch_meta_merge_adjacent(batch_meta_sort(items), same_user_data)
}
