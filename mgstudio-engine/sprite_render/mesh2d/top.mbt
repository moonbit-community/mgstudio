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
// Bevy source: `bevy/crates/bevy_sprite_render/src/mesh2d/mod.rs`.
// This package root is only the Bevy-equivalent module re-export surface. The
// concrete source owners live in the child packages.

///|
pub using @mesh {type Mesh2d}

///|
pub using @sprite_render_mesh2d_material {
  type AlphaMode2d,
  type Material2dKey,
  type Material2dPipeline,
  type Material2dPlugin,
  type MeshMaterial2d,
}

///|
pub using @sprite_render_mesh2d_color_material {
  type ColorMaterial,
  type ColorMaterialPlugin,
}

///|
pub using @sprite_render_mesh2d_runtime {
  type ExtractedMesh2d,
  type Mesh2dDrawPayload,
  type PhaseEntityRef,
}

///|
pub using @sprite_render_mesh2d_wireframe2d {
  type Mesh2dWireframe,
  type NoWireframe2d,
  type Wireframe2d,
  type Wireframe2dColor,
  type Wireframe2dConfig,
  type Wireframe2dMaterial,
  type Wireframe2dPlugin,
}

///|
pub let ecs_key_mesh2d : @ecs.ComponentKey[@mesh.Mesh2d] = @mesh.ecs_key_mesh2d

///|
pub let ecs_key_mesh_material2d : @ecs.ComponentKey[
  @sprite_render_mesh2d_material.MeshMaterial2d[
    @sprite_render_mesh2d_color_material.ColorMaterial,
  ],
] = @sprite_render_mesh2d_color_material.color_material_mesh_material2d_component()

///|
pub let ecs_key_no_wireframe2d : @ecs.ComponentKey[
  @sprite_render_mesh2d_wireframe2d.NoWireframe2d,
] = @sprite_render_mesh2d_wireframe2d.ecs_key_no_wireframe2d

///|
pub let ecs_key_wireframe2d : @ecs.ComponentKey[
  @sprite_render_mesh2d_wireframe2d.Wireframe2d,
] = @sprite_render_mesh2d_wireframe2d.ecs_key_wireframe2d

///|
pub let ecs_key_wireframe2d_color : @ecs.ComponentKey[
  @sprite_render_mesh2d_wireframe2d.Wireframe2dColor,
] = @sprite_render_mesh2d_wireframe2d.ecs_key_wireframe2d_color

///|
pub let ecs_key_wireframe2d_config : @ecs.ResourceKey[
  @sprite_render_mesh2d_wireframe2d.Wireframe2dConfig,
] = @sprite_render_mesh2d_wireframe2d.ecs_key_wireframe2d_config

///|
pub fn[M] material2d_plugin(
  plugin : @sprite_render_mesh2d_material.Material2dPlugin[M],
) -> @sprite_render_mesh2d_material.Material2dPlugin[M] {
  @sprite_render_mesh2d_material.material2d_plugin(plugin)
}

///|
pub fn color_material_plugin(
  plugin : @sprite_render_mesh2d_color_material.ColorMaterialPlugin,
) -> @sprite_render_mesh2d_color_material.ColorMaterialPlugin {
  @sprite_render_mesh2d_color_material.color_material_plugin(plugin)
}
