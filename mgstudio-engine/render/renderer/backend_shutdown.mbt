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
  self.release_frame_retired_resources()

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
fn GpuBackend::release_mesh3d_pbr_owners(_self : GpuBackend) -> Unit {

}

///|
fn GpuBackend::release_preprocess_meshlet_motion_owners(
  _self : GpuBackend,
) -> Unit {

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
  self.queue.release()
  self.device.release()
  self.adapter.release()
  self.instance.release()
}
