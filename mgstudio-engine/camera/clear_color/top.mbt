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
// Bevy source: `bevy/crates/bevy_camera/src/clear_color.rs`.

///|
pub(all) enum ClearColorConfig {
  Default
  Custom(@color.Color)
  None
}

///|
pub fn ClearColorConfig::default() -> ClearColorConfig {
  Default
}

///|
pub fn ClearColorConfig::resolve(
  self : ClearColorConfig,
) -> (Bool, @color.Color) {
  match self {
    Default => (true, clear_color_current_value())
    Custom(color) => (true, color)
    None => (false, @color.Color::new(0.0F, 0.0F, 0.0F, 0.0F))
  }
}

///|
pub struct ClearColor {
  color : @color.Color
}

///|
pub fn ClearColor::new(color : @color.Color) -> ClearColor {
  { color, }
}

///|
pub fn ClearColor::ClearColor() -> ClearColor {
  { color: @color.Color::srgb(43.0F / 255.0F, 44.0F / 255.0F, 47.0F / 255.0F) }
}

///|
pub impl Default for ClearColor with fn default() {
  ClearColor()
}

///|
fn clear_color_default_value() -> @color.Color {
  ClearColor::ClearColor().color
}

///|
let clear_color_resource_key : @ecs.ResourceKey[ClearColor] = @ecs.register_resource(
  debug_name="mgstudio.camera.ClearColor",
)

///|
pub impl @app.Resource for ClearColor with fn resource() {
  clear_color_resource_key
}

///|
pub let ecs_key_clear_color_config : @ecs.ComponentKey[ClearColorConfig] = @ecs.register_component(
  debug_name="mgstudio.camera.clear_color_config",
)

///|
pub impl @ecs.Component for ClearColorConfig with fn component() {
  ecs_key_clear_color_config
}

///|
pub fn clear_color_current_value() -> @color.Color {
  match @app.current_world() {
    Some(world) => {
      let source_world = @render_sync_world.render_source_world(world)
      match source_world.get_resource(ClearColor::resource()) {
        Some(clear_color) => clear_color.color
        None => clear_color_default_value()
      }
    }
    None => clear_color_default_value()
  }
}

///|
pub fn encode_clear_color_config(clear_color : ClearColorConfig) -> Json {
  match clear_color {
    Default => (0, Json::null()) |> ToJson::to_json
    Custom(color) => (1, color |> ToJson::to_json) |> ToJson::to_json
    None => (2, Json::null()) |> ToJson::to_json
  }
}

///|
pub fn decode_clear_color_config(json : Json) -> ClearColorConfig {
  let (tag, payload) : (Int, Json) = try! @json.from_json(json)
  match tag {
    0 => Default
    1 => Custom(try! @json.from_json(payload))
    2 => None
    _ => Default
  }
}

///|
pub impl ToJson for ClearColorConfig with fn to_json(self) {
  encode_clear_color_config(self)
}

///|
pub impl @json.FromJson for ClearColorConfig with fn from_json(json, _path) {
  decode_clear_color_config(json)
}

///|
