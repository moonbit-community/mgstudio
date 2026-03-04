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
pub(open) trait Has_Anchor {
  get_anchor_store(self : Self) -> @ecs.ComponentAccess[Anchor]
}

///|
pub(open) trait Has_Camera {
  get_camera_store(self : Self) -> @ecs.ComponentAccess[Camera]
}

///|
pub(open) trait Has_Mesh2d {
  get_mesh2d_store(self : Self) -> @ecs.ComponentAccess[Mesh2d]
}

///|
pub(open) trait Has_Sprite {
  get_sprite_store(self : Self) -> @ecs.ComponentAccess[Sprite]
}

///|
pub(open) trait Has_Bloom2d {
  get_bloom2d_store(self : Self) -> @ecs.ComponentAccess[Bloom2d]
}

///|
pub(open) trait Has_Camera2d {
  get_camera2d_store(self : Self) -> @ecs.ComponentAccess[Camera2d]
}

///|
pub(open) trait Has_GpuMesh2d {
  get_gpu_mesh2d_store(self : Self) -> @ecs.ComponentAccess[GpuMesh2d]
}

///|
pub(open) trait Has_Projection {
  get_projection_store(self : Self) -> @ecs.ComponentAccess[Projection]
}

///|
pub(open) trait Has_ScissorRect {
  get_scissor_rect_store(self : Self) -> @ecs.ComponentAccess[ScissorRect]
}

///|
pub(open) trait Has_Wireframe2d {
  get_wireframe2d_store(self : Self) -> @ecs.ComponentAccess[Wireframe2d]
}

///|
pub(open) trait Has_RenderLayers {
  get_render_layers_store(self : Self) -> @ecs.ComponentAccess[RenderLayers]
}

///|
pub(open) trait Has_RenderTarget {
  get_render_target_store(self : Self) -> @ecs.ComponentAccess[RenderTarget]
}

///|
pub(open) trait Has_ColorMaterial {
  get_color_material_store(self : Self) -> @ecs.ComponentAccess[ColorMaterial]
}

///|
pub(open) trait Has_NoWireframe2d {
  get_no_wireframe2d_store(self : Self) -> @ecs.ComponentAccess[NoWireframe2d]
}

///|
pub(open) trait Has_MeshMaterial2d {
  get_mesh_material2d_store(self : Self) -> @ecs.ComponentAccess[MeshMaterial2d]
}

///|
pub(open) trait Has_ClearColorConfig {
  get_clear_color_config_store(self : Self) -> @ecs.ComponentAccess[
    ClearColorConfig,
  ]
}

///|
pub(open) trait Has_Wireframe2dColor {
  get_wireframe2d_color_store(self : Self) -> @ecs.ComponentAccess[
    Wireframe2dColor,
  ]
}

///|
pub fn[W : Has_Anchor] get_anchor_store(
  world : W,
) -> @ecs.ComponentAccess[Anchor] {
  world.get_anchor_store()
}

///|
pub fn[W : Has_Camera] get_camera_store(
  world : W,
) -> @ecs.ComponentAccess[Camera] {
  world.get_camera_store()
}

///|
pub fn[W : Has_Mesh2d] get_mesh2d_store(
  world : W,
) -> @ecs.ComponentAccess[Mesh2d] {
  world.get_mesh2d_store()
}

///|
pub fn[W : Has_Sprite] get_sprite_store(
  world : W,
) -> @ecs.ComponentAccess[Sprite] {
  world.get_sprite_store()
}

///|
pub fn[W : Has_Bloom2d] get_bloom2d_store(
  world : W,
) -> @ecs.ComponentAccess[Bloom2d] {
  world.get_bloom2d_store()
}

///|
pub fn[W : Has_Camera2d] get_camera2d_store(
  world : W,
) -> @ecs.ComponentAccess[Camera2d] {
  world.get_camera2d_store()
}

///|
pub fn[W : Has_GpuMesh2d] get_gpu_mesh2d_store(
  world : W,
) -> @ecs.ComponentAccess[GpuMesh2d] {
  world.get_gpu_mesh2d_store()
}

///|
pub fn[W : Has_Projection] get_projection_store(
  world : W,
) -> @ecs.ComponentAccess[Projection] {
  world.get_projection_store()
}

///|
pub fn[W : Has_ScissorRect] get_scissor_rect_store(
  world : W,
) -> @ecs.ComponentAccess[ScissorRect] {
  world.get_scissor_rect_store()
}

///|
pub fn[W : Has_Wireframe2d] get_wireframe2d_store(
  world : W,
) -> @ecs.ComponentAccess[Wireframe2d] {
  world.get_wireframe2d_store()
}

///|
pub fn[W : Has_RenderLayers] get_render_layers_store(
  world : W,
) -> @ecs.ComponentAccess[RenderLayers] {
  world.get_render_layers_store()
}

///|
pub fn[W : Has_RenderTarget] get_render_target_store(
  world : W,
) -> @ecs.ComponentAccess[RenderTarget] {
  world.get_render_target_store()
}

///|
pub fn[W : Has_ColorMaterial] get_color_material_store(
  world : W,
) -> @ecs.ComponentAccess[ColorMaterial] {
  world.get_color_material_store()
}

///|
pub fn[W : Has_NoWireframe2d] get_no_wireframe2d_store(
  world : W,
) -> @ecs.ComponentAccess[NoWireframe2d] {
  world.get_no_wireframe2d_store()
}

///|
pub fn[W : Has_MeshMaterial2d] get_mesh_material2d_store(
  world : W,
) -> @ecs.ComponentAccess[MeshMaterial2d] {
  world.get_mesh_material2d_store()
}

///|
pub fn[W : Has_ClearColorConfig] get_clear_color_config_store(
  world : W,
) -> @ecs.ComponentAccess[ClearColorConfig] {
  world.get_clear_color_config_store()
}

///|
pub fn[W : Has_Wireframe2dColor] get_wireframe2d_color_store(
  world : W,
) -> @ecs.ComponentAccess[Wireframe2dColor] {
  world.get_wireframe2d_color_store()
}

///|
pub(open) trait HasRes_RenderState {
  get_render_state_resource(self : Self) -> @ecs.ResourceAccess[RenderState]
}

///|
pub(open) trait HasRes_Wireframe2dConfig {
  get_wireframe2d_config_resource(self : Self) -> @ecs.ResourceAccess[
    Wireframe2dConfig,
  ]
}

///|
pub fn[W : HasRes_RenderState] get_render_state_resource(
  world : W,
) -> @ecs.ResourceAccess[RenderState] {
  world.get_render_state_resource()
}

///|
pub fn[W : HasRes_Wireframe2dConfig] get_wireframe2d_config_resource(
  world : W,
) -> @ecs.ResourceAccess[Wireframe2dConfig] {
  world.get_wireframe2d_config_resource()
}

///|
/// ECS bridge impls for @ecs.World.

///|
pub impl Has_Anchor for @ecs.World with get_anchor_store(self) {
  self.component(ecs_key_anchor)
}

///|
pub impl Has_Camera for @ecs.World with get_camera_store(self) {
  self.component(ecs_key_camera)
}

///|
pub impl Has_Mesh2d for @ecs.World with get_mesh2d_store(self) {
  self.component(ecs_key_mesh2d)
}

///|
pub impl Has_Sprite for @ecs.World with get_sprite_store(self) {
  self.component(ecs_key_sprite)
}

///|
pub impl Has_Bloom2d for @ecs.World with get_bloom2d_store(self) {
  self.component(ecs_key_bloom2d)
}

///|
pub impl Has_Camera2d for @ecs.World with get_camera2d_store(self) {
  self.component(ecs_key_camera2d)
}

///|
pub impl Has_GpuMesh2d for @ecs.World with get_gpu_mesh2d_store(self) {
  self.component(ecs_key_gpu_mesh2d)
}

///|
pub impl Has_Projection for @ecs.World with get_projection_store(self) {
  self.component(ecs_key_projection)
}

///|
pub impl Has_ScissorRect for @ecs.World with get_scissor_rect_store(self) {
  self.component(ecs_key_scissor_rect)
}

///|
pub impl Has_Wireframe2d for @ecs.World with get_wireframe2d_store(self) {
  self.component(ecs_key_wireframe2d)
}

///|
pub impl Has_RenderLayers for @ecs.World with get_render_layers_store(self) {
  self.component(ecs_key_render_layers)
}

///|
pub impl Has_RenderTarget for @ecs.World with get_render_target_store(self) {
  self.component(ecs_key_render_target)
}

///|
pub impl Has_ColorMaterial for @ecs.World with get_color_material_store(self) {
  self.component(ecs_key_color_material)
}

///|
pub impl Has_NoWireframe2d for @ecs.World with get_no_wireframe2d_store(self) {
  self.component(ecs_key_no_wireframe2d)
}

///|
pub impl Has_MeshMaterial2d for @ecs.World with get_mesh_material2d_store(self) {
  self.component(ecs_key_mesh_material2d)
}

///|
pub impl Has_ClearColorConfig for @ecs.World with get_clear_color_config_store(
  self,
) {
  self.component(ecs_key_clear_color_config)
}

///|
pub impl Has_Wireframe2dColor for @ecs.World with get_wireframe2d_color_store(
  self,
) {
  self.component(ecs_key_wireframe2d_color)
}

///|
pub impl HasRes_RenderState for @ecs.World with get_render_state_resource(self) {
  self.resource(ecs_key_render_state)
}

///|
pub impl HasRes_Wireframe2dConfig for @ecs.World with get_wireframe2d_config_resource(
  self,
) {
  self.resource(ecs_key_wireframe2d_config)
}

///|
/// End ECS bridge impls.
