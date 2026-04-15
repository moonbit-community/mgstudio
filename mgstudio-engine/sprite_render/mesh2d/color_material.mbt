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
// Bevy source: `bevy/crates/bevy_sprite_render/src/mesh2d/color_material.rs`.
pub using @sprite_render {type ColorMaterial}

///|
pub using @sprite_render {type ColorMaterialAsset}

///|
pub using @sprite_render {type ColorMaterialPlugin}

///|
pub let ecs_key_color_material : @ecs.ComponentKey[@sprite_render.ColorMaterial] = @sprite_render.ecs_key_color_material

///|
pub fn color_material_plugin(
  plugin : @sprite_render.ColorMaterialPlugin,
) -> @sprite_render.ColorMaterialPlugin {
  @sprite_render.color_material_plugin(plugin)
}
