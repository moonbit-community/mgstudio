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
// Bevy source: `bevy/crates/bevy_ui_render/src/pipeline.rs`.
pub let ui_render_set_extract : @app.SystemSet = @app.system_set(
  "mgstudio.ui.render.extract",
)

///|
pub let ui_render_set_transparent_ui : @app.SystemSet = ui_render_set_extract

///|
const UI_DRAW_FLAG_TEXTURED : Int = 1

///|
const UI_DRAW_FLAG_ANTIALIAS : Int = 4

///|
const UI_DRAW_FLAG_BORDER_LEFT : Int = 256

///|
const UI_DRAW_FLAG_BORDER_TOP : Int = 512

///|
const UI_DRAW_FLAG_BORDER_RIGHT : Int = 1024

///|
const UI_DRAW_FLAG_BORDER_BOTTOM : Int = 2048

///|
fn ui_draw_border_flags(
  left : Float,
  top : Float,
  right : Float,
  bottom : Float,
) -> Int {
  let mut flags = 0
  if left > 0.0F {
    flags = flags | UI_DRAW_FLAG_BORDER_LEFT
  }
  if top > 0.0F {
    flags = flags | UI_DRAW_FLAG_BORDER_TOP
  }
  if right > 0.0F {
    flags = flags | UI_DRAW_FLAG_BORDER_RIGHT
  }
  if bottom > 0.0F {
    flags = flags | UI_DRAW_FLAG_BORDER_BOTTOM
  }
  flags
}
