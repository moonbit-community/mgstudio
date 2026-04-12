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
// Bevy source: `bevy/crates/bevy_winit/src/cursor/mod.rs`.

///|
pub fn winit_cursor_icon_from_custom(
  cursor : @window.CustomCursor,
) -> @window.CursorIcon {
  cursor_icon_from_custom(cursor)
}

///|
pub fn winit_changed_cursor_options_system(world : @ecs.World) -> Unit {
  @window.window_backend_apply_changed_cursor_options_system(world)
}

///|
pub fn winit_cursor_options_default() -> @window.CursorOptions {
  @window.CursorOptions::default()
}
