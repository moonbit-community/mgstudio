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
// Bevy source: `bevy/crates/bevy_ui/src/update.rs::update_clipping_system`.

///|
/// A per-entity scissor rectangle in logical pixels, relative to the active
/// camera's view.
pub struct ScissorRect {
  rect : @math.Rect
}

///|
pub fn ScissorRect::new(rect : @math.Rect) -> ScissorRect {
  { rect, }
}

///|
pub let ecs_key_scissor_rect : @ecs.ComponentKey[ScissorRect] = @ecs.register_component(
  debug_name="ui.scissor_rect",
)

///|
pub impl @ecs.Component for ScissorRect with fn component() {
  ecs_key_scissor_rect
}

///|
pub impl ToJson for ScissorRect with fn to_json(self) {
  self.rect.to_json()
}

///|
pub impl @json.FromJson for ScissorRect with fn from_json(json, path) {
  ScissorRect::new(@json.from_json(json, path~))
}
