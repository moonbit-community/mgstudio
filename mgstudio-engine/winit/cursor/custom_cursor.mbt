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
// Bevy source: `bevy/crates/bevy_winit/src/cursor/custom_cursor.rs`.

///|
pub fn cursor_icon_from_custom(
  cursor : @window.CustomCursor,
) -> @window.CursorIcon {
  @window.CursorIcon::from_custom(cursor)
}

///|
pub fn custom_cursor_image(
  data : @window.CustomCursorImage,
) -> @window.CustomCursor {
  @window.CustomCursor::Image(data)
}

///|
pub fn custom_cursor_url(url : @window.CustomCursorUrl) -> @window.CustomCursor {
  @window.CustomCursor::Url(url)
}
