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
test "core prepass node: color attachment plan preserves Bevy slots" {
  let empty = prepass_color_attachment_plan(PrepassViewState::default())
  inspect(empty.slot_count, content="0")
  let with_normal_and_motion = prepass_color_attachment_plan(
    PrepassViewState::new(
      has_normal_attachment=true,
      has_motion_vectors_attachment=true,
    ),
  )
  inspect(with_normal_and_motion.normal, content="true")
  inspect(with_normal_and_motion.motion_vectors, content="true")
  inspect(with_normal_and_motion.deferred, content="false")
  inspect(with_normal_and_motion.slot_count, content="4")
}

///|
test "core prepass node: early run plan mirrors render pass gating" {
  let state = PrepassViewState::new(
    has_opaque_prepass_phase=true,
    has_alpha_mask_prepass_phase=true,
    has_prepass_depth_attachment=true,
  )
  let plan = prepass_run_plan(PrepassRunKind::Early, state)
  inspect(plan.label, content="early prepass")
  inspect(plan.should_run, content="true")
  inspect(plan.has_depth_stencil_attachment, content="true")
  inspect(plan.draw_opaque_phase, content="true")
  inspect(plan.draw_alpha_mask_phase, content="true")
  inspect(plan.copy_depth_to_prepass_depth, content="true")
}

///|
test "core prepass node: late run plan requires occlusion and indirect drawing" {
  let early_state = PrepassViewState::new(
    has_opaque_prepass_phase=true,
    occlusion_culling_enabled=false,
  )
  inspect(
    prepass_run_plan(PrepassRunKind::Late, early_state).should_run,
    content="false",
  )
  let late_state = PrepassViewState::new(
    has_opaque_prepass_phase=true,
    occlusion_culling_enabled=true,
    no_indirect_drawing=false,
  )
  inspect(
    prepass_run_plan(PrepassRunKind::Late, late_state).should_run,
    content="true",
  )
  let no_indirect = PrepassViewState::new(
    has_opaque_prepass_phase=true,
    occlusion_culling_enabled=true,
    no_indirect_drawing=true,
  )
  inspect(
    prepass_run_plan(PrepassRunKind::Late, no_indirect).should_run,
    content="false",
  )
}

///|
test "core prepass node: deferred prepass suppresses normal prepass and depth copy" {
  let state = PrepassViewState::new(
    has_deferred_prepass_component=true,
    has_opaque_prepass_phase=true,
    has_prepass_depth_attachment=true,
    has_normal_attachment=true,
  )
  let plan = prepass_run_plan(PrepassRunKind::Early, state)
  inspect(plan.should_run, content="false")
  inspect(plan.skip_due_to_deferred, content="true")
  inspect(plan.color_attachments.slot_count, content="4")
  inspect(plan.has_depth_stencil_attachment, content="false")
  inspect(plan.copy_depth_to_prepass_depth, content="false")
}

///|
test "core prepass node: skybox draw needs pipeline bind group previous view and cache hit" {
  let state = PrepassViewState::new(has_opaque_prepass_phase=true)
  let missing_cache = prepass_run_plan(
    PrepassRunKind::Early,
    state,
    has_skybox_prepass_pipeline=true,
    has_skybox_prepass_bind_group=true,
    has_previous_view_uniform_offset=true,
    skybox_pipeline_ready=false,
  )
  inspect(missing_cache.draw_skybox, content="false")
  let ready = prepass_run_plan(
    PrepassRunKind::Early,
    state,
    has_skybox_prepass_pipeline=true,
    has_skybox_prepass_bind_group=true,
    has_previous_view_uniform_offset=true,
    skybox_pipeline_ready=true,
  )
  inspect(ready.draw_skybox, content="true")
  inspect(ready.skybox_dynamic_offset_count, content="2")
}
