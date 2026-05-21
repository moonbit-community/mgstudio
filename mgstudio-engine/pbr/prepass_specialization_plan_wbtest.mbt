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
fn pbr_prepass_test_properties(
  alpha_mode? : @material.AlphaMode3d = @material.AlphaMode3d::Opaque,
  render_method? : OpaqueRendererMethod = OpaqueRendererMethod::Forward,
  render_phase_type? : @material.RenderPhaseType = @material.RenderPhaseType::Opaque,
  prepass_enabled? : Bool = true,
  reads_view_transmission_texture? : Bool = false,
) -> @material.MaterialProperties {
  let draw_functions = @material.DrawFunctions::new()
  let ids = pbr_material_register_draw_functions(draw_functions)
  pbr_material_apply_draw_functions(
    @material.MaterialProperties::default(),
    ids,
  )
  .with_alpha_mode(alpha_mode)
  .with_render_method(render_method)
  .with_render_phase_type(render_phase_type)
  .with_prepass_enabled(prepass_enabled)
  .with_reads_view_transmission_texture(reads_view_transmission_texture)
}

///|
test "pbr prepass specialization: removes materials Bevy excludes before queuing" {
  let disabled = pbr_prepass_material_specialization_decision(
    pbr_prepass_test_properties(prepass_enabled=false),
    0UL,
    MESH_PIPELINE_KEY_DEPTH_PREPASS,
  )
  debug_inspect(
    disabled is PbrPrepassMaterialSpecializationDecision::Remove,
    content="true",
  )
  let blended = pbr_prepass_material_specialization_decision(
    pbr_prepass_test_properties(alpha_mode=@material.AlphaMode3d::Blend),
    0UL,
    MESH_PIPELINE_KEY_DEPTH_PREPASS,
  )
  debug_inspect(
    blended is PbrPrepassMaterialSpecializationDecision::Remove,
    content="true",
  )
  let transmissive = pbr_prepass_material_specialization_decision(
    pbr_prepass_test_properties(reads_view_transmission_texture=true),
    0UL,
    MESH_PIPELINE_KEY_DEPTH_PREPASS,
  )
  debug_inspect(
    transmissive is PbrPrepassMaterialSpecializationDecision::Remove,
    content="true",
  )
}

///|
test "pbr prepass specialization: depth-only opaque uses empty material bind group" {
  let decision = pbr_prepass_material_specialization_decision(
    pbr_prepass_test_properties(),
    0UL,
    MESH_PIPELINE_KEY_DEPTH_PREPASS,
  )
  guard decision is PbrPrepassMaterialSpecializationDecision::Queue(plan) else {
    abort("expected queued depth-only prepass plan")
  }
  inspect(
    plan.draw_function_label(),
    content="PrepassOpaqueDepthOnlyDrawFunction",
  )
  inspect(plan.draw_function().id(), content="6")
  debug_inspect(plan.material_bind_group_required(), content="false")
  inspect(plan.mesh_key_bits(), content="8")
}

///|
test "pbr prepass specialization: deferred lightmap keeps bicubic bit and deferred draw" {
  let decision = pbr_prepass_material_specialization_decision(
    pbr_prepass_test_properties(render_method=OpaqueRendererMethod::Deferred),
    0UL,
    MESH_PIPELINE_KEY_DEPTH_PREPASS | MESH_PIPELINE_KEY_NORMAL_PREPASS,
    has_deferred_prepass=true,
    lightmapped=true,
    lightmap_bicubic_sampling=true,
  )
  guard decision is PbrPrepassMaterialSpecializationDecision::Queue(plan) else {
    abort("expected queued deferred prepass plan")
  }
  inspect(plan.draw_function_label(), content="DeferredOpaqueDrawFunction")
  inspect(
    plan.mesh_key_bits() & MESH_PIPELINE_KEY_DEFERRED_PREPASS,
    content="32",
  )
  inspect(plan.mesh_key_bits() & MESH_PIPELINE_KEY_LIGHTMAPPED, content="8192")
  inspect(
    plan.mesh_key_bits() & MESH_PIPELINE_KEY_LIGHTMAP_BICUBIC_SAMPLING,
    content="16384",
  )
  debug_inspect(plan.deferred(), content="true")
  debug_inspect(plan.material_bind_group_required(), content="true")
}

///|
test "pbr prepass specialization: alpha mask motion path keeps previous flags" {
  let decision = pbr_prepass_material_specialization_decision(
    pbr_prepass_test_properties(
      alpha_mode=@material.AlphaMode3d::Mask(0.5F),
      render_phase_type=@material.RenderPhaseType::AlphaMask,
    ),
    0UL,
    MESH_PIPELINE_KEY_DEPTH_PREPASS | MESH_PIPELINE_KEY_MOTION_VECTOR_PREPASS,
    visibility_range_dither=true,
    has_previous_skin=true,
    has_previous_morph=true,
  )
  guard decision is PbrPrepassMaterialSpecializationDecision::Queue(plan) else {
    abort("expected queued alpha-mask prepass plan")
  }
  inspect(plan.draw_function_label(), content="PrepassAlphaMaskDrawFunction")
  inspect(plan.mesh_key_bits() & MESH_PIPELINE_KEY_MAY_DISCARD, content="128")
  inspect(
    plan.mesh_key_bits() & MESH_PIPELINE_KEY_VISIBILITY_RANGE_DITHER,
    content="65536",
  )
  inspect(
    plan.mesh_key_bits() & MESH_PIPELINE_KEY_HAS_PREVIOUS_SKIN,
    content="262144",
  )
  inspect(
    plan.mesh_key_bits() & MESH_PIPELINE_KEY_HAS_PREVIOUS_MORPH,
    content="524288",
  )
}
