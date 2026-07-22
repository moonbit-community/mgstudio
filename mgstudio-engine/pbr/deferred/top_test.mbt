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
test "pbr deferred: depth id clamps to byte range" {
  let depth = PbrDeferredLightingDepthId::new(999)
  inspect(depth.get(), content="255")
  depth.set(-1)
  inspect(depth.get(), content="0")
}

///|
test "pbr deferred: plugin inserts default depth id for deferred prepass entity" {
  let lifecycle_world_23_0 = @ecs.World::new()
  defer lifecycle_world_23_0.close()
  let mut app = @app.App::new(lifecycle_world_23_0).add_plugins(
    @deferred.DeferredPbrLightingPlugin::DeferredPbrLightingPlugin(),
  )
  let world = app.world()
  let entity = world.spawn_empty()
  try! world.set_by_key(
    entity,
    @core_pipeline.ecs_key_deferred_prepass,
    DeferredPrepass(),
  )
  app = app.run_once()
  let depth = match
    (try! app.world().get_by_key(entity, ecs_key_pbr_deferred_lighting_depth_id)) {
    Some(v) => v
    None => abort("missing deferred depth id component")
  }
  inspect(depth.get(), content="1")
}

///|
test "pbr deferred: plugin keeps explicit depth id value" {
  let lifecycle_world_44_0 = @ecs.World::new()
  defer lifecycle_world_44_0.close()
  let mut app = @app.App::new(lifecycle_world_44_0).add_plugins(
    @deferred.DeferredPbrLightingPlugin::DeferredPbrLightingPlugin(),
  )
  let world = app.world()
  let entity = world.spawn_empty()
  try! world.set_by_key(
    entity,
    @core_pipeline.ecs_key_deferred_prepass,
    DeferredPrepass(),
  )
  try! world.set_by_key(
    entity,
    ecs_key_pbr_deferred_lighting_depth_id,
    PbrDeferredLightingDepthId::new(7),
  )
  app = app.run_once()
  let depth = match
    (try! app.world().get_by_key(entity, ecs_key_pbr_deferred_lighting_depth_id)) {
    Some(v) => v
    None => abort("missing deferred depth id component")
  }
  inspect(depth.get(), content="7")
}

///|
test "pbr deferred: deferred prepass run plan is exposed from core node owner" {
  let state = DeferredPrepassViewState::new(
    has_opaque_deferred_phase=true,
    has_alpha_mask_deferred_phase=true,
    has_normal_attachment=true,
    has_motion_vectors_attachment=true,
    has_deferred_attachment=true,
    has_deferred_lighting_pass_id_attachment=true,
    has_prepass_depth_attachment=true,
    occlusion_culling_enabled=true,
  )
  let early = deferred_prepass_run_plan(Early, state)
  inspect(
    deferred_prepass_run_kind_label(Early),
    content="early deferred prepass",
  )
  inspect(early.should_run, content="true")
  inspect(early.color_attachments.slot_count, content="4")
  inspect(
    early.color_attachments.deferred_attachment_loads_existing,
    content="false",
  )
  inspect(early.draw_opaque_phase, content="true")
  inspect(early.draw_alpha_mask_phase, content="true")
  inspect(early.copy_depth_to_prepass_depth, content="true")

  let late = deferred_prepass_run_plan(Late, state)
  inspect(late.should_run, content="true")
  inspect(late.is_late, content="true")
  inspect(
    late.color_attachments.deferred_attachment_loads_existing,
    content="true",
  )
}

///|
test "pbr deferred: prepare plan removes stale pipeline without deferred prepass" {
  let state = DeferredLightingViewState::new(
    deferred_prepass=false,
    skip_deferred_lighting=false,
  )
  let plan = deferred_lighting_prepare_plan(state)
  inspect(plan.should_prepare, content="false")
  inspect(plan.remove_existing_pipeline, content="true")
  inspect(plan.shader_defs.length(), content="0")

  let skipped = DeferredLightingViewState::new(
    deferred_prepass=true,
    skip_deferred_lighting=true,
  )
  let skipped_plan = deferred_lighting_prepare_plan(skipped)
  inspect(skipped_plan.should_prepare, content="false")
  inspect(skipped_plan.remove_existing_pipeline, content="true")
}

///|
test "pbr deferred: shader defs mirror deferred lighting specialization key" {
  let state = DeferredLightingViewState::new(
    hdr=false,
    tonemapping=Some(AgX),
    deband_dither=Some(Enabled),
    shadow_filter_method=Some(Temporal),
    screen_space_ambient_occlusion=true,
    screen_space_reflections=true,
    distance_fog=true,
    normal_prepass=true,
    depth_prepass=true,
    motion_vector_prepass=true,
    deferred_prepass=true,
    environment_map=true,
    irradiance_volume=true,
    atmosphere=true,
    binding_arrays_are_usable=true,
  )
  let plan = deferred_lighting_prepare_plan(state)
  inspect(plan.should_prepare, content="true")
  inspect(plan.remove_existing_pipeline, content="false")
  let defs = plan.shader_defs
  inspect(defs.length(), content="17")
  inspect(defs[0], content="DEFERRED_LIGHTING_PIPELINE")
  inspect(defs[1], content="TONEMAP_IN_SHADER")
  inspect(defs[2], content="TONEMAP_METHOD_AGX")
  inspect(defs[3], content="DEBAND_DITHER")
  inspect(defs[4], content="SCREEN_SPACE_AMBIENT_OCCLUSION")
  inspect(defs[5], content="ENVIRONMENT_MAP")
  inspect(defs[6], content="IRRADIANCE_VOLUME")
  inspect(defs[7], content="NORMAL_PREPASS")
  inspect(defs[8], content="DEPTH_PREPASS")
  inspect(defs[9], content="MOTION_VECTOR_PREPASS")
  inspect(defs[10], content="SCREEN_SPACE_REFLECTIONS")
  inspect(defs[11], content="DISTANCE_FOG")
  inspect(defs[12], content="ATMOSPHERE")
  inspect(defs[13], content="DEFERRED_PREPASS")
  inspect(defs[14], content="SHADOW_FILTER_METHOD_TEMPORAL")
  inspect(defs[15], content="MULTIPLE_LIGHT_PROBES_IN_ARRAY")
  inspect(defs[16], content="MULTIPLE_LIGHTMAPS_IN_ARRAY")
}

///|
test "pbr deferred: hdr lighting skips tonemap-in-shader defs" {
  let state = DeferredLightingViewState::new(
    hdr=true,
    tonemapping=Some(Reinhard),
    deband_dither=Some(Enabled),
    deferred_prepass=true,
  )
  let descriptor = deferred_lighting_pipeline_descriptor_plan(state)
  inspect(
    descriptor.color_target_format,
    content="ViewTarget::TEXTURE_FORMAT_HDR",
  )
  inspect(descriptor.shader_defs.length(), content="3")
  inspect(descriptor.shader_defs[0], content="DEFERRED_LIGHTING_PIPELINE")
  inspect(descriptor.shader_defs[1], content="DEFERRED_PREPASS")
  inspect(descriptor.shader_defs[2], content="SHADOW_FILTER_METHOD_GAUSSIAN")
}

///|
test "pbr deferred: pipeline descriptor and pass plan mirror fullscreen lighting pass" {
  let state = DeferredLightingViewState::new(deferred_prepass=true)
  let descriptor = deferred_lighting_pipeline_descriptor_plan(state)
  inspect(descriptor.label, content="deferred_lighting_pipeline")
  inspect(descriptor.layout_count, content="3")
  inspect(descriptor.main_view_layout, content="true")
  inspect(descriptor.binding_array_layout, content="true")
  inspect(descriptor.depth_id_layout, content="true")
  inspect(
    descriptor.vertex_shader_path,
    content="pbr/deferred/deferred_lighting.wgsl",
  )
  inspect(
    descriptor.fragment_shader_path,
    content="pbr/deferred/deferred_lighting.wgsl",
  )
  inspect(descriptor.color_target_count, content="1")
  inspect(descriptor.color_target_format, content="TextureFormat::bevy_default")
  inspect(descriptor.color_write_mask_all, content="true")
  inspect(descriptor.depth_format, content="Depth16Unorm")
  inspect(descriptor.depth_write_enabled, content="false")
  inspect(descriptor.depth_compare, content="Equal")
  inspect(descriptor.stencil_ignored, content="true")

  let blocked = deferred_lighting_pass_plan(
    has_pipeline=true,
    has_depth_id_binding=false,
    has_mesh_view_bind_group=true,
    has_view_target=true,
    has_deferred_lighting_id_depth_texture=true,
  )
  inspect(blocked.should_run, content="false")
  inspect(blocked.bind_group_count, content="0")

  let pass = deferred_lighting_pass_plan(
    has_pipeline=true,
    has_depth_id_binding=true,
    has_mesh_view_bind_group=true,
    has_view_target=true,
    has_deferred_lighting_id_depth_texture=true,
  )
  inspect(pass.label, content="deferred_lighting")
  inspect(pass.should_run, content="true")
  inspect(pass.color_attachment_count, content="1")
  inspect(pass.depth_format, content="Depth16Unorm")
  inspect(pass.depth_load, content="Load")
  inspect(pass.depth_store, content="Discard")
  inspect(pass.bind_group_count, content="3")
  inspect(pass.dynamic_offset_count, content="7")
  inspect(pass.bind_group_2_label, content="deferred_lighting_layout_group_2")
  inspect(pass.draw_vertex_start, content="0")
  inspect(pass.draw_vertex_end, content="3")
  inspect(pass.draw_instance_start, content="0")
  inspect(pass.draw_instance_end, content="1")
}
