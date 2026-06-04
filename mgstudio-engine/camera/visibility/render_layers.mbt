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
// Bevy source: `bevy/crates/bevy_camera/src/visibility/render_layers.rs`.

///|
pub using @camera_render_layers {type Layer}

///|
pub using @camera_render_layers {type RenderLayers}

///|
pub using @camera_render_layers {default_layers}

///|
pub using @camera_render_layers {ecs_key_render_layers}

///|
pub fn render_layers_default() -> RenderLayers {
  RenderLayers::RenderLayers()
}

///|
pub fn render_layers_none() -> RenderLayers {
  RenderLayers::none()
}

///|
pub fn render_layers_layer(index : Layer) -> RenderLayers {
  RenderLayers::layer(index)
}

///|
pub fn render_layers_from_indices(indices : Array[Layer]) -> RenderLayers {
  RenderLayers::from_layers(indices)
}

///|
pub fn render_layers_matches(a : RenderLayers, b : RenderLayers) -> Bool {
  a.matches(b)
}
