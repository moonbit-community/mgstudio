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
pub fn AssetServer::load_font(
  self : AssetServer,
  path : String,
) -> Handle[Font] {
  let id = host_asset_load_font(path)
  self.paths.push(path)
  Handle::new(id)
}
