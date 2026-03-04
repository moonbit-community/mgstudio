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
/// ECS component bridge types.
pub let ecs_components : Array[String] = [
  "Anchor", "Camera", "Mesh2d", "Sprite", "Bloom2d", "Camera2d", "GpuMesh2d", "Projection",
  "ScissorRect", "Wireframe2d", "RenderLayers", "RenderTarget", "ColorMaterial",
  "NoWireframe2d", "MeshMaterial2d", "ClearColorConfig", "Wireframe2dColor",
]

///|
/// ECS resource bridge types.
pub let ecs_resources : Array[String] = ["RenderState", "Wireframe2dConfig"]

///|
pub fn get_anchor_store(world : @ecs.World) -> @ecs.ComponentAccess[Anchor] {
  world.component(ecs_key_anchor)
}

///|
pub fn get_camera_store(world : @ecs.World) -> @ecs.ComponentAccess[Camera] {
  world.component(ecs_key_camera)
}

///|
pub fn get_mesh2d_store(world : @ecs.World) -> @ecs.ComponentAccess[Mesh2d] {
  world.component(ecs_key_mesh2d)
}

///|
pub fn get_sprite_store(world : @ecs.World) -> @ecs.ComponentAccess[Sprite] {
  world.component(ecs_key_sprite)
}

///|
pub fn get_bloom2d_store(world : @ecs.World) -> @ecs.ComponentAccess[Bloom2d] {
  world.component(ecs_key_bloom2d)
}

///|
pub fn get_camera2d_store(world : @ecs.World) -> @ecs.ComponentAccess[Camera2d] {
  world.component(ecs_key_camera2d)
}

///|
pub fn get_gpu_mesh2d_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[GpuMesh2d] {
  world.component(ecs_key_gpu_mesh2d)
}

///|
pub fn get_projection_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[Projection] {
  world.component(ecs_key_projection)
}

///|
pub fn get_scissor_rect_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[ScissorRect] {
  world.component(ecs_key_scissor_rect)
}

///|
pub fn get_wireframe2d_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[Wireframe2d] {
  world.component(ecs_key_wireframe2d)
}

///|
pub fn get_render_layers_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[RenderLayers] {
  world.component(ecs_key_render_layers)
}

///|
pub fn get_render_target_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[RenderTarget] {
  world.component(ecs_key_render_target)
}

///|
pub fn get_color_material_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[ColorMaterial] {
  world.component(ecs_key_color_material)
}

///|
pub fn get_no_wireframe2d_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[NoWireframe2d] {
  world.component(ecs_key_no_wireframe2d)
}

///|
pub fn get_mesh_material2d_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[MeshMaterial2d] {
  world.component(ecs_key_mesh_material2d)
}

///|
pub fn get_clear_color_config_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[ClearColorConfig] {
  world.component(ecs_key_clear_color_config)
}

///|
pub fn get_wireframe2d_color_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[Wireframe2dColor] {
  world.component(ecs_key_wireframe2d_color)
}

///|
pub fn get_render_state_resource(
  world : @ecs.World,
) -> @ecs.ResourceAccess[RenderState] {
  world.resource(ecs_key_render_state)
}

///|
pub fn get_wireframe2d_config_resource(
  world : @ecs.World,
) -> @ecs.ResourceAccess[Wireframe2dConfig] {
  world.resource(ecs_key_wireframe2d_config)
}
