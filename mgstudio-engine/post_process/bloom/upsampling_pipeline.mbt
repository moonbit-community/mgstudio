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
// Bevy source: `bevy/crates/bevy_post_process/src/bloom/upsampling_pipeline.rs`.
// Host-side bloom upsample pass planning from the downsample chain.

///|
pub struct BloomUpsamplePass {
  source_mip_level : Int
  target_mip_level : Int
  width : Int
  height : Int
  blend_factor : Float
  additive : Bool
} derive(ToJson, FromJson)

///|
pub fn bloom_upsample_passes(
  settings : Bloom,
  downsample_passes : Array[BloomDownsamplePass],
) -> Array[BloomUpsamplePass] {
  let passes : Array[BloomUpsamplePass] = []
  if downsample_passes.length() <= 1 {
    return passes
  }
  let total_levels = downsample_passes.length()
  for index in 1..<total_levels {
    let reverse_index = total_levels - index
    let source_pass = downsample_passes[reverse_index]
    let target_pass = downsample_passes[reverse_index - 1]
    let normalized_level = Float::from_double(reverse_index.to_double()) /
      Float::from_double(total_levels.to_double())
    passes.push(BloomUpsamplePass::{
      source_mip_level: source_pass.mip_level,
      target_mip_level: target_pass.mip_level,
      width: target_pass.width,
      height: target_pass.height,
      blend_factor: settings.intensity * (1.0F - normalized_level * 0.5F),
      additive: settings.composite_mode == BloomCompositeMode::Additive,
    })
  }
  passes
}
