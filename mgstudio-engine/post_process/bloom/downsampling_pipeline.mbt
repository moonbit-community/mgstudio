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

///|
// Bevy source: `bevy/crates/bevy_post_process/src/bloom/downsampling_pipeline.rs`.
// Host-side bloom downsample pass planning from the stable root bloom settings.

///|
pub struct BloomDownsamplePass {
  mip_level : Int
  width : Int
  height : Int
  threshold : Float
  threshold_softness : Float
} derive(ToJson, FromJson)

///|
pub fn bloom_downsample_passes(
  settings : Bloom,
  viewport_width : Int,
  viewport_height : Int,
) -> Array[BloomDownsamplePass] {
  let passes : Array[BloomDownsamplePass] = []
  let mut width = bloom_downsample_limit(
    viewport_width,
    settings.max_mip_dimension,
  )
  let mut height = bloom_downsample_limit(
    viewport_height,
    settings.max_mip_dimension,
  )
  let mut mip_level = 0
  while width > 1 || height > 1 {
    width = bloom_downsample_next_extent(width)
    height = bloom_downsample_next_extent(height)
    passes.push(BloomDownsamplePass::{
      mip_level,
      width,
      height,
      threshold: settings.prefilter.threshold,
      threshold_softness: settings.prefilter.threshold_softness,
    })
    mip_level = mip_level + 1
    if width == 1 && height == 1 {
      break
    }
  }
  passes
}

///|
fn bloom_downsample_limit(value : Int, max_dimension : Int) -> Int {
  let safe_value = if value <= 0 { 1 } else { value }
  if safe_value < max_dimension {
    safe_value
  } else {
    max_dimension
  }
}

///|
fn bloom_downsample_next_extent(value : Int) -> Int {
  let next_value = value / 2
  if next_value <= 0 {
    1
  } else {
    next_value
  }
}
