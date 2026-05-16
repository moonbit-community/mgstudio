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

///|
// Bevy source: `bevy/crates/bevy_pbr/src/meshlet/material_shade_nodes.rs`.

///|
pub const MESHLET_MAIN_OPAQUE_PASS_NODE : String = "mgstudio.pbr.meshlet.main_opaque_pass"

///|
pub const MESHLET_PREPASS_NODE : String = "mgstudio.pbr.meshlet.prepass"

///|
pub const MESHLET_DEFERRED_GBUFFER_PREPASS_NODE : String = "mgstudio.pbr.meshlet.deferred_gbuffer_prepass"

///|
pub fn meshlet_material_shade_nodes() -> Array[String] {
  [
    MESHLET_MAIN_OPAQUE_PASS_NODE,
    MESHLET_PREPASS_NODE,
    MESHLET_DEFERRED_GBUFFER_PREPASS_NODE,
  ]
}

///|
pub fn meshlet_material_shade_node_count() -> Int {
  meshlet_material_shade_nodes().length()
}

///|
pub fn meshlet_material_shade_node_index(node : String) -> Int? {
  let nodes = meshlet_material_shade_nodes()
  for index in 0..<nodes.length() {
    if nodes[index] == node {
      return Some(index)
    }
  }
  None
}

///|
pub(all) enum MeshletMaterialShadePassVariant {
  MainOpaque
  Prepass
  DeferredGBufferPrepass
} derive(Eq, Debug)

///|
pub struct MeshletMaterialShadePassDescriptor {
  pass_variant : MeshletMaterialShadePassVariant
  label : String
  color_attachment_slots : Array[String]
  depth_load : String
  depth_store : String
  view_bind_group_kind : String
  view_bind_group_dynamic_offset_count : Int
  sets_binding_array_group : Bool
  material_shade_bind_group_index : Int
  material_bind_group_index : Int
  uses_main_pass_resolution_override : Bool
  uses_motion_vector_prepass_bind_group : Bool
  requires_material_depth : Bool
  requires_material_shade_bind_group : Bool
} derive(Eq, Debug)

///|
fn meshlet_material_shade_pass_descriptor(
  pass_variant : MeshletMaterialShadePassVariant,
  uses_motion_vector_prepass_bind_group? : Bool = false,
) -> MeshletMaterialShadePassDescriptor {
  match pass_variant {
    MainOpaque =>
      MeshletMaterialShadePassDescriptor::{
        pass_variant,
        label: "meshlet_material_opaque_3d_pass",
        color_attachment_slots: ["view_target"],
        depth_load: "Load",
        depth_store: "Store",
        view_bind_group_kind: "mesh_view",
        view_bind_group_dynamic_offset_count: 7,
        sets_binding_array_group: true,
        material_shade_bind_group_index: 2,
        material_bind_group_index: 3,
        uses_main_pass_resolution_override: true,
        uses_motion_vector_prepass_bind_group: false,
        requires_material_depth: true,
        requires_material_shade_bind_group: true,
      }
    Prepass =>
      MeshletMaterialShadePassDescriptor::{
        pass_variant,
        label: "meshlet_material_prepass",
        color_attachment_slots: ["normal", "motion_vectors", "none", "none"],
        depth_load: "Load",
        depth_store: "Store",
        view_bind_group_kind: if uses_motion_vector_prepass_bind_group {
          "prepass_motion_vectors"
        } else {
          "prepass_no_motion_vectors"
        },
        view_bind_group_dynamic_offset_count: if uses_motion_vector_prepass_bind_group {
          2
        } else {
          1
        },
        sets_binding_array_group: false,
        material_shade_bind_group_index: 2,
        material_bind_group_index: 2,
        uses_main_pass_resolution_override: true,
        uses_motion_vector_prepass_bind_group,
        requires_material_depth: true,
        requires_material_shade_bind_group: true,
      }
    DeferredGBufferPrepass =>
      MeshletMaterialShadePassDescriptor::{
        pass_variant,
        label: "meshlet_material_deferred_prepass",
        color_attachment_slots: [
          "normal", "motion_vectors", "deferred", "deferred_lighting_pass_id",
        ],
        depth_load: "Load",
        depth_store: "Store",
        view_bind_group_kind: if uses_motion_vector_prepass_bind_group {
          "prepass_motion_vectors"
        } else {
          "prepass_no_motion_vectors"
        },
        view_bind_group_dynamic_offset_count: if uses_motion_vector_prepass_bind_group {
          2
        } else {
          1
        },
        sets_binding_array_group: false,
        material_shade_bind_group_index: 2,
        material_bind_group_index: 2,
        uses_main_pass_resolution_override: true,
        uses_motion_vector_prepass_bind_group,
        requires_material_depth: true,
        requires_material_shade_bind_group: true,
      }
  }
}

///|
pub fn meshlet_main_opaque_pass_descriptor() -> MeshletMaterialShadePassDescriptor {
  meshlet_material_shade_pass_descriptor(
    MeshletMaterialShadePassVariant::MainOpaque,
  )
}

///|
pub fn meshlet_prepass_descriptor(
  uses_motion_vector_prepass_bind_group? : Bool = false,
) -> MeshletMaterialShadePassDescriptor {
  meshlet_material_shade_pass_descriptor(
    MeshletMaterialShadePassVariant::Prepass,
    uses_motion_vector_prepass_bind_group~,
  )
}

///|
pub fn meshlet_deferred_gbuffer_prepass_descriptor(
  uses_motion_vector_prepass_bind_group? : Bool = false,
) -> MeshletMaterialShadePassDescriptor {
  meshlet_material_shade_pass_descriptor(
    MeshletMaterialShadePassVariant::DeferredGBufferPrepass,
    uses_motion_vector_prepass_bind_group~,
  )
}

///|
fn meshlet_clamp_draw_count(draw_count : Int) -> Int {
  if draw_count < 0 {
    0
  } else {
    draw_count
  }
}

///|
fn meshlet_pipeline_id_valid(pipeline_id : Int) -> Bool {
  pipeline_id >= 0
}

///|
pub struct MeshletMaterialDrawCall {
  material_id : Int
  material_pipeline_id : Int
  material_bind_group : Int
  vertex_start : Int
  vertex_end : Int
} derive(Eq, Debug)

///|
pub struct MeshletMaterialShadePassPlan {
  descriptor : MeshletMaterialShadePassDescriptor
  draw_calls : Array[MeshletMaterialDrawCall]
  render_pass_enabled : Bool
} derive(Eq, Debug)

///|
pub(all) enum MeshletMaterialShadePassCommandKind {
  BeginRenderPass
  SetCameraViewport
  SetBindGroup
  SetRenderPipeline
  Draw
} derive(Eq, Debug)

///|
pub struct MeshletMaterialShadePassCommand {
  kind : MeshletMaterialShadePassCommandKind
  label : String
  bind_group_index : Int
  bind_group_kind : String
  dynamic_offset_count : Int
  material_id : Int
  material_pipeline_id : Int
  material_bind_group : Int
  vertex_start : Int
  vertex_end : Int
} derive(Eq, Debug)

///|
fn meshlet_material_shade_command(
  kind : MeshletMaterialShadePassCommandKind,
  label? : String = "",
  bind_group_index? : Int = -1,
  bind_group_kind? : String = "",
  dynamic_offset_count? : Int = 0,
  material_id? : Int = -1,
  material_pipeline_id? : Int = -1,
  material_bind_group? : Int = -1,
  vertex_start? : Int = 0,
  vertex_end? : Int = 0,
) -> MeshletMaterialShadePassCommand {
  MeshletMaterialShadePassCommand::{
    kind,
    label,
    bind_group_index,
    bind_group_kind,
    dynamic_offset_count,
    material_id,
    material_pipeline_id,
    material_bind_group,
    vertex_start,
    vertex_end,
  }
}

///|
fn meshlet_material_bin_draw_calls(
  material_bins : Array[MeshletViewMaterialEntry],
  instance_manager : InstanceManager,
  has_material_depth : Bool,
  has_material_shade_bind_group : Bool,
) -> Array[MeshletMaterialDrawCall] {
  if material_bins.is_empty() {
    return []
  }
  if !has_material_depth || !has_material_shade_bind_group {
    return []
  }
  let draw_calls : Array[MeshletMaterialDrawCall] = []
  for material_bin in material_bins {
    if meshlet_pipeline_id_valid(material_bin.material_pipeline_id) &&
      instance_manager.material_present_in_scene(material_bin.material_id) {
      let vertex_start = material_bin.material_id * 3
      draw_calls.push(MeshletMaterialDrawCall::{
        material_id: material_bin.material_id,
        material_pipeline_id: material_bin.material_pipeline_id,
        material_bind_group: material_bin.material_bind_group,
        vertex_start,
        vertex_end: vertex_start + 3,
      })
    }
  }
  draw_calls
}

///|
fn meshlet_material_shade_pass_plan(
  descriptor : MeshletMaterialShadePassDescriptor,
  material_bins : Array[MeshletViewMaterialEntry],
  instance_manager : InstanceManager,
  has_material_depth : Bool,
  has_material_shade_bind_group : Bool,
) -> MeshletMaterialShadePassPlan {
  let draw_calls = meshlet_material_bin_draw_calls(
    material_bins, instance_manager, has_material_depth, has_material_shade_bind_group,
  )
  MeshletMaterialShadePassPlan::{
    descriptor,
    draw_calls,
    render_pass_enabled: draw_calls.length() > 0,
  }
}

///|
fn meshlet_material_bin_draw_count(
  material_bins : Array[MeshletViewMaterialEntry],
  instance_manager : InstanceManager,
  has_material_depth : Bool,
  has_material_shade_bind_group : Bool,
) -> Int {
  meshlet_material_bin_draw_calls(
    material_bins, instance_manager, has_material_depth, has_material_shade_bind_group,
  ).length()
}

///|
pub fn meshlet_main_opaque_pass_plan(
  materials : MeshletViewMaterialsMainOpaquePass,
  instance_manager : InstanceManager,
  has_material_depth? : Bool = true,
  has_material_shade_bind_group? : Bool = true,
) -> MeshletMaterialShadePassPlan {
  meshlet_material_shade_pass_plan(
    meshlet_main_opaque_pass_descriptor(),
    materials.entries,
    instance_manager,
    has_material_depth,
    has_material_shade_bind_group,
  )
}

///|
pub fn meshlet_prepass_plan(
  materials : MeshletViewMaterialsPrepass,
  instance_manager : InstanceManager,
  has_material_depth? : Bool = true,
  has_material_shade_bind_group? : Bool = true,
  uses_motion_vector_prepass_bind_group? : Bool = false,
) -> MeshletMaterialShadePassPlan {
  meshlet_material_shade_pass_plan(
    meshlet_prepass_descriptor(uses_motion_vector_prepass_bind_group~),
    materials.entries,
    instance_manager,
    has_material_depth,
    has_material_shade_bind_group,
  )
}

///|
pub fn meshlet_deferred_gbuffer_prepass_plan(
  materials : MeshletViewMaterialsDeferredGBufferPrepass,
  instance_manager : InstanceManager,
  has_material_depth? : Bool = true,
  has_material_shade_bind_group? : Bool = true,
  uses_motion_vector_prepass_bind_group? : Bool = false,
) -> MeshletMaterialShadePassPlan {
  meshlet_material_shade_pass_plan(
    meshlet_deferred_gbuffer_prepass_descriptor(
      uses_motion_vector_prepass_bind_group~,
    ),
    materials.entries,
    instance_manager,
    has_material_depth,
    has_material_shade_bind_group,
  )
}

///|
pub fn MeshletMaterialShadePassPlan::draw_count(
  self : MeshletMaterialShadePassPlan,
) -> Int {
  self.draw_calls.length()
}

///|
pub fn meshlet_material_shade_pass_commands(
  plan : MeshletMaterialShadePassPlan,
  has_camera_viewport? : Bool = false,
) -> Array[MeshletMaterialShadePassCommand] {
  if !plan.render_pass_enabled {
    return []
  }
  let commands : Array[MeshletMaterialShadePassCommand] = []
  let descriptor = plan.descriptor
  commands.push(
    meshlet_material_shade_command(
      MeshletMaterialShadePassCommandKind::BeginRenderPass,
      label=descriptor.label,
    ),
  )
  if has_camera_viewport && descriptor.uses_main_pass_resolution_override {
    commands.push(
      meshlet_material_shade_command(
        MeshletMaterialShadePassCommandKind::SetCameraViewport,
        label="camera_viewport",
      ),
    )
  }
  commands.push(
    meshlet_material_shade_command(
      MeshletMaterialShadePassCommandKind::SetBindGroup,
      bind_group_index=0,
      bind_group_kind=descriptor.view_bind_group_kind,
      dynamic_offset_count=descriptor.view_bind_group_dynamic_offset_count,
    ),
  )
  commands.push(
    meshlet_material_shade_command(
      MeshletMaterialShadePassCommandKind::SetBindGroup,
      bind_group_index=1,
      bind_group_kind=if descriptor.sets_binding_array_group {
        "binding_array"
      } else {
        "empty"
      },
    ),
  )
  commands.push(
    meshlet_material_shade_command(
      MeshletMaterialShadePassCommandKind::SetBindGroup,
      bind_group_index=descriptor.material_shade_bind_group_index,
      bind_group_kind="material_shade",
    ),
  )
  for draw_call in plan.draw_calls {
    commands.push(
      meshlet_material_shade_command(
        MeshletMaterialShadePassCommandKind::SetRenderPipeline,
        material_id=draw_call.material_id,
        material_pipeline_id=draw_call.material_pipeline_id,
      ),
    )
    commands.push(
      meshlet_material_shade_command(
        MeshletMaterialShadePassCommandKind::SetBindGroup,
        bind_group_index=descriptor.material_bind_group_index,
        bind_group_kind="material",
        material_id=draw_call.material_id,
        material_bind_group=draw_call.material_bind_group,
      ),
    )
    commands.push(
      meshlet_material_shade_command(
        MeshletMaterialShadePassCommandKind::Draw,
        material_id=draw_call.material_id,
        vertex_start=draw_call.vertex_start,
        vertex_end=draw_call.vertex_end,
      ),
    )
  }
  commands
}

///|
pub fn meshlet_main_opaque_pass_draw_calls(
  materials : MeshletViewMaterialsMainOpaquePass,
  instance_manager : InstanceManager,
  has_material_depth? : Bool = true,
  has_material_shade_bind_group? : Bool = true,
) -> Array[MeshletMaterialDrawCall] {
  meshlet_material_bin_draw_calls(
    materials.entries,
    instance_manager,
    has_material_depth,
    has_material_shade_bind_group,
  )
}

///|
pub fn meshlet_prepass_draw_calls(
  materials : MeshletViewMaterialsPrepass,
  instance_manager : InstanceManager,
  has_material_depth? : Bool = true,
  has_material_shade_bind_group? : Bool = true,
) -> Array[MeshletMaterialDrawCall] {
  meshlet_material_bin_draw_calls(
    materials.entries,
    instance_manager,
    has_material_depth,
    has_material_shade_bind_group,
  )
}

///|
pub fn meshlet_deferred_gbuffer_prepass_draw_calls(
  materials : MeshletViewMaterialsDeferredGBufferPrepass,
  instance_manager : InstanceManager,
  has_material_depth? : Bool = true,
  has_material_shade_bind_group? : Bool = true,
) -> Array[MeshletMaterialDrawCall] {
  meshlet_material_bin_draw_calls(
    materials.entries,
    instance_manager,
    has_material_depth,
    has_material_shade_bind_group,
  )
}

///|
pub fn meshlet_main_opaque_pass_materials(
  materials : MeshletViewMaterialsMainOpaquePass,
  instance_manager : InstanceManager,
  has_material_depth? : Bool = true,
  has_material_shade_bind_group? : Bool = true,
) -> Int {
  meshlet_material_bin_draw_count(
    materials.entries,
    instance_manager,
    has_material_depth,
    has_material_shade_bind_group,
  )
}

///|
pub fn meshlet_prepass_materials(
  materials : MeshletViewMaterialsPrepass,
  instance_manager : InstanceManager,
  has_material_depth? : Bool = true,
  has_material_shade_bind_group? : Bool = true,
) -> Int {
  meshlet_material_bin_draw_count(
    materials.entries,
    instance_manager,
    has_material_depth,
    has_material_shade_bind_group,
  )
}

///|
pub fn meshlet_deferred_gbuffer_prepass_materials(
  materials : MeshletViewMaterialsDeferredGBufferPrepass,
  instance_manager : InstanceManager,
  has_material_depth? : Bool = true,
  has_material_shade_bind_group? : Bool = true,
) -> Int {
  meshlet_material_bin_draw_count(
    materials.entries,
    instance_manager,
    has_material_depth,
    has_material_shade_bind_group,
  )
}

///|
pub fn meshlet_prepass(draw_count : Int) -> Int {
  meshlet_clamp_draw_count(draw_count)
}

///|
pub fn meshlet_deferred_gbuffer_prepass(draw_count : Int) -> Int {
  meshlet_clamp_draw_count(draw_count)
}

///|
pub fn meshlet_main_opaque_pass(draw_count : Int) -> Int {
  meshlet_clamp_draw_count(draw_count)
}
