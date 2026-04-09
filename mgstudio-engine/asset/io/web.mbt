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
// Bevy source: `bevy/crates/bevy_asset/src/io/web.rs`.

///|
pub const WEB_ASSET_SOURCE_NAME : String = "web"

///|
pub fn asset_io_web_source_name() -> String {
  WEB_ASSET_SOURCE_NAME
}

///|
pub fn asset_io_web_supported() -> Bool {
  false
}
