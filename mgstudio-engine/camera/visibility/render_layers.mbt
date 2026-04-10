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
pub type RenderLayers = @sprite.RenderLayers

///|
pub type Layer = Int

///|
pub let default_layers : RenderLayers = @sprite.RenderLayers::default()

///|
pub fn render_layers_default() -> RenderLayers {
  @sprite.RenderLayers::default()
}

///|
pub fn render_layers_none() -> RenderLayers {
  @sprite.RenderLayers::none()
}

///|
pub fn render_layers_layer(index : Layer) -> RenderLayers {
  @sprite.RenderLayers::layer(index)
}

///|
pub fn render_layers_from_indices(indices : Array[Layer]) -> RenderLayers {
  @sprite.RenderLayers::from_layers(indices)
}

///|
pub fn render_layers_matches(a : RenderLayers, b : RenderLayers) -> Bool {
  a.matches(b)
}
