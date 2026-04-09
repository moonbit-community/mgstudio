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
// Bevy source: `bevy/crates/bevy_sprite_render/src/sprite_mesh/sprite_material.rs`.
// Bridge surface to the root `sprite_render` package implementation.
pub using @sprite_render {type OverlaySpriteUvScissor}

///|
pub fn render2d_push_sprite_uv_scissor_batch(
  world : @ecs.World,
  sprites : Array[@sprite_render.OverlaySpriteUvScissor],
) -> Unit {
  @sprite_render.render2d_push_sprite_uv_scissor_batch(world, sprites)
}
