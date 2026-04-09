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
// Bevy source: `bevy/crates/bevy_sprite_render/src/mesh2d/wireframe2d.rs`.
// Bridge surface to the root `sprite_render` package implementation.
pub using @sprite_render {type NoWireframe2d}

///|
pub using @sprite_render {type Wireframe2d}

///|
pub using @sprite_render {type Wireframe2dColor}

///|
pub using @sprite_render {type Wireframe2dConfig}

///|
pub let ecs_key_no_wireframe2d : @ecs.ComponentKey[@sprite_render.NoWireframe2d] = @sprite_render.ecs_key_no_wireframe2d

///|
pub let ecs_key_wireframe2d : @ecs.ComponentKey[@sprite_render.Wireframe2d] = @sprite_render.ecs_key_wireframe2d

///|
pub let ecs_key_wireframe2d_color : @ecs.ComponentKey[
  @sprite_render.Wireframe2dColor,
] = @sprite_render.ecs_key_wireframe2d_color

///|
pub let ecs_key_wireframe2d_config : @ecs.ResourceKey[
  @sprite_render.Wireframe2dConfig,
] = @sprite_render.ecs_key_wireframe2d_config

///|
pub fn wireframe2d_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  @sprite_render.wireframe2d_plugin(app)
}
