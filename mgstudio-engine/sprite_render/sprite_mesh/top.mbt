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
// Bevy source: `bevy/crates/bevy_sprite_render/src/sprite_mesh/mod.rs`.
// Bridge surface to the root `sprite_render` package implementation.
pub using @sprite_render {type SceneCullContext}

///|
pub using @sprite_render {type UiBorderRect}

///|
pub using @sprite_render {type UiCornerRadii}

///|
pub fn render2d_primary_scene_cull_context(
  world : @ecs.World,
) -> @sprite_render.SceneCullContext? {
  @sprite_render.render2d_primary_scene_cull_context(world)
}

///|
pub fn render2d_scene_cull_context_values(
  context : @sprite_render.SceneCullContext,
) -> (Float, Float, Float, Float, Float, Float) {
  @sprite_render.render2d_scene_cull_context_values(context)
}

///|
pub fn render2d_scene_item_visible(
  context : @sprite_render.SceneCullContext,
  x : Float,
  y : Float,
  radius : Float,
) -> Bool {
  @sprite_render.render2d_scene_item_visible(context, x, y, radius)
}
