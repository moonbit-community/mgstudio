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
// Bevy source: `bevy/crates/bevy_window/src/cursor/custom_cursor.rs`.

///|
pub struct CustomCursorImage {
  handle : @asset.Handle[@asset.Image]
  texture_atlas : @asset.TextureAtlas?
  flip_x : Bool
  flip_y : Bool
  rect : @math.URect?
  hotspot : (Int, Int)
}

///|
pub fn CustomCursorImage::new(
  handle : @asset.Handle[@asset.Image],
  hotspot : (Int, Int),
  texture_atlas? : @asset.TextureAtlas? = None,
  flip_x? : Bool = false,
  flip_y? : Bool = false,
  rect? : @math.URect? = None,
) -> CustomCursorImage {
  CustomCursorImage::{ handle, texture_atlas, flip_x, flip_y, rect, hotspot }
}

///|
pub struct CustomCursorUrl {
  url : String
  hotspot : (Int, Int)
}

///|
pub fn CustomCursorUrl::new(
  url : String,
  hotspot : (Int, Int),
) -> CustomCursorUrl {
  CustomCursorUrl::{ url, hotspot }
}

///|
pub(all) enum CustomCursor {
  Image(CustomCursorImage)
  Url(CustomCursorUrl)
}

///|
pub fn cursor_icon_from_custom(cursor : CustomCursor) -> CursorIcon {
  CursorIcon::from_custom(cursor)
}
