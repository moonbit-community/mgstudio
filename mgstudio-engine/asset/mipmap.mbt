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
fn mip_min_int(a : Int, b : Int) -> Int {
  if a < b {
    a
  } else {
    b
  }
}

///|
fn mip_rgba_at(
  pixels : Bytes,
  width : Int,
  x : Int,
  y : Int,
  channel : Int,
) -> Int {
  let index = (y * width + x) * 4 + channel
  pixels.unsafe_get(index).to_int()
}

///|
fn mip_downsample_rgba8(previous : (Int, Int, Bytes)) -> (Int, Int, Bytes) {
  let width = previous.0
  let height = previous.1
  let pixels = previous.2
  // Align with GPU mip sizing: floor(size / 2), clamped to >= 1.
  let next_width = if width > 1 { width / 2 } else { 1 }
  let next_height = if height > 1 { height / 2 } else { 1 }
  let out : Array[Byte] = []
  for y in 0..<next_height {
    for x in 0..<next_width {
      let src_x0 = mip_min_int(x * 2, width - 1)
      let src_x1 = mip_min_int(src_x0 + 1, width - 1)
      let src_y0 = mip_min_int(y * 2, height - 1)
      let src_y1 = mip_min_int(src_y0 + 1, height - 1)
      for channel in 0..<4 {
        let sum = mip_rgba_at(pixels, width, src_x0, src_y0, channel) +
          mip_rgba_at(pixels, width, src_x1, src_y0, channel) +
          mip_rgba_at(pixels, width, src_x0, src_y1, channel) +
          mip_rgba_at(pixels, width, src_x1, src_y1, channel)
        out.push((sum / 4).to_byte())
      }
    }
  }
  (next_width, next_height, Bytes::from_array(out))
}

///|
pub fn asset_generate_mip_chain_rgba8(
  width : Int,
  height : Int,
  base_pixels_rgba8 : Bytes,
) -> Array[(Int, Int, Bytes)] {
  let levels : Array[(Int, Int, Bytes)] = []
  if width <= 0 || height <= 0 {
    return levels
  }
  let expected_length = width * height * 4
  if base_pixels_rgba8.length() != expected_length {
    return levels
  }
  levels.push((width, height, base_pixels_rgba8))
  while levels.length() > 0 {
    let last = levels[levels.length() - 1]
    if last.0 == 1 && last.1 == 1 {
      break
    }
    levels.push(mip_downsample_rgba8(last))
  }
  levels
}

///|
pub fn asset_create_dynamic_texture_mip_chain_rgba8(
  width : Int,
  height : Int,
  base_pixels_rgba8 : Bytes,
  nearest : Bool,
) -> Array[Handle[Image]] {
  let handles : Array[Handle[Image]] = []
  let levels = asset_generate_mip_chain_rgba8(width, height, base_pixels_rgba8)
  for level in levels {
    let level_size = @math.UVec2::new(level.0, level.1)
    let handle = asset_create_dynamic_texture(level_size, nearest)
    asset_update_texture_region_rgba8(
      handle,
      @math.URect::new(@math.UVec2::zero(), level_size),
      level.2,
    )
    handles.push(handle)
  }
  handles
}
