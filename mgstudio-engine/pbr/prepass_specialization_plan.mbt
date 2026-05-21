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
// Bevy source: `bevy/crates/bevy_pbr/src/prepass/mod.rs`,
// `specialize_prepass_material_meshes` and `queue_prepass_material_meshes`.

///|
pub struct PbrPrepassMaterialSpecializationPlan {
  mesh_key_bits : UInt64
  draw_function_label : @material.DrawFunctionLabel
  draw_function : @material.DrawFunctionId
  deferred : Bool
  material_bind_group_required : Bool
}

///|
pub enum PbrPrepassMaterialSpecializationDecision {
  Queue(PbrPrepassMaterialSpecializationPlan)
  Remove
  Skip
}

///|
pub fn PbrPrepassMaterialSpecializationPlan::mesh_key_bits(
  self : PbrPrepassMaterialSpecializationPlan,
) -> UInt64 {
  self.mesh_key_bits
}

///|
pub fn PbrPrepassMaterialSpecializationPlan::draw_function_label(
  self : PbrPrepassMaterialSpecializationPlan,
) -> @material.DrawFunctionLabel {
  self.draw_function_label
}

///|
pub fn PbrPrepassMaterialSpecializationPlan::draw_function(
  self : PbrPrepassMaterialSpecializationPlan,
) -> @material.DrawFunctionId {
  self.draw_function
}

///|
pub fn PbrPrepassMaterialSpecializationPlan::deferred(
  self : PbrPrepassMaterialSpecializationPlan,
) -> Bool {
  self.deferred
}

///|
pub fn PbrPrepassMaterialSpecializationPlan::material_bind_group_required(
  self : PbrPrepassMaterialSpecializationPlan,
) -> Bool {
  self.material_bind_group_required
}

///|
fn pbr_prepass_alpha_mode_allowed(alpha_mode : @material.AlphaMode3d) -> Bool {
  match alpha_mode {
    @material.AlphaMode3d::Opaque
    | @material.AlphaMode3d::AlphaToCoverage
    | @material.AlphaMode3d::Mask(_) => true
    @material.AlphaMode3d::Blend
    | @material.AlphaMode3d::Premultiplied
    | @material.AlphaMode3d::Add
    | @material.AlphaMode3d::Multiply => false
  }
}

///|
fn pbr_prepass_draw_function_label(
  properties : @material.MaterialProperties,
  mesh_key_bits : UInt64,
  deferred : Bool,
  emulate_unclipped_depth : Bool,
) -> @material.DrawFunctionLabel? {
  match properties.render_phase_type {
    @material.RenderPhaseType::Opaque =>
      if deferred {
        Some(DEFERRED_OPAQUE_DRAW_FUNCTION_LABEL)
      } else if pbr_prepass_is_depth_only_opaque(mesh_key_bits) &&
        !emulate_unclipped_depth {
        Some(PREPASS_OPAQUE_DEPTH_ONLY_DRAW_FUNCTION_LABEL)
      } else {
        Some(PREPASS_OPAQUE_DRAW_FUNCTION_LABEL)
      }
    @material.RenderPhaseType::AlphaMask =>
      if deferred {
        Some(DEFERRED_ALPHA_MASK_DRAW_FUNCTION_LABEL)
      } else {
        Some(PREPASS_ALPHA_MASK_DRAW_FUNCTION_LABEL)
      }
    @material.RenderPhaseType::Transmissive
    | @material.RenderPhaseType::Transparent => None
  }
}

///|
pub fn pbr_prepass_material_specialization_decision(
  properties : @material.MaterialProperties,
  base_mesh_key_bits : UInt64,
  view_key_bits : UInt64,
  has_deferred_prepass? : Bool = false,
  lightmapped? : Bool = false,
  lightmap_bicubic_sampling? : Bool = false,
  visibility_range_dither? : Bool = false,
  has_previous_skin? : Bool = false,
  has_previous_morph? : Bool = false,
  emulate_unclipped_depth? : Bool = false,
) -> PbrPrepassMaterialSpecializationDecision {
  if !properties.prepass_enabled {
    return PbrPrepassMaterialSpecializationDecision::Remove
  }
  if !pbr_prepass_alpha_mode_allowed(properties.alpha_mode) ||
    properties.reads_view_transmission_texture {
    return PbrPrepassMaterialSpecializationDecision::Remove
  }
  let forward = properties.render_method is OpaqueRendererMethod::Forward
  let deferred = has_deferred_prepass && !forward
  let mut mesh_key_bits = view_key_bits |
    base_mesh_key_bits |
    properties.mesh_pipeline_key_bits.bits() |
    alpha_mode_pipeline_key(properties.alpha_mode)
  if deferred {
    mesh_key_bits = mesh_key_bits | MESH_PIPELINE_KEY_DEFERRED_PREPASS
  }
  if lightmapped {
    mesh_key_bits = mesh_key_bits | MESH_PIPELINE_KEY_LIGHTMAPPED
    if lightmap_bicubic_sampling && deferred {
      mesh_key_bits = mesh_key_bits |
        MESH_PIPELINE_KEY_LIGHTMAP_BICUBIC_SAMPLING
    }
  }
  if visibility_range_dither {
    mesh_key_bits = mesh_key_bits | MESH_PIPELINE_KEY_VISIBILITY_RANGE_DITHER
  }
  if (view_key_bits & MESH_PIPELINE_KEY_MOTION_VECTOR_PREPASS) != 0UL {
    if has_previous_skin {
      mesh_key_bits = mesh_key_bits | MESH_PIPELINE_KEY_HAS_PREVIOUS_SKIN
    }
    if has_previous_morph {
      mesh_key_bits = mesh_key_bits | MESH_PIPELINE_KEY_HAS_PREVIOUS_MORPH
    }
  }
  guard pbr_prepass_draw_function_label(
      properties, mesh_key_bits, deferred, emulate_unclipped_depth,
    )
    is Some(draw_function_label) else {
    return PbrPrepassMaterialSpecializationDecision::Skip
  }
  guard properties.get_draw_function(draw_function_label) is Some(draw_function) else {
    return PbrPrepassMaterialSpecializationDecision::Skip
  }
  let material_bind_group_required = draw_function_label !=
    PREPASS_OPAQUE_DEPTH_ONLY_DRAW_FUNCTION_LABEL
  PbrPrepassMaterialSpecializationDecision::Queue(PbrPrepassMaterialSpecializationPlan::{
    mesh_key_bits,
    draw_function_label,
    draw_function,
    deferred,
    material_bind_group_required,
  })
}
