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
test "core deferred node: early run plan mirrors deferred prepass attachments" {
  let state = DeferredPrepassViewState::new(
    has_opaque_deferred_phase=true,
    has_normal_attachment=true,
    has_motion_vectors_attachment=true,
    has_deferred_attachment=true,
    has_deferred_lighting_pass_id_attachment=true,
    has_prepass_depth_attachment=true,
  )
  let plan = deferred_prepass_run_plan(DeferredPrepassRunKind::Early, state)
  inspect(plan.label, content="early deferred prepass")
  inspect(plan.should_run, content="true")
  inspect(plan.is_late, content="false")
  inspect(plan.color_attachments.slot_count, content="4")
  inspect(plan.color_attachments.normal, content="true")
  inspect(plan.color_attachments.motion_vectors, content="true")
  inspect(plan.color_attachments.deferred, content="true")
  inspect(plan.color_attachments.deferred_lighting_pass_id, content="true")
  inspect(
    plan.color_attachments.deferred_attachment_loads_existing,
    content="false",
  )
  inspect(plan.draw_opaque_phase, content="true")
  inspect(plan.draw_alpha_mask_phase, content="false")
  inspect(plan.copy_depth_to_prepass_depth, content="true")
}

///|
test "core deferred node: late run plan requires occlusion and indirect drawing" {
  let missing_occlusion = DeferredPrepassViewState::new(
    has_opaque_deferred_phase=true,
    occlusion_culling_enabled=false,
  )
  inspect(
    deferred_prepass_run_plan(DeferredPrepassRunKind::Late, missing_occlusion).should_run,
    content="false",
  )
  let no_indirect = DeferredPrepassViewState::new(
    has_opaque_deferred_phase=true,
    occlusion_culling_enabled=true,
    no_indirect_drawing=true,
  )
  inspect(
    deferred_prepass_run_plan(DeferredPrepassRunKind::Late, no_indirect).should_run,
    content="false",
  )
  let late = DeferredPrepassViewState::new(
    has_alpha_mask_deferred_phase=true,
    has_deferred_attachment=true,
    occlusion_culling_enabled=true,
    no_indirect_drawing=false,
  )
  let plan = deferred_prepass_run_plan(DeferredPrepassRunKind::Late, late)
  inspect(plan.label, content="late deferred prepass")
  inspect(plan.should_run, content="true")
  inspect(plan.is_late, content="true")
  inspect(plan.draw_alpha_mask_phase, content="true")
  inspect(
    plan.color_attachments.deferred_attachment_loads_existing,
    content="true",
  )
}

///|
test "core deferred node: webgl early deferred clear is explicit" {
  let state = DeferredPrepassViewState::new(
    has_opaque_deferred_phase=true,
    has_deferred_attachment=true,
  )
  let native = deferred_prepass_color_attachment_plan(
    DeferredPrepassRunKind::Early,
    state,
  )
  inspect(native.webgl_manual_deferred_clear, content="false")
  let webgl = deferred_prepass_color_attachment_plan(
    DeferredPrepassRunKind::Early,
    state,
    webgl_manual_clear_supported=true,
  )
  inspect(webgl.webgl_manual_deferred_clear, content="true")
  inspect(webgl.deferred_attachment_loads_existing, content="false")
}

///|
test "core deferred node: empty color attachments remove fragment requirement" {
  let state = DeferredPrepassViewState::new(has_opaque_deferred_phase=true)
  let plan = deferred_prepass_run_plan(DeferredPrepassRunKind::Early, state)
  inspect(plan.should_run, content="true")
  inspect(plan.color_attachments.slot_count, content="0")
  inspect(plan.has_depth_stencil_attachment, content="true")
}
