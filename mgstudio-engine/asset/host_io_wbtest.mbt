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
fn push_u32_le(out : Array[Byte], value : Int) -> Unit {
  out.push((value & 0xFF).to_byte())
  out.push(((value >> 8) & 0xFF).to_byte())
  out.push(((value >> 16) & 0xFF).to_byte())
  out.push(((value >> 24) & 0xFF).to_byte())
}

///|
fn push_u64_le(out : Array[Byte], value : Int) -> Unit {
  out.push((value & 0xFF).to_byte())
  out.push(((value >> 8) & 0xFF).to_byte())
  out.push(((value >> 16) & 0xFF).to_byte())
  out.push(((value >> 24) & 0xFF).to_byte())
  out.push(((value >> 32) & 0xFF).to_byte())
  out.push(((value >> 40) & 0xFF).to_byte())
  out.push(((value >> 48) & 0xFF).to_byte())
  out.push(((value >> 56) & 0xFF).to_byte())
}

///|
fn push_bytes_test(out : Array[Byte], bytes : Bytes) -> Unit {
  for i in 0..<bytes.length() {
    out.push(bytes[i])
  }
}

///|
fn build_ktx2_level0_bytes(
  level0_payload : Bytes,
  supercompression_scheme : Int,
  level0_uncompressed_length : Int,
) -> Bytes {
  let out : Array[Byte] = []
  // KTX2 identifier.
  out.push((0xAB).to_byte())
  out.push((0x4B).to_byte())
  out.push((0x54).to_byte())
  out.push((0x58).to_byte())
  out.push((0x20).to_byte())
  out.push((0x32).to_byte())
  out.push((0x30).to_byte())
  out.push((0xBB).to_byte())
  out.push((0x0D).to_byte())
  out.push((0x0A).to_byte())
  out.push((0x1A).to_byte())
  out.push((0x0A).to_byte())

  push_u32_le(out, KTX2_VK_FORMAT_R16G16B16A16_SFLOAT)
  push_u32_le(out, 2) // typeSize
  push_u32_le(out, 1) // pixelWidth
  push_u32_le(out, 1) // pixelHeight
  push_u32_le(out, 2) // pixelDepth
  push_u32_le(out, 0) // layerCount
  push_u32_le(out, 1) // faceCount
  push_u32_le(out, 1) // levelCount
  push_u32_le(out, supercompression_scheme)
  push_u32_le(out, 0) // dfdByteOffset
  push_u32_le(out, 0) // dfdByteLength
  push_u32_le(out, 0) // kvdByteOffset
  push_u32_le(out, 0) // kvdByteLength
  push_u64_le(out, 0) // sgdByteOffset
  push_u64_le(out, 0) // sgdByteLength

  let level0_offset = KTX2_HEADER_SIZE + KTX2_LEVEL_INDEX_ENTRY_SIZE
  push_u64_le(out, level0_offset)
  push_u64_le(out, level0_payload.length())
  push_u64_le(out, level0_uncompressed_length)
  push_bytes_test(out, level0_payload)
  Bytes::from_array(out)
}

///|
test "asset host io: save_rgba8_png writes a valid png file" {
  let pixels = Bytes::from_array([
    (255).to_byte(),
    (0).to_byte(),
    (0).to_byte(),
    (255).to_byte(),
    (0).to_byte(),
    (255).to_byte(),
    (0).to_byte(),
    (255).to_byte(),
  ])
  let path = "wbtests/asset_host_save_rgba8_png.png"
  let out_path = resolve_output_path(path)
  save_rgba8_png(width=2, height=1, pixels~, path~)
  let encoded = @fs.read_file_to_bytes(out_path)
  inspect(png_dimensions(encoded), content="Some((2, 1))")
  inspect(encoded.length() > 16, content="true")
  inspect(encoded[0].to_uint(), content="137")
  inspect(encoded[1].to_uint(), content="80")
  inspect(encoded[2].to_uint(), content="78")
  inspect(encoded[3].to_uint(), content="71")
}

///|
test "asset host io: decode uncompressed ktx2 3d level0 payload" {
  let raw_pixels = Bytes::from_array([
    (0).to_byte(),
    (1).to_byte(),
    (2).to_byte(),
    (3).to_byte(),
    (4).to_byte(),
    (5).to_byte(),
    (6).to_byte(),
    (7).to_byte(),
    (8).to_byte(),
    (9).to_byte(),
    (10).to_byte(),
    (11).to_byte(),
    (12).to_byte(),
    (13).to_byte(),
    (14).to_byte(),
    (15).to_byte(),
  ])
  let ktx2 = build_ktx2_level0_bytes(
    raw_pixels,
    KTX2_SUPERCOMPRESSION_NONE,
    raw_pixels.length(),
  )
  let decoded = ktx2_decode_uncompressed_3d_payload(ktx2)
  inspect(decoded is Some(_), content="true")
  if decoded is Some(payload) {
    inspect(payload.width, content="1")
    inspect(payload.height, content="1")
    inspect(payload.depth, content="2")
    inspect(payload.format_raw, content="34")
    inspect(payload.pixels.length(), content="16")
    inspect(payload.pixels[0].to_int(), content="0")
    inspect(payload.pixels[15].to_int(), content="15")
  }
}

///|
test "asset host io: decode zstd supercompressed ktx2 3d level0 payload" {
  let raw_pixels = Bytes::from_array([
    (16).to_byte(),
    (17).to_byte(),
    (18).to_byte(),
    (19).to_byte(),
    (20).to_byte(),
    (21).to_byte(),
    (22).to_byte(),
    (23).to_byte(),
    (24).to_byte(),
    (25).to_byte(),
    (26).to_byte(),
    (27).to_byte(),
    (28).to_byte(),
    (29).to_byte(),
    (30).to_byte(),
    (31).to_byte(),
  ])
  let compressed = @zstd.compress(raw_pixels) catch {
    _ => Bytes::from_array([])
  }
  inspect(compressed.length() > 0, content="true")
  let ktx2 = build_ktx2_level0_bytes(
    compressed,
    KTX2_SUPERCOMPRESSION_ZSTD,
    raw_pixels.length(),
  )
  let decoded = ktx2_decode_uncompressed_3d_payload(ktx2)
  inspect(decoded is Some(_), content="true")
  if decoded is Some(payload) {
    inspect(payload.width, content="1")
    inspect(payload.height, content="1")
    inspect(payload.depth, content="2")
    inspect(payload.format_raw, content="34")
    inspect(payload.pixels.length(), content="16")
    inspect(payload.pixels[0].to_int(), content="16")
    inspect(payload.pixels[15].to_int(), content="31")
  }
}
