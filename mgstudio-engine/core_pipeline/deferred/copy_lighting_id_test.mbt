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
test "core deferred copy lighting id: pipeline plan mirrors Bevy descriptor" {
  let plan = copy_deferred_lighting_id_pipeline_plan()
  inspect(
    plan.bind_group_layout_label,
    content="copy_deferred_lighting_id_bind_group_layout",
  )
  inspect(plan.bind_group_layout_count, content="1")
  inspect(plan.texture_sample_type_uint, content="true")
  inspect(plan.uses_fullscreen_vertex_shader, content="true")
  inspect(
    plan.fragment_shader_path,
    content="core_pipeline/deferred/copy_deferred_lighting_id.wgsl",
  )
  inspect(
    plan.render_pipeline_label,
    content="copy_deferred_lighting_id_pipeline",
  )
  inspect(plan.depth_format, content="Depth16Unorm")
  inspect(plan.depth_write_enabled, content="true")
  inspect(plan.depth_compare_always, content="true")
}

///|
test "core deferred copy lighting id: pass needs pipeline source and depth target" {
  let missing_depth = CopyDeferredLightingIdState::new(
    has_copy_pipeline=true,
    has_deferred_lighting_pass_id_texture=true,
  )
  inspect(copy_deferred_lighting_id_should_run(missing_depth), content="false")
  inspect(
    copy_deferred_lighting_id_pass_plan(missing_depth).has_depth_stencil_attachment,
    content="false",
  )

  let ready = CopyDeferredLightingIdState::new(
    has_copy_pipeline=true,
    has_deferred_lighting_pass_id_texture=true,
    has_deferred_lighting_id_depth_texture=true,
  )
  let plan = copy_deferred_lighting_id_pass_plan(ready)
  inspect(plan.label, content="copy_deferred_lighting_id")
  inspect(plan.should_run, content="true")
  inspect(plan.bind_group_label, content="copy_deferred_lighting_id_bind_group")
  inspect(plan.color_attachment_count, content="0")
  inspect(plan.has_depth_stencil_attachment, content="true")
  inspect(plan.depth_format, content="Depth16Unorm")
  inspect(plan.depth_load_clear_value, content="0")
  inspect(plan.depth_store, content="true")
  inspect(plan.draw_vertex_start, content="0")
  inspect(plan.draw_vertex_end, content="3")
  inspect(plan.draw_instance_start, content="0")
  inspect(plan.draw_instance_end, content="1")
}

///|
test "core deferred copy lighting id: depth texture descriptor mirrors Bevy cache request" {
  let plan = deferred_lighting_id_depth_texture_descriptor_plan(1280, 720)
  inspect(plan.label, content="deferred_lighting_id_depth_texture_a")
  inspect(plan.should_prepare, content="true")
  inspect(plan.width, content="1280")
  inspect(plan.height, content="720")
  inspect(plan.mip_level_count, content="1")
  inspect(plan.sample_count, content="1")
  inspect(plan.dimension, content="D2")
  inspect(plan.format, content="Depth16Unorm")
  inspect(plan.usage_render_attachment, content="true")
  inspect(plan.usage_copy_src, content="true")
  inspect(plan.view_format_count, content="0")

  let missing_size = deferred_lighting_id_depth_texture_descriptor_plan(0, 720)
  inspect(missing_size.should_prepare, content="false")
}
