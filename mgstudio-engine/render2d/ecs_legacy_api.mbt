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
/// Legacy ECS component types.
pub let ecs_components : Array[String] = [
  "Anchor", "Camera", "Mesh2d", "Sprite", "Bloom2d", "Camera2d", "GpuMesh2d", "Projection",
  "ScissorRect", "Wireframe2d", "RenderLayers", "RenderTarget", "ColorMaterial",
  "NoWireframe2d", "MeshMaterial2d", "ClearColorConfig", "Wireframe2dColor",
]

///|
/// Legacy ECS resource types.
pub let ecs_resources : Array[String] = ["RenderState", "Wireframe2dConfig"]

///|
pub(open) trait Has_Anchor {
  get_anchor_store(self : Self) -> @core.ComponentStore[Anchor]
}

///|
pub(open) trait Has_Camera {
  get_camera_store(self : Self) -> @core.ComponentStore[Camera]
}

///|
pub(open) trait Has_Mesh2d {
  get_mesh2d_store(self : Self) -> @core.ComponentStore[Mesh2d]
}

///|
pub(open) trait Has_Sprite {
  get_sprite_store(self : Self) -> @core.ComponentStore[Sprite]
}

///|
pub(open) trait Has_Bloom2d {
  get_bloom2d_store(self : Self) -> @core.ComponentStore[Bloom2d]
}

///|
pub(open) trait Has_Camera2d {
  get_camera2d_store(self : Self) -> @core.ComponentStore[Camera2d]
}

///|
pub(open) trait Has_GpuMesh2d {
  get_gpu_mesh2d_store(self : Self) -> @core.ComponentStore[GpuMesh2d]
}

///|
pub(open) trait Has_Projection {
  get_projection_store(self : Self) -> @core.ComponentStore[Projection]
}

///|
pub(open) trait Has_ScissorRect {
  get_scissor_rect_store(self : Self) -> @core.ComponentStore[ScissorRect]
}

///|
pub(open) trait Has_Wireframe2d {
  get_wireframe2d_store(self : Self) -> @core.ComponentStore[Wireframe2d]
}

///|
pub(open) trait Has_RenderLayers {
  get_render_layers_store(self : Self) -> @core.ComponentStore[RenderLayers]
}

///|
pub(open) trait Has_RenderTarget {
  get_render_target_store(self : Self) -> @core.ComponentStore[RenderTarget]
}

///|
pub(open) trait Has_ColorMaterial {
  get_color_material_store(self : Self) -> @core.ComponentStore[ColorMaterial]
}

///|
pub(open) trait Has_NoWireframe2d {
  get_no_wireframe2d_store(self : Self) -> @core.ComponentStore[NoWireframe2d]
}

///|
pub(open) trait Has_MeshMaterial2d {
  get_mesh_material2d_store(self : Self) -> @core.ComponentStore[MeshMaterial2d]
}

///|
pub(open) trait Has_ClearColorConfig {
  get_clear_color_config_store(self : Self) -> @core.ComponentStore[
    ClearColorConfig,
  ]
}

///|
pub(open) trait Has_Wireframe2dColor {
  get_wireframe2d_color_store(self : Self) -> @core.ComponentStore[
    Wireframe2dColor,
  ]
}

///|
pub fn[W : Has_Anchor] query_get_anchor_store(
  world : W,
) -> @core.ComponentStore[Anchor] {
  world.get_anchor_store()
}

///|
pub fn[W : Has_Camera] query_get_camera_store(
  world : W,
) -> @core.ComponentStore[Camera] {
  world.get_camera_store()
}

///|
pub fn[W : Has_Mesh2d] query_get_mesh2d_store(
  world : W,
) -> @core.ComponentStore[Mesh2d] {
  world.get_mesh2d_store()
}

///|
pub fn[W : Has_Sprite] query_get_sprite_store(
  world : W,
) -> @core.ComponentStore[Sprite] {
  world.get_sprite_store()
}

///|
pub fn[W : Has_Bloom2d] query_get_bloom2d_store(
  world : W,
) -> @core.ComponentStore[Bloom2d] {
  world.get_bloom2d_store()
}

///|
pub fn[W : Has_Camera2d] query_get_camera2d_store(
  world : W,
) -> @core.ComponentStore[Camera2d] {
  world.get_camera2d_store()
}

///|
pub fn[W : Has_GpuMesh2d] query_get_gpu_mesh2d_store(
  world : W,
) -> @core.ComponentStore[GpuMesh2d] {
  world.get_gpu_mesh2d_store()
}

///|
pub fn[W : Has_Projection] query_get_projection_store(
  world : W,
) -> @core.ComponentStore[Projection] {
  world.get_projection_store()
}

///|
pub fn[W : Has_ScissorRect] query_get_scissor_rect_store(
  world : W,
) -> @core.ComponentStore[ScissorRect] {
  world.get_scissor_rect_store()
}

///|
pub fn[W : Has_Wireframe2d] query_get_wireframe2d_store(
  world : W,
) -> @core.ComponentStore[Wireframe2d] {
  world.get_wireframe2d_store()
}

///|
pub fn[W : Has_RenderLayers] query_get_render_layers_store(
  world : W,
) -> @core.ComponentStore[RenderLayers] {
  world.get_render_layers_store()
}

///|
pub fn[W : Has_RenderTarget] query_get_render_target_store(
  world : W,
) -> @core.ComponentStore[RenderTarget] {
  world.get_render_target_store()
}

///|
pub fn[W : Has_ColorMaterial] query_get_color_material_store(
  world : W,
) -> @core.ComponentStore[ColorMaterial] {
  world.get_color_material_store()
}

///|
pub fn[W : Has_NoWireframe2d] query_get_no_wireframe2d_store(
  world : W,
) -> @core.ComponentStore[NoWireframe2d] {
  world.get_no_wireframe2d_store()
}

///|
pub fn[W : Has_MeshMaterial2d] query_get_mesh_material2d_store(
  world : W,
) -> @core.ComponentStore[MeshMaterial2d] {
  world.get_mesh_material2d_store()
}

///|
pub fn[W : Has_ClearColorConfig] query_get_clear_color_config_store(
  world : W,
) -> @core.ComponentStore[ClearColorConfig] {
  world.get_clear_color_config_store()
}

///|
pub fn[W : Has_Wireframe2dColor] query_get_wireframe2d_color_store(
  world : W,
) -> @core.ComponentStore[Wireframe2dColor] {
  world.get_wireframe2d_color_store()
}

///|
pub(open) trait HasRes_RenderState {
  get_render_state_resource(self : Self) -> @core.Resource[RenderState]
}

///|
pub(open) trait HasRes_Wireframe2dConfig {
  get_wireframe2d_config_resource(self : Self) -> @core.Resource[
    Wireframe2dConfig,
  ]
}

///|
pub fn[W : HasRes_RenderState] query_get_render_state_resource(
  world : W,
) -> @core.Resource[RenderState] {
  world.get_render_state_resource()
}

///|
pub fn[W : HasRes_Wireframe2dConfig] query_get_wireframe2d_config_resource(
  world : W,
) -> @core.Resource[Wireframe2dConfig] {
  world.get_wireframe2d_config_resource()
}

///|
/// ECS bridge impls for @ecs.World (auto-generated).

///|
let bridge_get_anchor_store_by_world : Map[Int, @core.ComponentStore[Anchor]] = {}

///|
pub impl Has_Anchor for @ecs.World with get_anchor_store(self) {
  bridge_get_anchor_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_camera_store_by_world : Map[Int, @core.ComponentStore[Camera]] = {}

///|
pub impl Has_Camera for @ecs.World with get_camera_store(self) {
  bridge_get_camera_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_mesh2d_store_by_world : Map[Int, @core.ComponentStore[Mesh2d]] = {}

///|
pub impl Has_Mesh2d for @ecs.World with get_mesh2d_store(self) {
  bridge_get_mesh2d_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_sprite_store_by_world : Map[Int, @core.ComponentStore[Sprite]] = {}

///|
pub impl Has_Sprite for @ecs.World with get_sprite_store(self) {
  bridge_get_sprite_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_bloom2d_store_by_world : Map[Int, @core.ComponentStore[Bloom2d]] = {}

///|
pub impl Has_Bloom2d for @ecs.World with get_bloom2d_store(self) {
  bridge_get_bloom2d_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_camera2d_store_by_world : Map[
  Int,
  @core.ComponentStore[Camera2d],
] = {}

///|
pub impl Has_Camera2d for @ecs.World with get_camera2d_store(self) {
  bridge_get_camera2d_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_gpu_mesh2d_store_by_world : Map[
  Int,
  @core.ComponentStore[GpuMesh2d],
] = {}

///|
pub impl Has_GpuMesh2d for @ecs.World with get_gpu_mesh2d_store(self) {
  bridge_get_gpu_mesh2d_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_projection_store_by_world : Map[
  Int,
  @core.ComponentStore[Projection],
] = {}

///|
pub impl Has_Projection for @ecs.World with get_projection_store(self) {
  bridge_get_projection_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_scissor_rect_store_by_world : Map[
  Int,
  @core.ComponentStore[ScissorRect],
] = {}

///|
pub impl Has_ScissorRect for @ecs.World with get_scissor_rect_store(self) {
  bridge_get_scissor_rect_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_wireframe2d_store_by_world : Map[
  Int,
  @core.ComponentStore[Wireframe2d],
] = {}

///|
pub impl Has_Wireframe2d for @ecs.World with get_wireframe2d_store(self) {
  bridge_get_wireframe2d_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_render_layers_store_by_world : Map[
  Int,
  @core.ComponentStore[RenderLayers],
] = {}

///|
pub impl Has_RenderLayers for @ecs.World with get_render_layers_store(self) {
  bridge_get_render_layers_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_render_target_store_by_world : Map[
  Int,
  @core.ComponentStore[RenderTarget],
] = {}

///|
pub impl Has_RenderTarget for @ecs.World with get_render_target_store(self) {
  bridge_get_render_target_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_color_material_store_by_world : Map[
  Int,
  @core.ComponentStore[ColorMaterial],
] = {}

///|
pub impl Has_ColorMaterial for @ecs.World with get_color_material_store(self) {
  bridge_get_color_material_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_no_wireframe2d_store_by_world : Map[
  Int,
  @core.ComponentStore[NoWireframe2d],
] = {}

///|
pub impl Has_NoWireframe2d for @ecs.World with get_no_wireframe2d_store(self) {
  bridge_get_no_wireframe2d_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_mesh_material2d_store_by_world : Map[
  Int,
  @core.ComponentStore[MeshMaterial2d],
] = {}

///|
pub impl Has_MeshMaterial2d for @ecs.World with get_mesh_material2d_store(self) {
  bridge_get_mesh_material2d_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_clear_color_config_store_by_world : Map[
  Int,
  @core.ComponentStore[ClearColorConfig],
] = {}

///|
pub impl Has_ClearColorConfig for @ecs.World with get_clear_color_config_store(
  self,
) {
  bridge_get_clear_color_config_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_wireframe2d_color_store_by_world : Map[
  Int,
  @core.ComponentStore[Wireframe2dColor],
] = {}

///|
pub impl Has_Wireframe2dColor for @ecs.World with get_wireframe2d_color_store(
  self,
) {
  bridge_get_wireframe2d_color_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_render_state_resource_by_world : Map[
  Int,
  @core.Resource[RenderState],
] = {}

///|
pub impl HasRes_RenderState for @ecs.World with get_render_state_resource(self) {
  bridge_get_render_state_resource_by_world.get_or_init(self.world_id(), fn() {
    @core.Resource::new()
  })
}

///|
let bridge_get_wireframe2d_config_resource_by_world : Map[
  Int,
  @core.Resource[Wireframe2dConfig],
] = {}

///|
pub impl HasRes_Wireframe2dConfig for @ecs.World with get_wireframe2d_config_resource(
  self,
) {
  bridge_get_wireframe2d_config_resource_by_world.get_or_init(self.world_id(), fn() {
    @core.Resource::new()
  })
}

///|
/// End ECS bridge impls.
