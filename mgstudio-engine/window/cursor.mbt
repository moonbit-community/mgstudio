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
pub type CursorGrabMode = @window_cursor.CursorGrabMode

///|
pub type SystemCursorIcon = @window_cursor.SystemCursorIcon

///|
pub type CursorIcon = @window_cursor.CursorIcon

///|
pub type CustomCursor = @window_cursor.CustomCursor

///|
pub type CustomCursorImage = @window_cursor.CustomCursorImage

///|
pub type CustomCursorUrl = @window_cursor.CustomCursorUrl

///|
pub type CursorOptions = @window_cursor.CursorOptions

///|
pub let ecs_key_cursor_options : @ecs.ComponentKey[CursorOptions] = @window_cursor.ecs_key_cursor_options

///|
pub let ecs_key_cursor_icon : @ecs.ComponentKey[CursorIcon] = @window_cursor.ecs_key_cursor_icon

///|
pub fn cursor_icon_from_custom(cursor : CustomCursor) -> CursorIcon {
  @window_cursor.cursor_icon_from_custom(cursor)
}

///|
pub fn cursor_icon_from_system(icon : SystemCursorIcon) -> CursorIcon {
  @window_cursor.cursor_icon_from_system(icon)
}
