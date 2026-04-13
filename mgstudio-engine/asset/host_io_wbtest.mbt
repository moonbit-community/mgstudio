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
  debug_inspect(png_dimensions(encoded), content="Some((2, 1))")
  debug_inspect(encoded.length() > 16, content="true")
  debug_inspect(encoded[0].to_uint(), content="137")
  debug_inspect(encoded[1].to_uint(), content="80")
  debug_inspect(encoded[2].to_uint(), content="78")
  debug_inspect(encoded[3].to_uint(), content="71")
}

///|
test "asset host io: palette png preserves transparent background" {
  let path = resolve_asset_path("textures/simplespace/ship_C.png")
  let bytes = @fs.read_file_to_bytes(path)
  let decoded = decode_texture_image_with_container(bytes, None).unwrap()
  let center = (32 * decoded.width + 32) * 4
  debug_inspect((decoded.width, decoded.height), content="(64, 64)")
  debug_inspect(decoded.pixels[0].to_uint(), content="0")
  debug_inspect(decoded.pixels[1].to_uint(), content="0")
  debug_inspect(decoded.pixels[2].to_uint(), content="0")
  debug_inspect(decoded.pixels[3].to_uint(), content="0")
  debug_inspect(decoded.pixels[center + 3].to_uint(), content="255")
}

///|
fn test_bmp_24_2x2_bytes() -> Bytes {
  let out : Array[Byte] = []
  let push_u32_le_test = fn(out : Array[Byte], value : UInt) {
    out.push((value & 0xFFU).to_byte())
    out.push(((value >> 8) & 0xFFU).to_byte())
    out.push(((value >> 16) & 0xFFU).to_byte())
    out.push(((value >> 24) & 0xFFU).to_byte())
  }
  // BITMAPFILEHEADER
  out.push((0x42).to_byte())
  out.push((0x4D).to_byte())
  push_u32_le_test(out, 70U)
  push_u16_le(out, 0U)
  push_u16_le(out, 0U)
  push_u32_le_test(out, 54U)
  // BITMAPINFOHEADER
  push_u32_le_test(out, 40U)
  push_u32_le_test(out, 2U)
  push_u32_le_test(out, 2U)
  push_u16_le(out, 1U)
  push_u16_le(out, 24U)
  push_u32_le_test(out, 0U)
  push_u32_le_test(out, 16U)
  push_u32_le_test(out, 2835U)
  push_u32_le_test(out, 2835U)
  push_u32_le_test(out, 0U)
  push_u32_le_test(out, 0U)
  // Pixel rows (bottom-up), each row padded to 4-byte alignment.
  // Bottom row: blue, white
  out.push((255).to_byte())
  out.push((0).to_byte())
  out.push((0).to_byte())
  out.push((255).to_byte())
  out.push((255).to_byte())
  out.push((255).to_byte())
  out.push((0).to_byte())
  out.push((0).to_byte())
  // Top row: red, green
  out.push((0).to_byte())
  out.push((0).to_byte())
  out.push((255).to_byte())
  out.push((0).to_byte())
  out.push((255).to_byte())
  out.push((0).to_byte())
  out.push((0).to_byte())
  out.push((0).to_byte())
  Bytes::from_array(out)
}

///|
test "asset host io: bmp decode supports 24-bit bottom-up bitmap" {
  let bytes = test_bmp_24_2x2_bytes()
  let decoded = decode_texture_image_with_container(bytes, None).unwrap()
  debug_inspect((decoded.width, decoded.height), content="(2, 2)")
  // Top-left pixel should be red after bottom-up conversion.
  debug_inspect(decoded.pixels[0].to_uint(), content="255")
  debug_inspect(decoded.pixels[1].to_uint(), content="0")
  debug_inspect(decoded.pixels[2].to_uint(), content="0")
  debug_inspect(decoded.pixels[3].to_uint(), content="255")
  // Top-right pixel should be green.
  debug_inspect(decoded.pixels[4].to_uint(), content="0")
  debug_inspect(decoded.pixels[5].to_uint(), content="255")
  debug_inspect(decoded.pixels[6].to_uint(), content="0")
  debug_inspect(decoded.pixels[7].to_uint(), content="255")
  // Bottom-left pixel should be blue.
  debug_inspect(decoded.pixels[8].to_uint(), content="0")
  debug_inspect(decoded.pixels[9].to_uint(), content="0")
  debug_inspect(decoded.pixels[10].to_uint(), content="255")
  debug_inspect(decoded.pixels[11].to_uint(), content="255")
}

///|
test "asset host io: texture dimensions read from bmp header" {
  let bytes = test_bmp_24_2x2_bytes()
  debug_inspect(texture_dimensions_from_bytes(bytes), content="Some((2, 2))")
}

///|
fn test_tga_24_2x1_bytes() -> Bytes {
  let out : Array[Byte] = []
  // Header
  out.push((0).to_byte()) // id length
  out.push((0).to_byte()) // color map type
  out.push((2).to_byte()) // image type: uncompressed true-color
  out.push((0).to_byte())
  out.push((0).to_byte())
  out.push((0).to_byte())
  out.push((0).to_byte())
  out.push((0).to_byte())
  out.push((0).to_byte()) // x origin
  out.push((0).to_byte())
  out.push((0).to_byte()) // y origin
  out.push((0).to_byte())
  out.push((2).to_byte()) // width = 2
  out.push((0).to_byte())
  out.push((1).to_byte()) // height = 1
  out.push((0).to_byte())
  out.push((24).to_byte()) // pixel depth
  out.push((0x20).to_byte()) // top-left origin
  // Pixel data (BGR): red, green
  out.push((0).to_byte())
  out.push((0).to_byte())
  out.push((255).to_byte())
  out.push((0).to_byte())
  out.push((255).to_byte())
  out.push((0).to_byte())
  Bytes::from_array(out)
}

///|
test "asset host io: tga decode supports uncompressed true-color with container hint" {
  let bytes = test_tga_24_2x1_bytes()
  let decoded = decode_texture_image_with_container(
    bytes,
    Some(@image.ImageContainerFormat::Tga),
  ).unwrap()
  debug_inspect((decoded.width, decoded.height), content="(2, 1)")
  // Left pixel red.
  debug_inspect(decoded.pixels[0].to_uint(), content="255")
  debug_inspect(decoded.pixels[1].to_uint(), content="0")
  debug_inspect(decoded.pixels[2].to_uint(), content="0")
  debug_inspect(decoded.pixels[3].to_uint(), content="255")
  // Right pixel green.
  debug_inspect(decoded.pixels[4].to_uint(), content="0")
  debug_inspect(decoded.pixels[5].to_uint(), content="255")
  debug_inspect(decoded.pixels[6].to_uint(), content="0")
  debug_inspect(decoded.pixels[7].to_uint(), content="255")
}

///|
fn test_tga_rle_24_2x1_bytes() -> Bytes {
  let out : Array[Byte] = []
  // Header
  out.push((0).to_byte()) // id length
  out.push((0).to_byte()) // color map type
  out.push((10).to_byte()) // image type: RLE true-color
  out.push((0).to_byte())
  out.push((0).to_byte())
  out.push((0).to_byte())
  out.push((0).to_byte())
  out.push((0).to_byte())
  out.push((0).to_byte()) // x origin
  out.push((0).to_byte())
  out.push((0).to_byte()) // y origin
  out.push((0).to_byte())
  out.push((2).to_byte()) // width = 2
  out.push((0).to_byte())
  out.push((1).to_byte()) // height = 1
  out.push((0).to_byte())
  out.push((24).to_byte()) // pixel depth
  out.push((0x20).to_byte()) // top-left origin
  // One raw packet with two pixels (red, green)
  out.push((1).to_byte()) // raw packet, length 2
  out.push((0).to_byte())
  out.push((0).to_byte())
  out.push((255).to_byte())
  out.push((0).to_byte())
  out.push((255).to_byte())
  out.push((0).to_byte())
  Bytes::from_array(out)
}

///|
test "asset host io: tga decode supports RLE true-color payload" {
  let bytes = test_tga_rle_24_2x1_bytes()
  let decoded = decode_texture_image_with_container(
    bytes,
    Some(@image.ImageContainerFormat::Tga),
  ).unwrap()
  debug_inspect((decoded.width, decoded.height), content="(2, 1)")
  debug_inspect(decoded.pixels[0].to_uint(), content="255")
  debug_inspect(decoded.pixels[1].to_uint(), content="0")
  debug_inspect(decoded.pixels[2].to_uint(), content="0")
  debug_inspect(decoded.pixels[3].to_uint(), content="255")
  debug_inspect(decoded.pixels[4].to_uint(), content="0")
  debug_inspect(decoded.pixels[5].to_uint(), content="255")
  debug_inspect(decoded.pixels[6].to_uint(), content="0")
  debug_inspect(decoded.pixels[7].to_uint(), content="255")
}

///|
fn test_pnm_p6_2x1_bytes() -> Bytes {
  let out : Array[Byte] = []
  for code in @utf8.encode("P6\n2 1\n255\n"[:]) {
    out.push(code)
  }
  // RGB pixels: red, green
  out.push((255).to_byte())
  out.push((0).to_byte())
  out.push((0).to_byte())
  out.push((0).to_byte())
  out.push((255).to_byte())
  out.push((0).to_byte())
  Bytes::from_array(out)
}

///|
test "asset host io: pnm decode supports binary P6 payload" {
  let bytes = test_pnm_p6_2x1_bytes()
  let decoded = decode_texture_image_with_container(
    bytes,
    Some(@image.ImageContainerFormat::Pnm),
  ).unwrap()
  debug_inspect((decoded.width, decoded.height), content="(2, 1)")
  debug_inspect(decoded.pixels[0].to_uint(), content="255")
  debug_inspect(decoded.pixels[1].to_uint(), content="0")
  debug_inspect(decoded.pixels[2].to_uint(), content="0")
  debug_inspect(decoded.pixels[3].to_uint(), content="255")
  debug_inspect(decoded.pixels[4].to_uint(), content="0")
  debug_inspect(decoded.pixels[5].to_uint(), content="255")
  debug_inspect(decoded.pixels[6].to_uint(), content="0")
  debug_inspect(decoded.pixels[7].to_uint(), content="255")
}

///|
fn test_pnm_p3_2x1_bytes() -> Bytes {
  @utf8.encode("P3\n2 1\n255\n255 0 0 0 255 0\n"[:])
}

///|
test "asset host io: pnm decode supports ascii P3 payload" {
  let bytes = test_pnm_p3_2x1_bytes()
  let decoded = decode_texture_image_with_container(
    bytes,
    Some(@image.ImageContainerFormat::Pnm),
  ).unwrap()
  debug_inspect((decoded.width, decoded.height), content="(2, 1)")
  debug_inspect(decoded.pixels[0].to_uint(), content="255")
  debug_inspect(decoded.pixels[1].to_uint(), content="0")
  debug_inspect(decoded.pixels[2].to_uint(), content="0")
  debug_inspect(decoded.pixels[4].to_uint(), content="0")
  debug_inspect(decoded.pixels[5].to_uint(), content="255")
  debug_inspect(decoded.pixels[6].to_uint(), content="0")
}

///|
fn test_farbfeld_1x2_bytes() -> Bytes {
  let out : Array[Byte] = []
  for code in @utf8.encode("farbfeld"[:]) {
    out.push(code)
  }
  push_u32_be(out, 1U)
  push_u32_be(out, 2U)
  let push_u16_be_test = fn(out : Array[Byte], value : UInt) {
    out.push(((value >> 8) & 0xFFU).to_byte())
    out.push((value & 0xFFU).to_byte())
  }
  // Pixel 0: opaque red.
  push_u16_be_test(out, 0xFFFFU)
  push_u16_be_test(out, 0U)
  push_u16_be_test(out, 0U)
  push_u16_be_test(out, 0xFFFFU)
  // Pixel 1: blue with 50% alpha.
  push_u16_be_test(out, 0U)
  push_u16_be_test(out, 0U)
  push_u16_be_test(out, 0xFFFFU)
  push_u16_be_test(out, 0x8000U)
  Bytes::from_array(out)
}

///|
test "asset host io: farbfeld decode and dimensions work" {
  let bytes = test_farbfeld_1x2_bytes()
  debug_inspect(texture_dimensions_from_bytes(bytes), content="Some((1, 2))")
  let decoded = decode_texture_image_with_container(
    bytes,
    Some(@image.ImageContainerFormat::Farbfeld),
  ).unwrap()
  debug_inspect((decoded.width, decoded.height), content="(1, 2)")
  debug_inspect(decoded.pixels[0].to_uint(), content="255")
  debug_inspect(decoded.pixels[1].to_uint(), content="0")
  debug_inspect(decoded.pixels[2].to_uint(), content="0")
  debug_inspect(decoded.pixels[3].to_uint(), content="255")
  debug_inspect(decoded.pixels[4].to_uint(), content="0")
  debug_inspect(decoded.pixels[5].to_uint(), content="0")
  debug_inspect(decoded.pixels[6].to_uint(), content="255")
  // 0x8000 >> 8 = 128
  debug_inspect(decoded.pixels[7].to_uint(), content="128")
}

///|
fn test_qoi_1x1_red_bytes() -> Bytes {
  let out : Array[Byte] = []
  for code in @utf8.encode("qoif"[:]) {
    out.push(code)
  }
  push_u32_be(out, 1U) // width
  push_u32_be(out, 1U) // height
  out.push((4).to_byte()) // channels
  out.push((0).to_byte()) // colorspace
  // QOI_OP_RGBA + pixel
  out.push((0xFF).to_byte())
  out.push((255).to_byte())
  out.push((0).to_byte())
  out.push((0).to_byte())
  out.push((255).to_byte())
  // End marker
  out.push((0).to_byte())
  out.push((0).to_byte())
  out.push((0).to_byte())
  out.push((0).to_byte())
  out.push((0).to_byte())
  out.push((0).to_byte())
  out.push((0).to_byte())
  out.push((1).to_byte())
  Bytes::from_array(out)
}

///|
test "asset host io: qoi decode and dimensions work" {
  let bytes = test_qoi_1x1_red_bytes()
  debug_inspect(texture_dimensions_from_bytes(bytes), content="Some((1, 1))")
  let decoded = decode_texture_image_with_container(
    bytes,
    Some(@image.ImageContainerFormat::Qoi),
  ).unwrap()
  debug_inspect((decoded.width, decoded.height), content="(1, 1)")
  debug_inspect(decoded.pixels[0].to_uint(), content="255")
  debug_inspect(decoded.pixels[1].to_uint(), content="0")
  debug_inspect(decoded.pixels[2].to_uint(), content="0")
  debug_inspect(decoded.pixels[3].to_uint(), content="255")
}

///|
fn test_ico_with_png_1x1_red_bytes() -> Bytes {
  let red = Bytes::from_array([
    (255).to_byte(),
    (0).to_byte(),
    (0).to_byte(),
    (255).to_byte(),
  ])
  let payload = png_encode_rgba8(1, 1, red).unwrap()
  let out : Array[Byte] = []
  let push_u32_le_test = fn(out : Array[Byte], value : UInt) {
    out.push((value & 0xFFU).to_byte())
    out.push(((value >> 8) & 0xFFU).to_byte())
    out.push(((value >> 16) & 0xFFU).to_byte())
    out.push(((value >> 24) & 0xFFU).to_byte())
  }
  // ICONDIR
  push_u16_le(out, 0U)
  push_u16_le(out, 1U)
  push_u16_le(out, 1U)
  // ICONDIRENTRY
  out.push((1).to_byte()) // width
  out.push((1).to_byte()) // height
  out.push((0).to_byte()) // color count
  out.push((0).to_byte()) // reserved
  push_u16_le(out, 1U) // planes
  push_u16_le(out, 32U) // bit count
  let payload_size = payload.length().reinterpret_as_uint()
  push_u32_le_test(out, payload_size)
  push_u32_le_test(out, 22U) // payload offset
  push_bytes(out, payload)
  Bytes::from_array(out)
}

///|
test "asset host io: ico dimensions and embedded png decode work" {
  let bytes = test_ico_with_png_1x1_red_bytes()
  debug_inspect(texture_dimensions_from_bytes(bytes), content="Some((1, 1))")
  let decoded = decode_texture_image_with_container(
    bytes,
    Some(@image.ImageContainerFormat::Ico),
  ).unwrap()
  debug_inspect((decoded.width, decoded.height), content="(1, 1)")
  debug_inspect(decoded.pixels[0].to_uint(), content="255")
  debug_inspect(decoded.pixels[1].to_uint(), content="0")
  debug_inspect(decoded.pixels[2].to_uint(), content="0")
  debug_inspect(decoded.pixels[3].to_uint(), content="255")
}

///|
fn test_ico_with_dib_1x1_red_bytes() -> Bytes {
  let out : Array[Byte] = []
  let push_u32_le_test = fn(out : Array[Byte], value : UInt) {
    out.push((value & 0xFFU).to_byte())
    out.push(((value >> 8) & 0xFFU).to_byte())
    out.push(((value >> 16) & 0xFFU).to_byte())
    out.push(((value >> 24) & 0xFFU).to_byte())
  }
  // ICONDIR
  push_u16_le(out, 0U)
  push_u16_le(out, 1U)
  push_u16_le(out, 1U)
  // ICONDIRENTRY
  out.push((1).to_byte()) // width
  out.push((1).to_byte()) // height
  out.push((0).to_byte()) // color count
  out.push((0).to_byte()) // reserved
  push_u16_le(out, 1U) // planes
  push_u16_le(out, 32U) // bit count
  push_u32_le_test(out, 48U) // bytes in resource
  push_u32_le_test(out, 22U) // offset
  // BITMAPINFOHEADER (40 bytes)
  push_u32_le_test(out, 40U) // header size
  push_u32_le_test(out, 1U) // width
  push_u32_le_test(out, 2U) // height * 2 (XOR+AND)
  push_u16_le(out, 1U) // planes
  push_u16_le(out, 32U) // bit count
  push_u32_le_test(out, 0U) // compression BI_RGB
  push_u32_le_test(out, 4U) // image size for XOR bitmap
  push_u32_le_test(out, 0U) // x ppm
  push_u32_le_test(out, 0U) // y ppm
  push_u32_le_test(out, 0U) // clr used
  push_u32_le_test(out, 0U) // clr important
  // XOR bitmap pixel (BGRA): red
  out.push((0).to_byte())
  out.push((0).to_byte())
  out.push((255).to_byte())
  out.push((255).to_byte())
  // AND mask row (4-byte aligned)
  out.push((0).to_byte())
  out.push((0).to_byte())
  out.push((0).to_byte())
  out.push((0).to_byte())
  Bytes::from_array(out)
}

///|
test "asset host io: ico dimensions and DIB BGRA32 decode work" {
  let bytes = test_ico_with_dib_1x1_red_bytes()
  debug_inspect(texture_dimensions_from_bytes(bytes), content="Some((1, 1))")
  let decoded = decode_texture_image_with_container(
    bytes,
    Some(@image.ImageContainerFormat::Ico),
  ).unwrap()
  debug_inspect((decoded.width, decoded.height), content="(1, 1)")
  debug_inspect(decoded.pixels[0].to_uint(), content="255")
  debug_inspect(decoded.pixels[1].to_uint(), content="0")
  debug_inspect(decoded.pixels[2].to_uint(), content="0")
  debug_inspect(decoded.pixels[3].to_uint(), content="255")
}

///|
fn test_gif_2x3_header_bytes() -> Bytes {
  Bytes::from_array([
    // GIF89a
    (0x47).to_byte(),
    (0x49).to_byte(),
    (0x46).to_byte(),
    (0x38).to_byte(),
    (0x39).to_byte(),
    (0x61).to_byte(),
    // width=2, height=3
    (0x02).to_byte(),
    (0x00).to_byte(),
    (0x03).to_byte(),
    (0x00).to_byte(),
  ])
}

///|
fn test_webp_vp8x_4x5_header_bytes() -> Bytes {
  let out : Array[Byte] = []
  // RIFF + fake size + WEBP
  for code in @utf8.encode("RIFF"[:]) {
    out.push(code)
  }
  out.push((0).to_byte())
  out.push((0).to_byte())
  out.push((0).to_byte())
  out.push((0).to_byte())
  for code in @utf8.encode("WEBPVP8X"[:]) {
    out.push(code)
  }
  // chunk size = 10
  out.push((10).to_byte())
  out.push((0).to_byte())
  out.push((0).to_byte())
  out.push((0).to_byte())
  // features + reserved
  out.push((0).to_byte())
  out.push((0).to_byte())
  out.push((0).to_byte())
  out.push((0).to_byte())
  // width-1 = 3 (24-bit little endian)
  out.push((3).to_byte())
  out.push((0).to_byte())
  out.push((0).to_byte())
  // height-1 = 4
  out.push((4).to_byte())
  out.push((0).to_byte())
  out.push((0).to_byte())
  Bytes::from_array(out)
}

///|
fn test_tiff_le_7x5_header_bytes() -> Bytes {
  let out : Array[Byte] = []
  let push_u32_le_test = fn(out : Array[Byte], value : UInt) {
    out.push((value & 0xFFU).to_byte())
    out.push(((value >> 8) & 0xFFU).to_byte())
    out.push(((value >> 16) & 0xFFU).to_byte())
    out.push(((value >> 24) & 0xFFU).to_byte())
  }
  // TIFF header: II* and first IFD at offset 8
  out.push((0x49).to_byte())
  out.push((0x49).to_byte())
  out.push((0x2A).to_byte())
  out.push((0x00).to_byte())
  push_u32_le_test(out, 8U)
  // IFD with 2 entries
  push_u16_le(out, 2U)
  // Tag 256 (ImageWidth), type LONG, count 1, value 7
  push_u16_le(out, 256U)
  push_u16_le(out, 4U)
  push_u32_le_test(out, 1U)
  push_u32_le_test(out, 7U)
  // Tag 257 (ImageLength), type LONG, count 1, value 5
  push_u16_le(out, 257U)
  push_u16_le(out, 4U)
  push_u32_le_test(out, 1U)
  push_u32_le_test(out, 5U)
  // Next IFD offset
  push_u32_le_test(out, 0U)
  Bytes::from_array(out)
}

///|
test "asset host io: texture dimensions parse gif/webp/tiff headers" {
  debug_inspect(
    texture_dimensions_from_bytes(test_gif_2x3_header_bytes()),
    content="Some((2, 3))",
  )
  debug_inspect(
    texture_dimensions_from_bytes(test_webp_vp8x_4x5_header_bytes()),
    content="Some((4, 5))",
  )
  debug_inspect(
    texture_dimensions_from_bytes(test_tiff_le_7x5_header_bytes()),
    content="Some((7, 5))",
  )
}
