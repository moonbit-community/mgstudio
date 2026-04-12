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
// Bevy source: `bevy/crates/bevy_window/src/cursor/mod.rs`.

///|
pub type CursorGrabMode = @window.CursorGrabMode

///|
pub type CursorIcon = @window.CursorIcon

///|
pub type CursorOptions = @window.CursorOptions

///|
pub type CustomCursor = @window.CustomCursor

///|
pub type CustomCursorImage = @window.CustomCursorImage

///|
pub type CustomCursorUrl = @window.CustomCursorUrl

///|
pub let ecs_key_cursor_options : @ecs.ComponentKey[CursorOptions] = @window.ecs_key_cursor_options

///|
pub let ecs_key_cursor_icon : @ecs.ComponentKey[CursorIcon] = @window.ecs_key_cursor_icon
