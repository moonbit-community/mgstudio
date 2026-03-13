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
  inspect(png_dimensions(encoded), content="Some((2, 1))")
  inspect(encoded.length() > 16, content="true")
  inspect(encoded[0].to_uint(), content="137")
  inspect(encoded[1].to_uint(), content="80")
  inspect(encoded[2].to_uint(), content="78")
  inspect(encoded[3].to_uint(), content="71")
}

///|
test "asset host io: palette png preserves transparent background" {
  let path = resolve_asset_path("textures/simplespace/ship_C.png")
  let bytes = @fs.read_file_to_bytes(path)
  let decoded = decode_texture_image(bytes).unwrap()
  let center = (32 * decoded.width + 32) * 4
  inspect((decoded.width, decoded.height), content="(64, 64)")
  inspect(decoded.pixels[0].to_uint(), content="0")
  inspect(decoded.pixels[1].to_uint(), content="0")
  inspect(decoded.pixels[2].to_uint(), content="0")
  inspect(decoded.pixels[3].to_uint(), content="0")
  inspect(decoded.pixels[center + 3].to_uint(), content="255")
}
