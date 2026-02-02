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
pub struct Font {}

///|
pub fn host_asset_load_font(path : String) -> Int {
  @core.with_host_string_id(path, fn(path_id) {
    host_asset_load_font_id(path_id)
  })
}

///|
fn host_asset_load_font_id(path_id : Int) -> Int = "mgstudio_host" "asset_load_font"

///|
pub fn host_asset_font_bytes_len(font_id : Int) -> Int = "mgstudio_host" "asset_font_bytes_len"

///|
pub fn host_asset_font_bytes_get(font_id : Int, index : Int) -> Int = "mgstudio_host" "asset_font_bytes_get"

///|
pub fn host_asset_font_bytes_get_u32(font_id : Int, index : Int) -> Int = "mgstudio_host" "asset_font_bytes_get_u32"

///|
pub fn AssetServer::load_font(
  self : AssetServer,
  path : String,
) -> Handle[Font] {
  let id = host_asset_load_font(path)
  self.paths.push(path)
  Handle::new(id)
}

///|
pub fn asset_font_read_bytes(font : Handle[Font]) -> Bytes? {
  let len = host_asset_font_bytes_len(font.id())
  if len <= 0 {
    return None
  }
  let bytes : Array[Byte] = []
  let mut i = 0
  while i < len {
    let u = host_asset_font_bytes_get_u32(font.id(), i).reinterpret_as_uint()
    bytes.push((u & 0xFFU).reinterpret_as_int().to_byte())
    if i + 1 < len {
      bytes.push(((u >> 8) & 0xFFU).reinterpret_as_int().to_byte())
    }
    if i + 2 < len {
      bytes.push(((u >> 16) & 0xFFU).reinterpret_as_int().to_byte())
    }
    if i + 3 < len {
      bytes.push(((u >> 24) & 0xFFU).reinterpret_as_int().to_byte())
    }
    i = i + 4
  }
  Some(Bytes::from_array(bytes))
}
