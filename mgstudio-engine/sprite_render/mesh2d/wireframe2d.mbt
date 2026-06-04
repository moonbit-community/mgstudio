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
pub using @sprite {type NoWireframe2d}

///|
pub using @sprite {type Wireframe2d}

///|
pub using @sprite {type Wireframe2dColor}

///|
pub using @sprite {type Wireframe2dConfig}

///|
pub let ecs_key_no_wireframe2d : @ecs.ComponentKey[@sprite.NoWireframe2d] = @sprite.ecs_key_no_wireframe2d

///|
pub let ecs_key_wireframe2d : @ecs.ComponentKey[@sprite.Wireframe2d] = @sprite.ecs_key_wireframe2d

///|
pub let ecs_key_wireframe2d_color : @ecs.ComponentKey[@sprite.Wireframe2dColor] = @sprite.ecs_key_wireframe2d_color

///|
pub let ecs_key_wireframe2d_config : @ecs.ResourceKey[@sprite.Wireframe2dConfig] = @sprite.ecs_key_wireframe2d_config
