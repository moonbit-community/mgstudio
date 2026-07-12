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
fn GpuFrameState::release(self : GpuFrameState) -> Unit {
  if self.pass is Some(pass) {
    pass.release()
  }
  for bind_group in self.transient_bind_groups {
    bind_group.release()
  }
  for buffer in self.transient_buffers {
    buffer.release()
  }
  for view in self.transient_texture_views {
    view.release()
  }
  self.encoder.release()
  if self.present_view is Some(view) {
    view.release()
  }
  self.surface_view.release()
  if self.screenshot_capture_texture is Some(texture) {
    texture.release()
  }
  self.surface_texture.release()
  self.surface_tex.release()
}

///|
fn GpuSurfaceState::release(self : GpuSurfaceState) -> Unit {
  if self.frame is Some(frame) {
    frame.release()
  }
  self.surface.release()
}

///|
fn Mesh2dMaterialBindGroupCacheEntry::release(
  self : Mesh2dMaterialBindGroupCacheEntry,
) -> Unit {
  self.bind_group.release()
  for buffer in self.uniform_buffers {
    buffer.release()
  }
}

///|
fn GpuQueuedLineGizmoDraw::release(self : GpuQueuedLineGizmoDraw) -> Unit {
  self.list_position_buffer.release()
  self.list_color_buffer.release()
  self.strip_position_buffer.release()
  self.strip_color_buffer.release()
}

///|
fn GpuBackend::release_frame_surface_2d_owners(self : GpuBackend) -> Unit {
  for surface in self.surfaces {
    surface.release()
  }
  self.frame = None
  self.pass_state = None
  if self.depth_view is Some(view) {
    view.release()
  }
  if self.depth_texture is Some(texture) {
    texture.release()
  }
  if self.surface_msaa_view is Some(view) {
    view.release()
  }
  if self.surface_msaa_texture is Some(texture) {
    texture.release()
  }
  if self.sprite_globals_bg is Some(bind_group) {
    bind_group.release()
  }
  if self.sprite_view_bg is Some(bind_group) {
    bind_group.release()
  }
  if self.sprite_pipeline is Some(pipeline) {
    pipeline.release()
  }
  if self.sprite_pipeline_surface is Some(pipeline) {
    pipeline.release()
  }
  if self.sprite_pipeline_depth is Some(pipeline) {
    pipeline.release()
  }
  if self.sprite_pipeline_depth_surface is Some(pipeline) {
    pipeline.release()
  }
  if self.sprite_render_pipeline_layout is Some(layout) {
    layout.release()
  }
  if self.sprite_pipeline_layout is Some(layout) {
    layout.release()
  }
  if self.sprite_texture_bgl is Some(layout) {
    layout.release()
  }
  if self.sprite_view_bgl is Some(layout) {
    layout.release()
  }
  if self.sprite_bgl_globals is Some(layout) {
    layout.release()
  }
  if self.sprite_bgl_tex is Some(layout) {
    layout.release()
  }
  if self.sprite_globals_buf is Some(buffer) {
    buffer.release()
  }
  if self.sprite_instance_buf is Some(buffer) {
    buffer.release()
  }
  if self.sprite_index_buf is Some(buffer) {
    buffer.release()
  }
  if self.sprite_view_buf is Some(buffer) {
    buffer.release()
  }
  if self.sprite_lut_view is Some(view) {
    view.release()
  }
  if self.sprite_lut_texture is Some(texture) {
    texture.release()
  }
  if self.sprite_lut_sampler is Some(sampler) {
    sampler.release()
  }

  if self.ui_view_bg is Some(bind_group) {
    bind_group.release()
  }
  if self.ui_shadow_view_bg is Some(bind_group) {
    bind_group.release()
  }
  if self.ui_slice_view_bg is Some(bind_group) {
    bind_group.release()
  }
  if self.ui_pipeline is Some(pipeline) {
    pipeline.release()
  }
  if self.ui_pipeline_anti_alias is Some(pipeline) {
    pipeline.release()
  }
  if self.ui_pipeline_surface is Some(pipeline) {
    pipeline.release()
  }
  if self.ui_pipeline_surface_anti_alias is Some(pipeline) {
    pipeline.release()
  }
  for entry in self.ui_shadow_pipeline_cache {
    entry.pipeline.release()
  }
  if self.ui_slice_pipeline is Some(pipeline) {
    pipeline.release()
  }
  if self.ui_slice_pipeline_surface is Some(pipeline) {
    pipeline.release()
  }
  if self.ui_pipeline_layout is Some(layout) {
    layout.release()
  }
  if self.ui_shadow_pipeline_layout is Some(layout) {
    layout.release()
  }
  if self.ui_slice_pipeline_layout is Some(layout) {
    layout.release()
  }
  if self.ui_view_bgl is Some(layout) {
    layout.release()
  }
  if self.ui_shadow_view_bgl is Some(layout) {
    layout.release()
  }
  if self.ui_slice_view_bgl is Some(layout) {
    layout.release()
  }
  if self.ui_view_buf is Some(buffer) {
    buffer.release()
  }
  if self.ui_vertex_buf is Some(buffer) {
    buffer.release()
  }
  if self.ui_shadow_view_buf is Some(buffer) {
    buffer.release()
  }
  if self.ui_shadow_vertex_buf is Some(buffer) {
    buffer.release()
  }
  if self.ui_slice_view_buf is Some(buffer) {
    buffer.release()
  }
  if self.ui_slice_globals_buf is Some(buffer) {
    buffer.release()
  }
  if self.ui_slice_vertex_buf is Some(buffer) {
    buffer.release()
  }

  if self.mesh2d_instance_bg is Some(bind_group) {
    bind_group.release()
  }
  if self.mesh2d_view_bg is Some(bind_group) {
    bind_group.release()
  }
  for entry in self.mesh2d_material_bg_cache {
    entry.release()
  }
  if self.mesh_pipeline is Some(pipeline) {
    pipeline.release()
  }
  if self.mesh_pipeline_surface is Some(pipeline) {
    pipeline.release()
  }
  for entry in self.mesh2d_pipeline_cache {
    entry.pipeline.release()
  }
  for entry in self.line_gizmo_pipeline_cache {
    entry.pipeline.release()
    entry.uniform_bind_group_layout.release()
    entry.view_bind_group_layout.release()
  }
  if self.mesh2d_pipeline_layout_without_material is Some(layout) {
    layout.release()
  }
  for entry in self.mesh2d_material_layout_cache {
    entry.pipeline_layout.release()
    entry.bind_group_layout.release()
  }
  if self.mesh_pipeline_layout is Some(layout) {
    layout.release()
  }
  if self.mesh2d_view_bgl is Some(layout) {
    layout.release()
  }
  if self.mesh2d_mesh_bgl is Some(layout) {
    layout.release()
  }
  if self.mesh2d_material_bgl is Some(layout) {
    layout.release()
  }
  if self.mesh2d_view_buf is Some(buffer) {
    buffer.release()
  }
  if self.mesh2d_globals_buf is Some(buffer) {
    buffer.release()
  }
  if self.mesh2d_instance_buf is Some(buffer) {
    buffer.release()
  }
  if self.mesh2d_lut_view is Some(view) {
    view.release()
  }
  if self.mesh2d_lut_texture is Some(texture) {
    texture.release()
  }
  if self.mesh2d_lut_sampler is Some(sampler) {
    sampler.release()
  }
  for draw in self.line_gizmo_queued_draws {
    draw.release()
  }
}

///|
fn Mesh3dMaterialPipelineLayoutCacheEntry::release(
  self : Mesh3dMaterialPipelineLayoutCacheEntry,
) -> Unit {
  self.pipeline_layout.release()
  self.material_bind_group_layout.release()
  self.draw_bind_group_layout.release()
  self.binding_arrays_bind_group_layout.release()
  self.view_bind_group_layout.release()
}

///|
fn GpuStorageSlot::release(self : GpuStorageSlot) -> Unit {
  self.bind_group.release()
  self.buffer.release()
}

///|
fn GpuBackend::release_mesh3d_pbr_owners(self : GpuBackend) -> Unit {
  mesh3d_pass_uniform_states_clear(self)
  mesh3d_material_cache_clear(self)
  mesh3d_pipeline_cache_clear(self)
  mesh3d_custom_pipeline_cache_clear(self)
  mesh3d_volumetric_fog_pipeline_cache_clear(self)

  if self.mesh3d_binding_arrays_bg is Some(bind_group) {
    bind_group.release()
  }
  if self.mesh3d_shadow_view_bg is Some(bind_group) {
    bind_group.release()
  }
  if self.mesh3d_shadow_empty_bg is Some(bind_group) {
    bind_group.release()
  }
  for slot in self.mesh3d_draw_slots {
    slot.release()
  }
  if self.mesh3d_skin_current_bg is Some(bind_group) {
    bind_group.release()
  }
  if self.mesh3d_skin_prev_bg is Some(bind_group) {
    bind_group.release()
  }
  if self.mesh3d_instance_draw_bg is Some(bind_group) {
    bind_group.release()
  }
  for entry in self.wireframe_3d_wide_bind_groups {
    entry.bind_group.release()
  }

  for entry in self.mesh3d_material_render_pipelines {
    entry.pipeline.release()
  }
  for entry in self.mesh3d_shadow_pipeline_cache {
    entry.pipeline.release()
  }
  for entry in self.mesh3d_material_pipeline_layout_cache {
    entry.release()
  }
  if self.mesh3d_shadow_pipeline_layout_material is Some(layout) {
    layout.release()
  }
  if self.mesh3d_shadow_pipeline_layout_depth_only is Some(layout) {
    layout.release()
  }
  if self.mesh3d_pipeline_layout is Some(layout) {
    layout.release()
  }
  if self.mesh3d_shadow_bgl_empty is Some(layout) {
    layout.release()
  }
  if self.mesh3d_shadow_bgl_view is Some(layout) {
    layout.release()
  }
  if self.mesh3d_bgl_skin is Some(layout) {
    layout.release()
  }
  if self.mesh3d_bgl_material is Some(layout) {
    layout.release()
  }
  if self.mesh3d_bgl_draw is Some(layout) {
    layout.release()
  }
  if self.mesh3d_bgl_binding_arrays is Some(layout) {
    layout.release()
  }
  if self.mesh3d_bgl_view is Some(layout) {
    layout.release()
  }
  for layout in self.mesh3d_volumetric_fog_bgls {
    layout.release()
  }
  if self.wireframe_3d_wide_bgl is Some(layout) {
    layout.release()
  }

  if self.mesh3d_point_shadow_compare_sampler is Some(sampler) {
    sampler.release()
  }
  if self.mesh3d_directional_shadow_compare_sampler is Some(sampler) {
    sampler.release()
  }

  if self.mesh3d_view_buf is Some(buffer) {
    buffer.release()
  }
  if self.mesh3d_lights_buf is Some(buffer) {
    buffer.release()
  }
  if self.mesh3d_clustered_lights_buf is Some(buffer) {
    buffer.release()
  }
  if self.mesh3d_clusterable_object_index_lists_buf is Some(buffer) {
    buffer.release()
  }
  if self.mesh3d_cluster_offsets_and_counts_buf is Some(buffer) {
    buffer.release()
  }
  if self.mesh3d_clustered_decals_buf is Some(buffer) {
    buffer.release()
  }
  if self.mesh3d_globals_buf is Some(buffer) {
    buffer.release()
  }
  if self.mesh3d_fog_buf is Some(buffer) {
    buffer.release()
  }
  if self.mesh3d_volumetric_fog_buf is Some(buffer) {
    buffer.release()
  }
  if self.mesh3d_light_probes_buf is Some(buffer) {
    buffer.release()
  }
  if self.mesh3d_visibility_ranges_buf is Some(buffer) {
    buffer.release()
  }
  if self.wireframe_3d_wide_params_buf is Some(buffer) {
    buffer.release()
  }
  if self.mesh3d_ssr_settings_buf is Some(buffer) {
    buffer.release()
  }
  if self.mesh3d_contact_shadows_settings_buf is Some(buffer) {
    buffer.release()
  }
  if self.mesh3d_skin_current_buf is Some(buffer) {
    buffer.release()
  }
  if self.mesh3d_skin_prev_buf is Some(buffer) {
    buffer.release()
  }
  if self.mesh3d_morph_current_buf is Some(buffer) {
    buffer.release()
  }
  if self.mesh3d_morph_prev_buf is Some(buffer) {
    buffer.release()
  }
  if self.mesh3d_morph_descriptor_buf is Some(buffer) {
    buffer.release()
  }
  for entry in self.mesh3d_morph_target_buffers {
    entry.buffer.release()
  }
  for entry in self.mesh3d_instance_vertex_buffers {
    entry.buffer.release()
  }
  if self.mesh3d_instance_draw_buf is Some(buffer) {
    buffer.release()
  }
}

///|
fn GpuBackend::release_preprocess_meshlet_motion_owners(
  self : GpuBackend,
) -> Unit {
  self.release_preprocess_owners()
  self.release_meshlet_owners()
  self.release_motion_vector_owners()
}

///|
fn GpuBackend::release_preprocess_owners(self : GpuBackend) -> Unit {
  for state in self.mesh3d_preprocess_camera_upload_states {
    state.release()
  }
  let pipelines = [
    self.mesh3d_preprocess_reset_batch_sets_pipeline,
    self.mesh3d_preprocess_direct_pipeline,
    self.mesh3d_preprocess_indirect_pipeline,
    self.mesh3d_preprocess_indirect_early_occlusion_pipeline,
    self.mesh3d_preprocess_indirect_late_occlusion_pipeline,
    self.mesh3d_preprocess_build_indexed_indirect_pipeline,
    self.mesh3d_preprocess_build_indexed_indirect_early_pipeline,
    self.mesh3d_preprocess_build_indexed_indirect_late_pipeline,
    self.mesh3d_preprocess_build_indexed_indirect_main_pipeline,
    self.mesh3d_preprocess_build_non_indexed_indirect_pipeline,
    self.mesh3d_preprocess_build_non_indexed_indirect_early_pipeline,
    self.mesh3d_preprocess_build_non_indexed_indirect_late_pipeline,
    self.mesh3d_preprocess_build_non_indexed_indirect_main_pipeline,
    self.mesh3d_preprocess_downsample_depth_first_pipeline,
    self.mesh3d_preprocess_downsample_depth_second_pipeline,
    self.mesh3d_preprocess_downsample_depth_first_multisample_pipeline,
    self.mesh3d_preprocess_downsample_depth_second_multisample_pipeline,
  ]
  for pipeline in pipelines {
    if pipeline is Some(value) {
      value.release()
    }
  }
  let pipeline_layouts = [
    self.mesh3d_preprocess_reset_batch_sets_pipeline_layout,
    self.mesh3d_preprocess_direct_pipeline_layout,
    self.mesh3d_preprocess_indirect_pipeline_layout,
    self.mesh3d_preprocess_indirect_early_occlusion_pipeline_layout,
    self.mesh3d_preprocess_indirect_late_occlusion_pipeline_layout,
    self.mesh3d_preprocess_build_indexed_indirect_pipeline_layout,
    self.mesh3d_preprocess_build_non_indexed_indirect_pipeline_layout,
    self.mesh3d_preprocess_downsample_depth_pipeline_layout,
    self.mesh3d_preprocess_downsample_depth_multisample_pipeline_layout,
  ]
  for layout in pipeline_layouts {
    if layout is Some(value) {
      value.release()
    }
  }
  let bind_group_layouts = [
    self.mesh3d_preprocess_reset_batch_sets_bgl,
    self.mesh3d_preprocess_direct_bgl,
    self.mesh3d_preprocess_indirect_bgl,
    self.mesh3d_preprocess_indirect_early_occlusion_bgl,
    self.mesh3d_preprocess_indirect_late_occlusion_bgl,
    self.mesh3d_preprocess_build_indexed_indirect_bgl,
    self.mesh3d_preprocess_build_non_indexed_indirect_bgl,
    self.mesh3d_preprocess_downsample_depth_bgl,
    self.mesh3d_preprocess_downsample_depth_multisample_bgl,
  ]
  for layout in bind_group_layouts {
    if layout is Some(value) {
      value.release()
    }
  }
  if self.mesh3d_preprocess_depth_pyramid_dummy_view is Some(view) {
    view.release()
  }
  if self.mesh3d_preprocess_depth_pyramid_dummy_texture is Some(texture) {
    texture.release()
  }
  if self.mesh3d_preprocess_depth_pyramid_sampler is Some(sampler) {
    sampler.release()
  }
}

///|
fn GpuBackend::release_meshlet_owners(self : GpuBackend) -> Unit {
  for resources in self.meshlet_view_visibility_buffers.values() {
    meshlet_release_view_visibility_resources(resources)
  }
  let compute_pipelines = [
    self.meshlet_clear_visibility_buffer_pipeline,
    self.meshlet_first_instance_cull_pipeline,
    self.meshlet_first_bvh_cull_pipeline,
    self.meshlet_first_meshlet_cull_pipeline,
    self.meshlet_second_instance_cull_pipeline,
    self.meshlet_second_bvh_cull_pipeline,
    self.meshlet_second_meshlet_cull_pipeline,
    self.meshlet_visibility_buffer_software_raster_pipeline,
    self.meshlet_downsample_depth_first_pipeline,
    self.meshlet_downsample_depth_second_pipeline,
    self.meshlet_fill_counts_pipeline,
  ]
  for pipeline in compute_pipelines {
    if pipeline is Some(value) {
      value.release()
    }
  }
  let render_pipelines = [
    self.meshlet_visibility_buffer_hardware_raster_pipeline,
    self.meshlet_resolve_depth_pipeline,
    self.meshlet_resolve_material_depth_pipeline,
  ]
  for pipeline in render_pipelines {
    if pipeline is Some(value) {
      value.release()
    }
  }
  let pipeline_layouts = [
    self.meshlet_clear_visibility_buffer_pipeline_layout,
    self.meshlet_first_instance_cull_pipeline_layout,
    self.meshlet_first_bvh_cull_pipeline_layout,
    self.meshlet_first_meshlet_cull_pipeline_layout,
    self.meshlet_second_instance_cull_pipeline_layout,
    self.meshlet_second_bvh_cull_pipeline_layout,
    self.meshlet_second_meshlet_cull_pipeline_layout,
    self.meshlet_visibility_buffer_raster_pipeline_layout,
    self.meshlet_resolve_render_targets_pipeline_layout,
    self.meshlet_downsample_depth_pipeline_layout,
    self.meshlet_fill_counts_pipeline_layout,
  ]
  for layout in pipeline_layouts {
    if layout is Some(value) {
      value.release()
    }
  }
  let bind_group_layouts = [
    self.meshlet_clear_visibility_buffer_bgl,
    self.meshlet_first_instance_cull_bgl,
    self.meshlet_first_bvh_cull_bgl,
    self.meshlet_first_meshlet_cull_bgl,
    self.meshlet_second_instance_cull_bgl,
    self.meshlet_second_bvh_cull_bgl,
    self.meshlet_second_meshlet_cull_bgl,
    self.meshlet_visibility_buffer_raster_bgl,
    self.meshlet_resolve_render_targets_bgl,
    self.meshlet_downsample_depth_bgl,
    self.meshlet_fill_counts_bgl,
  ]
  for layout in bind_group_layouts {
    if layout is Some(value) {
      value.release()
    }
  }
  let buffers = [
    self.meshlet_vertex_positions_buf,
    self.meshlet_vertex_normals_buf,
    self.meshlet_vertex_uvs_buf,
    self.meshlet_indices_buf,
    self.meshlet_bvh_nodes_buf,
    self.meshlet_meshlets_buf,
    self.meshlet_cull_data_buf,
    self.meshlet_instance_uniforms_buf,
    self.meshlet_instance_aabbs_buf,
    self.meshlet_instance_material_ids_buf,
    self.meshlet_instance_bvh_root_nodes_buf,
    self.meshlet_visibility_buffer_raster_clusters_buf,
    self.meshlet_visibility_buffer_raster_cluster_prev_counts_buf,
    self.meshlet_software_raster_cluster_count_buf,
    self.meshlet_bvh_traversal_queue_0_buf,
    self.meshlet_bvh_traversal_queue_1_buf,
    self.meshlet_cluster_cull_candidate_queue_buf,
    self.meshlet_second_pass_candidates_buf,
    self.meshlet_clear_visibility_buffer_constants_buf,
    self.meshlet_first_instance_cull_constants_buf,
    self.meshlet_first_bvh_cull_constants_buf,
    self.meshlet_first_meshlet_cull_constants_buf,
    self.meshlet_second_instance_cull_constants_buf,
    self.meshlet_second_bvh_cull_constants_buf,
    self.meshlet_second_meshlet_cull_constants_buf,
    self.meshlet_visibility_buffer_raster_constants_buf,
    self.meshlet_resolve_render_targets_constants_buf,
  ]
  for buffer in buffers {
    if buffer is Some(value) {
      value.release()
    }
  }
  if self.meshlet_downsample_depth_dummy_view is Some(view) {
    view.release()
  }
  if self.meshlet_downsample_depth_dummy_texture is Some(texture) {
    texture.release()
  }
  if self.meshlet_downsample_depth_sampler is Some(sampler) {
    sampler.release()
  }
}

///|
fn GpuBackend::release_motion_vector_owners(_self : GpuBackend) -> Unit {

}

///|
fn GpuBackend::release_postprocess_feature_owners(_self : GpuBackend) -> Unit {

}

///|
fn GpuBackend::release_renderer_registry_owners(_self : GpuBackend) -> Unit {

}

///|
fn GpuBackend::shutdown(self : GpuBackend) -> Unit {
  if self.shutdown_complete {
    return
  }
  self.shutdown_complete = true
  ignore(self.device.poll(wait=true))
  self.release_frame_surface_2d_owners()
  self.release_mesh3d_pbr_owners()
  self.release_preprocess_meshlet_motion_owners()
  self.release_postprocess_feature_owners()
  self.release_renderer_registry_owners()
  self.release_frame_retired_resources()
  self.queue.release()
  self.device.release()
  self.adapter.release()
  self.instance.release()
}
