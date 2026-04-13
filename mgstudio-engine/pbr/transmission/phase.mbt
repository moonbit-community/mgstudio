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
// Bevy source: `bevy/crates/bevy_pbr/src/transmission/phase.rs`.

///|
pub struct Transmissive3d {
  distance : Float
  pipeline_id : Int
  render_entity : @core.Entity
  main_entity : @core.Entity
  draw_function_id : Int
  batch_range_start : Int
  batch_range_end : Int
  indexed : Bool
} derive(ToJson, FromJson)

///|
pub fn Transmissive3d::new(
  render_entity : @core.Entity,
  main_entity : @core.Entity,
  distance : Float,
  pipeline_id : Int,
  draw_function_id : Int,
  batch_range_start : Int,
  batch_range_end : Int,
  indexed : Bool,
) -> Transmissive3d {
  let safe_batch_start = if batch_range_start < 0 {
    0
  } else {
    batch_range_start
  }
  let safe_batch_end = if batch_range_end < safe_batch_start {
    safe_batch_start
  } else {
    batch_range_end
  }
  Transmissive3d::{
    distance,
    pipeline_id,
    render_entity,
    main_entity,
    draw_function_id,
    batch_range_start: safe_batch_start,
    batch_range_end: safe_batch_end,
    indexed,
  }
}

///|
pub fn Transmissive3d::simple(
  render_entity : @core.Entity,
  main_entity : @core.Entity,
  distance : Float,
  pipeline_id : Int,
  draw_function_id : Int,
) -> Transmissive3d {
  Transmissive3d::new(
    render_entity, main_entity, distance, pipeline_id, draw_function_id, 0, 1, false,
  )
}

///|
pub fn Transmissive3d::sort_key(self : Transmissive3d) -> Float {
  self.distance
}

///|
pub fn Transmissive3d::batch_len(self : Transmissive3d) -> Int {
  self.batch_range_end - self.batch_range_start
}

///|
pub fn transmissive3d_sort(
  items : Array[Transmissive3d],
) -> Array[Transmissive3d] {
  // Match Bevy's back-to-front transmissive ordering.
  items.sort_by(fn(a, b) {
    if a.distance < b.distance {
      -1
    } else if a.distance > b.distance {
      1
    } else {
      let a_main = a.main_entity.to_bits()
      let b_main = b.main_entity.to_bits()
      if a_main < b_main {
        -1
      } else if a_main > b_main {
        1
      } else {
        0
      }
    }
  })
  items
}

///|
pub fn transmissive3d_split_range(
  length : Int,
  max_num_splits : Int,
) -> Array[(Int, Int)] {
  if length <= 0 || max_num_splits <= 0 {
    return []
  }
  let num_splits = if max_num_splits < length { max_num_splits } else { length }
  let step = length / num_splits
  let ranges : Array[(Int, Int)] = []
  let mut rem = length % num_splits
  let mut start = 0
  for _ in 0..<num_splits {
    let extra = if rem > 0 {
      rem = rem - 1
      1
    } else {
      0
    }
    let end_ = start + step + extra
    ranges.push((start, end_))
    start = end_
  }
  ranges
}

///|
pub fn transmissive3d_render_step_ranges(
  items : Array[Transmissive3d],
  transmission : ScreenSpaceTransmission,
) -> Array[(Int, Int)] {
  let steps = if transmission.steps <= 0 { 1 } else { transmission.steps }
  transmissive3d_split_range(items.length(), steps)
}
