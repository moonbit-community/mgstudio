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
// Bevy source: `bevy/crates/bevy_ui/src/update.rs`.
pub struct UiContext {
  mut white_texture : @asset.Handle[@asset.Image]
  mut viewport_origin : @math.Vec2
  mut viewport_size : @math.Vec2
  mut camera_entity : @core.Entity?
  mut camera_transform : @transform.Transform
  mut camera_scale : Float
  mut pointer_pos : @math.Vec2?
  mut pointer_down : Bool
  mut pointer_just_pressed : Bool
  mut pointer_just_released : Bool
  mut wheel_delta : @math.Vec2
}

///|
pub fn UiContext::default() -> UiContext {
  UiContext::{
    white_texture: @asset.Handle::new(-1),
    viewport_origin: @math.Vec2::new(0.0F, 0.0F),
    viewport_size: @math.Vec2::new(0.0F, 0.0F),
    camera_entity: None,
    camera_transform: @transform.Transform::identity(),
    camera_scale: 1.0F,
    pointer_pos: None,
    pointer_down: false,
    pointer_just_pressed: false,
    pointer_just_released: false,
    wheel_delta: @math.Vec2::new(0.0F, 0.0F),
  }
}

///|
pub fn UiContext::new(
  white_texture : @asset.Handle[@asset.Image],
  viewport_origin : @math.Vec2,
  viewport_size : @math.Vec2,
  camera_entity : @core.Entity?,
  camera_transform : @transform.Transform,
  camera_scale : Float,
  pointer_pos : @math.Vec2?,
  pointer_down : Bool,
  pointer_just_pressed? : Bool = false,
  pointer_just_released? : Bool = false,
  wheel_delta? : @math.Vec2 = @math.Vec2::new(0.0F, 0.0F),
) -> UiContext {
  UiContext::{
    white_texture,
    viewport_origin,
    viewport_size,
    camera_entity,
    camera_transform,
    camera_scale,
    pointer_pos,
    pointer_down,
    pointer_just_pressed,
    pointer_just_released,
    wheel_delta,
  }
}

///|
let ui_context_serde_next_id : Ref[Int] = Ref::new(1)

///|
let ui_context_serde_values : Map[Int, UiContext] = {}

///|
pub impl ToJson for UiContext with to_json(self) {
  let id = ui_context_serde_next_id.val
  ui_context_serde_next_id.val = id + 1
  ui_context_serde_values.set(id, self)
  id.to_json()
}

///|
pub impl @json.FromJson for UiContext with from_json(json, path) {
  let id : Int = @json.from_json(json, path~)
  ui_context_serde_values.get(id).unwrap_or(UiContext::default())
}

///|
pub let ui_set_focus : @app.SystemSet = @app.system_set("mgstudio.ui.focus")

///|
pub let ui_set_prepare : @app.SystemSet = @app.system_set("mgstudio.ui.prepare")

///|
pub let ui_set_propagate : @app.SystemSet = @app.system_set(
  "mgstudio.ui.propagate",
)

///|
pub let ui_set_text_content : @app.SystemSet = @app.system_set(
  "mgstudio.ui.text_content",
)

///|
pub let ui_set_content : @app.SystemSet = @app.system_set("mgstudio.ui.content")

///|
pub let ui_set_layout : @app.SystemSet = @app.system_set("mgstudio.ui.layout")

///|
pub let ui_set_post_layout : @app.SystemSet = @app.system_set(
  "mgstudio.ui.post_layout",
)

///|
pub let ui_set_stack : @app.SystemSet = @app.system_set("mgstudio.ui.stack")

///|
pub let ui_set_context : @app.SystemSet = ui_set_prepare

///|
pub let ui_set_interaction : @app.SystemSet = ui_set_focus

///|
pub let ui_set_scroll : @app.SystemSet = ui_set_propagate

///|
pub let ui_set_measure : @app.SystemSet = ui_set_content

///|
pub let ui_set_clip : @app.SystemSet = ui_set_post_layout
