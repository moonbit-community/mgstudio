// Copyright 2026 International Digital Economy Academy
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

// Bevy source: `bevy/crates/bevy_pbr/src/render/mesh_view_bindings.rs`.

///|
const MESH_VIEW_LAYOUT_MULTISAMPLED : UInt = 1U << 0

///|
const MESH_VIEW_LAYOUT_DEPTH_PREPASS : UInt = 1U << 1

///|
const MESH_VIEW_LAYOUT_NORMAL_PREPASS : UInt = 1U << 2

///|
const MESH_VIEW_LAYOUT_MOTION_VECTOR_PREPASS : UInt = 1U << 3

///|
const MESH_VIEW_LAYOUT_DEFERRED_PREPASS : UInt = 1U << 4

///|
const MESH_VIEW_LAYOUT_OIT_ENABLED : UInt = 1U << 5

///|
const MESH_VIEW_LAYOUT_ATMOSPHERE : UInt = 1U << 6

///|
const MESH_VIEW_LAYOUT_STBN : UInt = 1U << 7

///|
pub struct MeshPipelineViewLayoutKey {
  bits : UInt
} derive(Eq, Debug, ToJson, FromJson)

///|
pub fn MeshPipelineViewLayoutKey::default() -> MeshPipelineViewLayoutKey {
  MeshPipelineViewLayoutKey::{ bits: 0U }
}

///|
fn mesh_view_layout_flag(enabled : Bool, flag : UInt) -> UInt {
  if enabled {
    flag
  } else {
    0U
  }
}

///|
pub fn mesh_view_layout_key(
  multisampled : Bool,
  depth_prepass : Bool,
  normal_prepass : Bool,
  motion_vector_prepass : Bool,
  deferred_prepass : Bool,
  oit_enabled : Bool,
  atmosphere : Bool,
  stbn : Bool,
) -> MeshPipelineViewLayoutKey {
  MeshPipelineViewLayoutKey::{
    bits: mesh_view_layout_flag(multisampled, MESH_VIEW_LAYOUT_MULTISAMPLED) |
    mesh_view_layout_flag(depth_prepass, MESH_VIEW_LAYOUT_DEPTH_PREPASS) |
    mesh_view_layout_flag(normal_prepass, MESH_VIEW_LAYOUT_NORMAL_PREPASS) |
    mesh_view_layout_flag(
      motion_vector_prepass,
      MESH_VIEW_LAYOUT_MOTION_VECTOR_PREPASS,
    ) |
    mesh_view_layout_flag(deferred_prepass, MESH_VIEW_LAYOUT_DEFERRED_PREPASS) |
    mesh_view_layout_flag(oit_enabled, MESH_VIEW_LAYOUT_OIT_ENABLED) |
    mesh_view_layout_flag(atmosphere, MESH_VIEW_LAYOUT_ATMOSPHERE) |
    mesh_view_layout_flag(stbn, MESH_VIEW_LAYOUT_STBN),
  }
}

///|
pub fn mesh_view_layout_key_from_msaa(
  msaa_samples : Int,
) -> MeshPipelineViewLayoutKey {
  mesh_view_layout_key(
    msaa_samples > 1,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
  )
}

///|
pub fn MeshPipelineViewLayoutKey::contains(
  self : MeshPipelineViewLayoutKey,
  flag : UInt,
) -> Bool {
  (self.bits & flag) != 0U
}

///|
pub fn MeshPipelineViewLayoutKey::label(
  self : MeshPipelineViewLayoutKey,
) -> String {
  let mut label = "mesh_view_layout"
  if self.contains(MESH_VIEW_LAYOUT_MULTISAMPLED) {
    label = "\{label}_multisampled"
  }
  if self.contains(MESH_VIEW_LAYOUT_DEPTH_PREPASS) {
    label = "\{label}_depth"
  }
  if self.contains(MESH_VIEW_LAYOUT_NORMAL_PREPASS) {
    label = "\{label}_normal"
  }
  if self.contains(MESH_VIEW_LAYOUT_MOTION_VECTOR_PREPASS) {
    label = "\{label}_motion"
  }
  if self.contains(MESH_VIEW_LAYOUT_DEFERRED_PREPASS) {
    label = "\{label}_deferred"
  }
  if self.contains(MESH_VIEW_LAYOUT_OIT_ENABLED) {
    label = "\{label}_oit"
  }
  if self.contains(MESH_VIEW_LAYOUT_ATMOSPHERE) {
    label = "\{label}_atmosphere"
  }
  if self.contains(MESH_VIEW_LAYOUT_STBN) {
    label = "\{label}_stbn"
  }
  label
}

///|
pub struct MeshViewBindGroupLayoutEntry {
  binding : Int
  name : String
  is_storage : Bool
  read_only : Bool
  has_dynamic_offset : Bool
}

///|
fn mesh_view_uniform_entry(
  binding : Int,
  name : String,
  has_dynamic_offset? : Bool = false,
) -> MeshViewBindGroupLayoutEntry {
  MeshViewBindGroupLayoutEntry::{
    binding,
    name,
    is_storage: false,
    read_only: true,
    has_dynamic_offset,
  }
}

///|
fn mesh_view_storage_entry(
  binding : Int,
  name : String,
  read_only : Bool,
  has_dynamic_offset? : Bool = false,
) -> MeshViewBindGroupLayoutEntry {
  MeshViewBindGroupLayoutEntry::{
    binding,
    name,
    is_storage: true,
    read_only,
    has_dynamic_offset,
  }
}

///|
pub fn render3d_mesh_view_layout_entries(
  clustered_forward_buffer_read_only : Bool,
  visibility_ranges_buffer_read_only : Bool,
  layout_key : MeshPipelineViewLayoutKey,
) -> (Array[MeshViewBindGroupLayoutEntry], Array[MeshViewBindGroupLayoutEntry]) {
  let main_entries : Array[MeshViewBindGroupLayoutEntry] = [
    mesh_view_uniform_entry(0, "view", has_dynamic_offset=true),
    mesh_view_uniform_entry(1, "lights", has_dynamic_offset=true),
    mesh_view_uniform_entry(2, "point_shadow_textures"),
    mesh_view_uniform_entry(3, "point_shadow_sampler"),
    mesh_view_uniform_entry(4, "directional_shadow_textures"),
    mesh_view_uniform_entry(5, "directional_shadow_sampler"),
    mesh_view_storage_entry(
      6, "clusterable_object_meta", clustered_forward_buffer_read_only,
    ),
    mesh_view_storage_entry(
      7, "visibility_ranges", visibility_ranges_buffer_read_only,
    ),
    mesh_view_uniform_entry(8, "globals", has_dynamic_offset=true),
    mesh_view_uniform_entry(9, "light_probes", has_dynamic_offset=true),
    mesh_view_uniform_entry(10, "fog", has_dynamic_offset=true),
  ]
  if layout_key.contains(MESH_VIEW_LAYOUT_DEPTH_PREPASS) {
    main_entries.push(mesh_view_uniform_entry(11, "depth_prepass_texture"))
  }
  if layout_key.contains(MESH_VIEW_LAYOUT_NORMAL_PREPASS) {
    main_entries.push(mesh_view_uniform_entry(12, "normal_prepass_texture"))
  }
  if layout_key.contains(MESH_VIEW_LAYOUT_MOTION_VECTOR_PREPASS) {
    main_entries.push(
      mesh_view_uniform_entry(13, "motion_vector_prepass_texture"),
    )
  }
  if layout_key.contains(MESH_VIEW_LAYOUT_DEFERRED_PREPASS) {
    main_entries.push(mesh_view_uniform_entry(14, "deferred_prepass_texture"))
  }
  if layout_key.contains(MESH_VIEW_LAYOUT_OIT_ENABLED) {
    main_entries.push(
      mesh_view_storage_entry(15, "oit_layers", false, has_dynamic_offset=true),
    )
  }
  if layout_key.contains(MESH_VIEW_LAYOUT_ATMOSPHERE) {
    main_entries.push(
      mesh_view_uniform_entry(16, "atmosphere", has_dynamic_offset=true),
    )
  }
  if layout_key.contains(MESH_VIEW_LAYOUT_STBN) {
    main_entries.push(mesh_view_uniform_entry(17, "stbn_texture"))
  }
  let binding_array_entries : Array[MeshViewBindGroupLayoutEntry] = [
    mesh_view_uniform_entry(0, "point_shadow_textures_array"),
    mesh_view_uniform_entry(1, "directional_shadow_textures_array"),
  ]
  (main_entries, binding_array_entries)
}

///|
pub struct MeshViewBindings3d {
  viewport : (Int, Int, Int, Int)?
  clear_enabled : Bool
  logical_rect : (Float, Float, Float, Float)
  view_matrix : ProjectionMatrix3d
  layout_key : MeshPipelineViewLayoutKey
}

///|
pub fn MeshViewBindings3d::default() -> MeshViewBindings3d {
  MeshViewBindings3d::{
    viewport: None,
    clear_enabled: true,
    logical_rect: (0.0F, 0.0F, 1.0F, 1.0F),
    view_matrix: ProjectionMatrix3d::from_cols(
      @math.Vec4::new(1.0F, 0.0F, 0.0F, 0.0F),
      @math.Vec4::new(0.0F, 1.0F, 0.0F, 0.0F),
      @math.Vec4::new(0.0F, 0.0F, 1.0F, 0.0F),
      @math.Vec4::new(0.0F, 0.0F, 0.0F, 1.0F),
    ),
    layout_key: MeshPipelineViewLayoutKey::default(),
  }
}

///|
pub fn render3d_mesh_view_bindings(
  target_info : RenderTargetComputed3d,
  camera_transform : @transform.Transform,
) -> MeshViewBindings3d {
  let logical_rect = (
    0.0F,
    0.0F,
    Float::from_int(target_info.target_size.x),
    Float::from_int(target_info.target_size.y),
  )
  let viewport = render3d_pass_viewport_for_target(
    target_info.target_id,
    target_info.target_id,
    0,
    0,
    target_info.target_size.x,
    target_info.target_size.y,
  )
  let clear_enabled = render3d_pass_clear_enabled_for_target(
      [],
      target_info.target_id,
      true,
    ) ==
    1
  MeshViewBindings3d::{
    viewport: Some(viewport),
    clear_enabled,
    logical_rect,
    view_matrix: render3d_view_from_world_matrix(camera_transform),
    layout_key: mesh_view_layout_key_from_msaa(1),
  }
}
