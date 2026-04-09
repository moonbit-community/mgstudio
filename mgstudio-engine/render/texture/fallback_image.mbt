// Copyright 2026 International Digital Economy Academy
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
// Bevy source: `bevy/crates/bevy_render/src/texture/fallback_image.rs`.

///|
pub const FALLBACK_TEXTURE_ID : Int = -1

///|
pub fn fallback_image_texture_id() -> Int {
  FALLBACK_TEXTURE_ID
}

///|
pub fn fallback_image_is_default(texture_id : Int) -> Bool {
  texture_id < 0
}
