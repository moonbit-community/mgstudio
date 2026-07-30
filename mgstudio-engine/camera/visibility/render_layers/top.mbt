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
// Bevy source: `bevy/crates/bevy_camera/src/visibility/render_layers.rs`.

///|
pub type Layer = Int

///|
pub let default_layers : RenderLayers = RenderLayers()

///|
pub struct RenderLayers {
  mask : Int
}

///|
fn render_layer_clamp_index(index : Int) -> Int {
  if index < 0 {
    0
  } else {
    index
  }
}

///|
fn render_layer_bit(index : Int) -> Int {
  1 << render_layer_clamp_index(index)
}

///|
pub fn RenderLayers::RenderLayers() -> RenderLayers {
  { mask: 1 }
}

///|
pub fn RenderLayers::none() -> RenderLayers {
  { mask: 0 }
}

///|
pub fn RenderLayers::layer(index : Layer) -> RenderLayers {
  { mask: render_layer_bit(index) }
}

///|
pub fn RenderLayers::matches(self : RenderLayers, other : RenderLayers) -> Bool {
  self.intersects(other)
}

///|
pub fn RenderLayers::intersects(
  self : RenderLayers,
  other : RenderLayers,
) -> Bool {
  (self.mask & other.mask) != 0
}

///|
pub fn RenderLayers::from_layers(layers : Array[Layer]) -> RenderLayers {
  let mut mask = 0
  for layer in layers {
    mask = mask | render_layer_bit(layer)
  }
  { mask, }
}

///|
pub fn RenderLayers::with_layer(
  self : RenderLayers,
  index : Layer,
) -> RenderLayers {
  { mask: self.mask | render_layer_bit(index) }
}

///|
pub fn RenderLayers::without_layer(
  self : RenderLayers,
  index : Layer,
) -> RenderLayers {
  let bit = render_layer_bit(index)
  if (self.mask & bit) != 0 {
    { mask: self.mask ^ bit }
  } else {
    self
  }
}

///|
pub fn RenderLayers::add(self : RenderLayers, index : Layer) -> RenderLayers {
  self.with_layer(index)
}

///|
pub fn RenderLayers::remove(self : RenderLayers, index : Layer) -> RenderLayers {
  self.without_layer(index)
}

///|
pub fn RenderLayers::contains(self : RenderLayers, index : Layer) -> Bool {
  (self.mask & render_layer_bit(index)) != 0
}

///|
pub fn RenderLayers::mask(self : RenderLayers) -> Int {
  self.mask
}

///|
pub fn RenderLayers::union(
  self : RenderLayers,
  other : RenderLayers,
) -> RenderLayers {
  { mask: self.mask | other.mask }
}

///|
pub fn RenderLayers::intersection(
  self : RenderLayers,
  other : RenderLayers,
) -> RenderLayers {
  { mask: self.mask & other.mask }
}

///|
pub fn RenderLayers::combine(
  self : RenderLayers,
  other : RenderLayers,
) -> RenderLayers {
  self.union(other)
}

///|
pub let ecs_key_render_layers : @ecs.ComponentKey[RenderLayers] = @ecs.register_component(
  debug_name="mgstudio.camera.visibility.render_layers",
)

///|
pub impl @ecs.Component for RenderLayers with fn component() {
  ecs_key_render_layers
}

///|
fn encode_render_layers(layers : RenderLayers) -> Json {
  layers.mask |> ToJson::to_json
}

///|
fn decode_render_layers(json : Json) -> RenderLayers {
  let mask : Int = try! @json.from_json(json)
  { mask, }
}

///|
pub impl ToJson for RenderLayers with fn to_json(self) {
  encode_render_layers(self)
}

///|
pub impl @json.FromJson for RenderLayers with fn from_json(json, _path) {
  decode_render_layers(json)
}
