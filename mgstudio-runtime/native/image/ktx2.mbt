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
const KTX2_SUPERCOMPRESSION_NONE : Int = 0

///|
const KTX2_SUPERCOMPRESSION_ZSTD : Int = 2

///|
priv struct Ktx2LevelIndex {
  byte_offset : Int
  byte_length : Int
  uncompressed_byte_length : Int
}

///|
priv struct Ktx2BlockLayout {
  block_width : Int
  block_height : Int
  block_bytes : Int
}

///|
pub struct Ktx2UploadTexture {
  width : Int
  height_per_slice : Int
  slice_count : Int
  format_raw : UInt
  levels : Array[Bytes]
}

///|
pub fn is_ktx2(bytes : Bytes) -> Bool {
  let magic = [
    0xAB, 0x4B, 0x54, 0x58, 0x20, 0x32, 0x30, 0xBB, 0x0D, 0x0A, 0x1A, 0x0A,
  ]
  if bytes.length() < magic.length() {
    return false
  }
  for i in 0..<magic.length() {
    let b = match bytes.get(i) {
      Some(v) => v.to_int() & 0xFF
      None => -1
    }
    if b != magic[i] {
      return false
    }
  }
  true
}

///|
fn read_u32_le(bytes : Bytes, offset : Int) -> UInt? {
  if offset < 0 || offset + 4 > bytes.length() {
    return None
  }
  let b0 = match bytes.get(offset) {
    Some(v) => v.to_int() & 0xFF
    None => return None
  }
  let b1 = match bytes.get(offset + 1) {
    Some(v) => v.to_int() & 0xFF
    None => return None
  }
  let b2 = match bytes.get(offset + 2) {
    Some(v) => v.to_int() & 0xFF
    None => return None
  }
  let b3 = match bytes.get(offset + 3) {
    Some(v) => v.to_int() & 0xFF
    None => return None
  }
  Some(
    b0.reinterpret_as_uint() |
    (b1.reinterpret_as_uint() << 8) |
    (b2.reinterpret_as_uint() << 16) |
    (b3.reinterpret_as_uint() << 24),
  )
}

///|
fn read_u64_le_as_int(bytes : Bytes, offset : Int) -> Int? {
  guard read_u32_le(bytes, offset) is Some(lo) else { return None }
  guard read_u32_le(bytes, offset + 4) is Some(hi) else { return None }
  if hi != 0U {
    return None
  }
  Some(lo.reinterpret_as_int())
}

///|
fn bytes_slice_copy(bytes : Bytes, offset : Int, length : Int) -> Bytes? {
  if offset < 0 || length < 0 || offset + length > bytes.length() {
    return None
  }
  Some(
    Bytes::makei(length, i => {
      match bytes.get(offset + i) {
        Some(b) => b
        None => (0).to_byte()
      }
    }),
  )
}

///|
fn bytes_take(bytes : Bytes, count : Int) -> Bytes? {
  if count < 0 || count > bytes.length() {
    return None
  }
  if count == bytes.length() {
    return Some(bytes)
  }
  Some(
    Bytes::makei(count, i => {
      match bytes.get(i) {
        Some(b) => b
        None => (0).to_byte()
      }
    }),
  )
}

///|
fn ceil_div(v : Int, d : Int) -> Int {
  if d <= 0 {
    return 0
  }
  if v <= 0 {
    return 1
  }
  (v + d - 1) / d
}

///|
fn bytes_for_level(block : Ktx2BlockLayout, width : Int, height : Int) -> Int? {
  let w = if width <= 0 { 1 } else { width }
  let h = if height <= 0 { 1 } else { height }
  let blocks_w = ceil_div(w, block.block_width)
  let blocks_h = ceil_div(h, block.block_height)
  if blocks_w <= 0 || blocks_h <= 0 {
    return None
  }
  let bytes_per_row = blocks_w * block.block_bytes
  if bytes_per_row <= 0 {
    return None
  }
  let total = bytes_per_row * blocks_h
  if total <= 0 {
    return None
  }
  Some(total)
}

///|
fn ktx2_format_info(vk_format : UInt) -> (UInt, Ktx2BlockLayout)? {
  match vk_format.reinterpret_as_int() {
    // VK_FORMAT_R16G16B16A16_SFLOAT
    97 =>
      Some(
        (
          @wgpu.TEXTURE_FORMAT_RGBA16_FLOAT,
          Ktx2BlockLayout::{ block_width: 1, block_height: 1, block_bytes: 8 },
        ),
      )
    // VK_FORMAT_E5B9G9R9_UFLOAT_PACK32
    123 =>
      Some(
        (
          @wgpu.TEXTURE_FORMAT_RGB9_E5_UFLOAT,
          Ktx2BlockLayout::{ block_width: 1, block_height: 1, block_bytes: 4 },
        ),
      )
    // VK_FORMAT_BC7_UNORM_BLOCK
    146 =>
      Some(
        (
          @wgpu.TEXTURE_FORMAT_BC7_RGBA_UNORM,
          Ktx2BlockLayout::{ block_width: 4, block_height: 4, block_bytes: 16 },
        ),
      )
    // VK_FORMAT_ETC2_R8G8B8A8_UNORM_BLOCK
    148 =>
      Some(
        (
          @wgpu.TEXTURE_FORMAT_ETC2_RGBA8_UNORM,
          Ktx2BlockLayout::{ block_width: 4, block_height: 4, block_bytes: 16 },
        ),
      )
    // VK_FORMAT_ASTC_4x4_UNORM_BLOCK
    158 =>
      Some(
        (
          @wgpu.TEXTURE_FORMAT_ASTC4X4_UNORM,
          Ktx2BlockLayout::{ block_width: 4, block_height: 4, block_bytes: 16 },
        ),
      )
    _ => None
  }
}

///|
fn decode_ktx2_level(
  all_bytes : Bytes,
  level : Ktx2LevelIndex,
  supercompression_scheme : Int,
) -> Bytes? {
  guard bytes_slice_copy(all_bytes, level.byte_offset, level.byte_length)
    is Some(raw) else {
    return None
  }
  if supercompression_scheme == KTX2_SUPERCOMPRESSION_NONE {
    return Some(raw)
  }
  if supercompression_scheme == KTX2_SUPERCOMPRESSION_ZSTD {
    let expected = if level.uncompressed_byte_length > 0 {
      level.uncompressed_byte_length
    } else {
      0
    }
    let decoded = c_zstd_decompress(raw, expected)
    if expected > 0 && decoded.length() != expected {
      return None
    }
    if decoded.length() == 0 {
      return None
    }
    return Some(decoded)
  }
  None
}

///|
pub fn parse_ktx2_texture_for_stacked_upload(
  bytes : Bytes,
) -> Ktx2UploadTexture? {
  if !is_ktx2(bytes) || bytes.length() < 80 {
    return None
  }
  guard read_u32_le(bytes, 12) is Some(vk_format) else { return None }
  guard read_u32_le(bytes, 20) is Some(pixel_width_u32) else { return None }
  guard read_u32_le(bytes, 24) is Some(pixel_height_u32) else { return None }
  guard read_u32_le(bytes, 28) is Some(pixel_depth_u32) else { return None }
  guard read_u32_le(bytes, 32) is Some(layer_count_u32) else { return None }
  guard read_u32_le(bytes, 36) is Some(face_count_u32) else { return None }
  guard read_u32_le(bytes, 40) is Some(level_count_raw_u32) else { return None }
  guard read_u32_le(bytes, 44) is Some(supercompression_u32) else {
    return None
  }
  guard ktx2_format_info(vk_format) is Some((format_raw, block_layout)) else {
    return None
  }

  let mut level_count = level_count_raw_u32.reinterpret_as_int()
  if level_count <= 0 {
    level_count = 1
  }
  let width = {
    let v = pixel_width_u32.reinterpret_as_int()
    if v <= 0 {
      1
    } else {
      v
    }
  }
  let height_per_slice = {
    let v = pixel_height_u32.reinterpret_as_int()
    if v <= 0 {
      1
    } else {
      v
    }
  }
  let depth = {
    let v = pixel_depth_u32.reinterpret_as_int()
    if v <= 0 {
      1
    } else {
      v
    }
  }
  let layers = {
    let v = layer_count_u32.reinterpret_as_int()
    if v <= 0 {
      1
    } else {
      v
    }
  }
  let faces = {
    let v = face_count_u32.reinterpret_as_int()
    if v <= 0 {
      1
    } else {
      v
    }
  }
  let slice_count = layers * faces * depth
  if slice_count <= 0 {
    return None
  }

  let supercompression = supercompression_u32.reinterpret_as_int()
  let level_indices : Array[Ktx2LevelIndex] = []
  let mut offset = 80
  for _ in 0..<level_count {
    guard read_u64_le_as_int(bytes, offset) is Some(byte_offset) else {
      return None
    }
    guard read_u64_le_as_int(bytes, offset + 8) is Some(byte_length) else {
      return None
    }
    guard read_u64_le_as_int(bytes, offset + 16) is Some(uncompressed_length) else {
      return None
    }
    level_indices.push(Ktx2LevelIndex::{
      byte_offset,
      byte_length,
      uncompressed_byte_length: uncompressed_length,
    })
    offset = offset + 24
  }

  let stacked_levels : Array[Bytes] = []
  let level_total = level_indices.length()
  for mip_index in 0..<level_total {
    let level = level_indices[mip_index]
    let mip_width = if width >> mip_index <= 0 { 1 } else { width >> mip_index }
    let mip_height = if height_per_slice >> mip_index <= 0 {
      1
    } else {
      height_per_slice >> mip_index
    }
    let mip_depth = if depth >> mip_index <= 0 { 1 } else { depth >> mip_index }
    let mip_slice_count = layers * faces * mip_depth
    if mip_slice_count <= 0 {
      return None
    }
    if mip_slice_count != slice_count {
      if mip_index == 0 {
        return None
      }
      // Stacked-2D upload cannot represent depth-shrinking mips of true 3D
      // textures; keep only mip 0 for LUT-style usage.
      break
    }
    guard bytes_for_level(block_layout, mip_width, mip_height)
      is Some(per_slice_bytes) else {
      return None
    }
    let expected_level_bytes = per_slice_bytes * mip_slice_count
    if expected_level_bytes <= 0 {
      return None
    }
    guard decode_ktx2_level(bytes, level, supercompression) is Some(decoded) else {
      return None
    }
    if decoded.length() < expected_level_bytes {
      return None
    }
    guard bytes_take(decoded, expected_level_bytes) is Some(trimmed) else {
      return None
    }
    stacked_levels.push(trimmed)
  }

  Some(Ktx2UploadTexture::{
    width,
    height_per_slice,
    slice_count,
    format_raw,
    levels: stacked_levels,
  })
}

///|
#borrow(bytes)
extern "C" fn c_zstd_decompress(bytes : Bytes, expected_len : Int) -> Bytes = "mgimg_zstd_decompress"
