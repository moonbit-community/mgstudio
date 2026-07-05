// Copyright 2025 International Digital Economy Academy
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
pub struct GpuBackend {
  instance : @wgpu.Instance
  adapter : @wgpu.Adapter
  device : @wgpu.Device
  queue : @wgpu.Queue
  assets_base : String
  mut surface : @wgpu.Surface?
  mut surface_format : @wgpu.TextureFormat?
  mut configured_width : Int
  mut configured_height : Int
  mut surface_capture_active : Bool
  mut surface_cleared_this_frame : Bool
  mut frame : GpuFrameState?
  mut pass_state : GpuPassState?
  mut pass_has_depth : Bool
  frame_retired_buffers : Array[@wgpu.Buffer]
  frame_retired_bind_groups : Array[@wgpu.BindGroup]
  frame_retired_texture_views : Array[@wgpu.TextureView]
  mut frame_count : UInt
  mut depth_texture : @wgpu.Texture?
  mut depth_view : @wgpu.TextureView?
  mut depth_target_id : Int
  mut depth_width : Int
  mut depth_height : Int
  mut depth_sample_count : Int
  mut surface_msaa_texture : @wgpu.Texture?
  mut surface_msaa_view : @wgpu.TextureView?
  mut surface_msaa_target_id : Int
  mut surface_msaa_width : Int
  mut surface_msaa_height : Int
  mut surface_msaa_sample_count : Int
  mut surface_msaa_format : @wgpu.TextureFormat?
  mut sprite_bgl_tex : @wgpu.BindGroupLayout?
  mut sprite_bgl_globals : @wgpu.BindGroupLayout?
  mut sprite_pipeline_layout : @wgpu.PipelineLayout?
  mut sprite_pipeline : @wgpu.RenderPipeline?
  mut sprite_pipeline_surface : @wgpu.RenderPipeline?
  mut sprite_pipeline_surface_format : @wgpu.TextureFormat?
  mut sprite_pipeline_depth : @wgpu.RenderPipeline?
  mut sprite_pipeline_depth_surface : @wgpu.RenderPipeline?
  mut sprite_pipeline_depth_surface_format : @wgpu.TextureFormat?
  mut sprite_globals_buf : @wgpu.Buffer?
  mut sprite_instance_buf : @wgpu.Buffer?
  mut sprite_index_buf : @wgpu.Buffer?
  mut sprite_instance_capacity : UInt64
  mut sprite_globals_bg : @wgpu.BindGroup?
  mut sprite_view_bgl : @wgpu.BindGroupLayout?
  mut sprite_texture_bgl : @wgpu.BindGroupLayout?
  mut sprite_render_pipeline_layout : @wgpu.PipelineLayout?
  mut sprite_view_buf : @wgpu.Buffer?
  mut sprite_view_bg : @wgpu.BindGroup?
  mut sprite_lut_texture : @wgpu.Texture?
  mut sprite_lut_view : @wgpu.TextureView?
  mut sprite_lut_sampler : @wgpu.Sampler?
  sprite_instance_data : Array[Float]
  sprite_batches : Array[SpriteBatch]
  mut sprite_instance_count : UInt
  mut sprite_flush_count_this_frame : Int
  mut ui_view_bgl : @wgpu.BindGroupLayout?
  mut ui_pipeline_layout : @wgpu.PipelineLayout?
  mut ui_pipeline : @wgpu.RenderPipeline?
  mut ui_pipeline_anti_alias : @wgpu.RenderPipeline?
  mut ui_pipeline_surface : @wgpu.RenderPipeline?
  mut ui_pipeline_surface_anti_alias : @wgpu.RenderPipeline?
  mut ui_pipeline_surface_format : @wgpu.TextureFormat?
  mut ui_view_buf : @wgpu.Buffer?
  mut ui_view_bg : @wgpu.BindGroup?
  mut ui_vertex_buf : @wgpu.Buffer?
  mut ui_vertex_capacity : UInt64
  ui_vertex_data : Array[UInt]
  ui_batches : Array[UiBatch]
  mut ui_vertex_count : UInt
  mut ui_shadow_view_bgl : @wgpu.BindGroupLayout?
  mut ui_shadow_pipeline_layout : @wgpu.PipelineLayout?
  mut ui_shadow_view_buf : @wgpu.Buffer?
  mut ui_shadow_view_bg : @wgpu.BindGroup?
  mut ui_shadow_vertex_buf : @wgpu.Buffer?
  mut ui_shadow_vertex_capacity : UInt64
  ui_shadow_vertex_data : Array[UInt]
  ui_shadow_batches : Array[UiShadowBatch]
  ui_shadow_pipeline_cache : Array[UiShadowPipelineCacheEntry]
  mut ui_shadow_vertex_count : UInt
  mut ui_slice_view_bgl : @wgpu.BindGroupLayout?
  mut ui_slice_pipeline_layout : @wgpu.PipelineLayout?
  mut ui_slice_pipeline : @wgpu.RenderPipeline?
  mut ui_slice_pipeline_surface : @wgpu.RenderPipeline?
  mut ui_slice_pipeline_surface_format : @wgpu.TextureFormat?
  mut ui_slice_view_buf : @wgpu.Buffer?
  mut ui_slice_globals_buf : @wgpu.Buffer?
  mut ui_slice_view_bg : @wgpu.BindGroup?
  mut ui_slice_vertex_buf : @wgpu.Buffer?
  mut ui_slice_vertex_capacity : UInt64
  ui_slice_vertex_data : Array[UInt]
  ui_slice_batches : Array[UiBatch]
  mut ui_slice_vertex_count : UInt
  mut mesh_pipeline_layout : @wgpu.PipelineLayout?
  mut mesh2d_pipeline_layout_without_material : @wgpu.PipelineLayout?
  mut mesh_pipeline : @wgpu.RenderPipeline?
  mut mesh_pipeline_surface : @wgpu.RenderPipeline?
  mut mesh_pipeline_surface_format : @wgpu.TextureFormat?
  mut mesh2d_view_bgl : @wgpu.BindGroupLayout?
  mut mesh2d_mesh_bgl : @wgpu.BindGroupLayout?
  mut mesh2d_material_bgl : @wgpu.BindGroupLayout?
  mut mesh2d_view_buf : @wgpu.Buffer?
  mut mesh2d_globals_buf : @wgpu.Buffer?
  mut mesh2d_view_bg : @wgpu.BindGroup?
  mut mesh2d_lut_texture : @wgpu.Texture?
  mut mesh2d_lut_view : @wgpu.TextureView?
  mut mesh2d_lut_sampler : @wgpu.Sampler?
  mut mesh2d_instance_buf : @wgpu.Buffer?
  mut mesh2d_instance_bg : @wgpu.BindGroup?
  mut mesh2d_instance_capacity : UInt64
  mut mesh2d_gizmo_line_mesh_id : Int
  mut mesh2d_instance_used : Int
  mut mesh2d_batch_active : Bool
  mut mesh2d_batch_mesh_id : Int
  mut mesh2d_batch_alpha_mode_kind : Int
  mut mesh2d_batch_wireframe : Bool
  mut mesh2d_batch_vertex_shader_path : String
  mut mesh2d_batch_fragment_shader_path : String
  mut mesh2d_batch_pipeline_cache_key : String
  mut mesh2d_batch_material_hash : UInt64
  mut mesh2d_batch_material_key : Array[HostMaterial2dBinding]
  mut mesh2d_batch_uniform_base_offset : Int
  mut mesh2d_batch_instance_count : UInt
  mut mesh2d_batch_pipeline : @wgpu.RenderPipeline?
  mut mesh2d_batch_material_bg : @wgpu.BindGroup?
  mesh2d_pipeline_cache : Array[Mesh2dPipelineCacheEntry]
  mesh2d_pipeline_cache_index : @hashmap.HashMap[String, Int]
  mesh2d_pipeline_descriptors : Map[UInt64, Mesh2dRegisteredPipelineDescriptor]
  mesh2d_material_layout_cache : Array[Mesh2dMaterialLayoutCacheEntry]
  mesh2d_material_layout_cache_index : Map[UInt64, Array[Int]]
  mesh2d_material_bg_cache : Array[Mesh2dMaterialBindGroupCacheEntry]
  mesh2d_material_bg_cache_index : Map[UInt64, Array[Int]]
  line_gizmo_pipeline_cache : Array[LineGizmoPipelineCacheEntry]
  line_gizmo_queued_draws : Array[GpuQueuedLineGizmoDraw]
  mut mesh3d_bgl_view : @wgpu.BindGroupLayout?
  mut mesh3d_bgl_binding_arrays : @wgpu.BindGroupLayout?
  mut mesh3d_bgl_draw : @wgpu.BindGroupLayout?
  mut mesh3d_bgl_material : @wgpu.BindGroupLayout?
  mut mesh3d_bgl_skin : @wgpu.BindGroupLayout?
  mut mesh3d_binding_arrays_bg : @wgpu.BindGroup?
  mut mesh3d_pipeline_layout : @wgpu.PipelineLayout?
  mut mesh3d_shadow_bgl_view : @wgpu.BindGroupLayout?
  mut mesh3d_shadow_bgl_empty : @wgpu.BindGroupLayout?
  mut mesh3d_shadow_pipeline_layout_depth_only : @wgpu.PipelineLayout?
  mut mesh3d_shadow_pipeline_layout_material : @wgpu.PipelineLayout?
  mut mesh3d_shadow_view_bg : @wgpu.BindGroup?
  mut mesh3d_shadow_empty_bg : @wgpu.BindGroup?
  mesh3d_pipeline_cache : Array[Mesh3dPipelineCacheEntry]
  mesh3d_material_pipeline_descriptors : Array[
    Mesh3dRegisteredMaterialPipelineDescriptor,
  ]
  mesh3d_material_render_pipelines : Array[
    Mesh3dRegisteredMaterialRenderPipeline,
  ]
  mesh3d_material_pipeline_layout_cache : Array[
    Mesh3dMaterialPipelineLayoutCacheEntry,
  ]
  mesh3d_custom_pipeline_cache : Map[String, RenderPipelineCacheState]
  mesh3d_shadow_pipeline_cache : Array[Mesh3dShadowPipelineCacheEntry]
  mesh3d_volumetric_fog_pipeline_cache : Array[
    Mesh3dVolumetricFogPipelineCacheEntry,
  ]
  mut mesh3d_point_shadow_compare_sampler : @wgpu.Sampler?
  mut mesh3d_directional_shadow_compare_sampler : @wgpu.Sampler?
  mut mesh3d_view_buf : @wgpu.Buffer?
  mut mesh3d_lights_buf : @wgpu.Buffer?
  mut mesh3d_clustered_lights_buf : @wgpu.Buffer?
  mut mesh3d_clusterable_object_index_lists_buf : @wgpu.Buffer?
  mut mesh3d_cluster_offsets_and_counts_buf : @wgpu.Buffer?
  mut mesh3d_clustered_decals_buf : @wgpu.Buffer?
  mut mesh3d_clustered_decals_capacity : UInt64
  mut mesh3d_clustered_decals_revision : Int
  mesh3d_clustered_decal_texture_ids : Array[Int]
  mut mesh3d_globals_buf : @wgpu.Buffer?
  mut mesh3d_fog_buf : @wgpu.Buffer?
  mut mesh3d_volumetric_fog_buf : @wgpu.Buffer?
  mut mesh3d_volumetric_fog_capacity : UInt64
  mesh3d_volumetric_fog_bgls : Array[@wgpu.BindGroupLayout]
  mut mesh3d_light_probes_buf : @wgpu.Buffer?
  mut mesh3d_visibility_ranges_buf : @wgpu.Buffer?
  mut mesh3d_ssr_settings_buf : @wgpu.Buffer?
  mut mesh3d_contact_shadows_settings_buf : @wgpu.Buffer?
  mut mesh3d_motion_vector_pass_view_uniform_bytes : Bytes?
  mut mesh3d_motion_vector_pass_previous_view_uniform_bytes : Bytes?
  mesh3d_pass_uniform_states : Array[Mesh3dPassUniformState]
  mesh3d_frame_view_bg_cache : Array[Mesh3dFrameViewBindGroupCacheEntry]
  mesh3d_draw_slots : Array[GpuStorageSlot]
  mesh3d_draw_slot_skin_revisions : Array[Int]
  mesh3d_draw_slot_morph_revisions : Array[Int]
  mesh3d_draw_slot_material_pipeline_ids : Array[UInt64]
  mesh3d_draw_slot_lightmap_slab_indices : Array[Int]
  mesh3d_draw_slot_morph_target_texture_ids : Array[Int]
  mut mesh3d_draw_slot_used : Int
  mut mesh3d_skin_current_buf : @wgpu.Buffer?
  mut mesh3d_skin_current_bg : @wgpu.BindGroup?
  mut mesh3d_skin_prev_buf : @wgpu.Buffer?
  mut mesh3d_skin_prev_bg : @wgpu.BindGroup?
  mut mesh3d_skin_capacity : UInt64
  mut mesh3d_skin_staging_bytes : FixedArray[Byte]
  mut mesh3d_skin_staging_view : Bytes
  mut mesh3d_skin_revision : Int
  mut mesh3d_morph_current_buf : @wgpu.Buffer?
  mut mesh3d_morph_prev_buf : @wgpu.Buffer?
  mut mesh3d_morph_capacity : UInt64
  mut mesh3d_morph_revision : Int
  mut mesh3d_morph_descriptor_buf : @wgpu.Buffer?
  mut mesh3d_morph_descriptor_capacity : UInt64
  mesh3d_morph_target_buffers : Array[GpuMesh3dMorphTargetBufferInfo]
  mesh3d_instance_vertex_buffers : Array[GpuMesh3dInstanceVertexBufferInfo]
  mut mesh3d_gpu_instance_builder_enabled : Bool
  mut mesh3d_instance_draw_buf : @wgpu.Buffer?
  mut mesh3d_instance_draw_bg : @wgpu.BindGroup?
  mut mesh3d_instance_draw_capacity : UInt64
  mut mesh3d_instance_draw_skin_revision : Int
  mut mesh3d_instance_draw_morph_revision : Int
  mut mesh3d_instance_draw_material_pipeline_id : UInt64
  mut mesh3d_instance_draw_lightmap_slab_index : Int
  mut mesh3d_instance_draw_morph_target_texture_id : Int
  mut mesh3d_instance_draw_used : Int
  mut mesh3d_prepared_draw_camera_key_hi : Int
  mut mesh3d_prepared_draw_camera_key_lo : Int
  mut mesh3d_prepared_draw_pass_kind : Int
  mut mesh3d_prepared_draw_count : Int
  mesh3d_preprocess_camera_upload_states : Array[
    GpuMesh3dPreprocessCameraUploadState,
  ]
  mesh3d_preprocess_camera_upload_state_indices : Map[UInt64, Int]
  mut mesh3d_preprocess_reset_batch_sets_bgl : @wgpu.BindGroupLayout?
  mut mesh3d_preprocess_reset_batch_sets_pipeline_layout : @wgpu.PipelineLayout?
  mut mesh3d_preprocess_reset_batch_sets_pipeline : @wgpu.ComputePipeline?
  mut mesh3d_preprocess_direct_bgl : @wgpu.BindGroupLayout?
  mut mesh3d_preprocess_direct_pipeline_layout : @wgpu.PipelineLayout?
  mut mesh3d_preprocess_direct_pipeline : @wgpu.ComputePipeline?
  mut mesh3d_preprocess_indirect_bgl : @wgpu.BindGroupLayout?
  mut mesh3d_preprocess_indirect_pipeline_layout : @wgpu.PipelineLayout?
  mut mesh3d_preprocess_indirect_pipeline : @wgpu.ComputePipeline?
  mut mesh3d_preprocess_indirect_early_occlusion_bgl : @wgpu.BindGroupLayout?
  mut mesh3d_preprocess_indirect_early_occlusion_pipeline_layout : @wgpu.PipelineLayout?
  mut mesh3d_preprocess_indirect_early_occlusion_pipeline : @wgpu.ComputePipeline?
  mut mesh3d_preprocess_indirect_late_occlusion_bgl : @wgpu.BindGroupLayout?
  mut mesh3d_preprocess_indirect_late_occlusion_pipeline_layout : @wgpu.PipelineLayout?
  mut mesh3d_preprocess_indirect_late_occlusion_pipeline : @wgpu.ComputePipeline?
  mut mesh3d_preprocess_build_indexed_indirect_bgl : @wgpu.BindGroupLayout?
  mut mesh3d_preprocess_build_indexed_indirect_pipeline_layout : @wgpu.PipelineLayout?
  mut mesh3d_preprocess_build_indexed_indirect_pipeline : @wgpu.ComputePipeline?
  mut mesh3d_preprocess_build_indexed_indirect_early_pipeline : @wgpu.ComputePipeline?
  mut mesh3d_preprocess_build_indexed_indirect_late_pipeline : @wgpu.ComputePipeline?
  mut mesh3d_preprocess_build_indexed_indirect_main_pipeline : @wgpu.ComputePipeline?
  mut mesh3d_preprocess_build_non_indexed_indirect_bgl : @wgpu.BindGroupLayout?
  mut mesh3d_preprocess_build_non_indexed_indirect_pipeline_layout : @wgpu.PipelineLayout?
  mut mesh3d_preprocess_build_non_indexed_indirect_pipeline : @wgpu.ComputePipeline?
  mut mesh3d_preprocess_build_non_indexed_indirect_early_pipeline : @wgpu.ComputePipeline?
  mut mesh3d_preprocess_build_non_indexed_indirect_late_pipeline : @wgpu.ComputePipeline?
  mut mesh3d_preprocess_build_non_indexed_indirect_main_pipeline : @wgpu.ComputePipeline?
  mut mesh3d_preprocess_depth_pyramid_dummy_texture : @wgpu.Texture?
  mut mesh3d_preprocess_depth_pyramid_dummy_view : @wgpu.TextureView?
  mut mesh3d_preprocess_downsample_depth_bgl : @wgpu.BindGroupLayout?
  mut mesh3d_preprocess_downsample_depth_pipeline_layout : @wgpu.PipelineLayout?
  mut mesh3d_preprocess_downsample_depth_first_pipeline : @wgpu.ComputePipeline?
  mut mesh3d_preprocess_downsample_depth_second_pipeline : @wgpu.ComputePipeline?
  mut mesh3d_preprocess_depth_pyramid_sampler : @wgpu.Sampler?
  mut meshlet_vertex_positions_buf : @wgpu.Buffer?
  mut meshlet_vertex_positions_capacity : UInt64
  mut meshlet_vertex_normals_buf : @wgpu.Buffer?
  mut meshlet_vertex_normals_capacity : UInt64
  mut meshlet_vertex_uvs_buf : @wgpu.Buffer?
  mut meshlet_vertex_uvs_capacity : UInt64
  mut meshlet_indices_buf : @wgpu.Buffer?
  mut meshlet_indices_capacity : UInt64
  mut meshlet_bvh_nodes_buf : @wgpu.Buffer?
  mut meshlet_bvh_nodes_capacity : UInt64
  mut meshlet_meshlets_buf : @wgpu.Buffer?
  mut meshlet_meshlets_capacity : UInt64
  mut meshlet_cull_data_buf : @wgpu.Buffer?
  mut meshlet_cull_data_capacity : UInt64
  mut meshlet_instance_uniforms_buf : @wgpu.Buffer?
  mut meshlet_instance_uniforms_capacity : UInt64
  mut meshlet_instance_aabbs_buf : @wgpu.Buffer?
  mut meshlet_instance_aabbs_capacity : UInt64
  mut meshlet_instance_material_ids_buf : @wgpu.Buffer?
  mut meshlet_instance_material_ids_capacity : UInt64
  mut meshlet_instance_bvh_root_nodes_buf : @wgpu.Buffer?
  mut meshlet_instance_bvh_root_nodes_capacity : UInt64
  mut meshlet_gpu_buffer_revision : Int
  mut meshlet_visibility_buffer_raster_clusters_buf : @wgpu.Buffer?
  mut meshlet_visibility_buffer_raster_clusters_capacity : UInt64
  mut meshlet_visibility_buffer_raster_cluster_prev_counts_buf : @wgpu.Buffer?
  mut meshlet_software_raster_cluster_count_buf : @wgpu.Buffer?
  mut meshlet_bvh_traversal_queue_0_buf : @wgpu.Buffer?
  mut meshlet_bvh_traversal_queue_0_capacity : UInt64
  mut meshlet_bvh_traversal_queue_1_buf : @wgpu.Buffer?
  mut meshlet_bvh_traversal_queue_1_capacity : UInt64
  mut meshlet_cluster_cull_candidate_queue_buf : @wgpu.Buffer?
  mut meshlet_cluster_cull_candidate_queue_capacity : UInt64
  mut meshlet_second_pass_candidates_buf : @wgpu.Buffer?
  mut meshlet_second_pass_candidates_capacity : UInt64
  mut meshlet_frame_resource_revision : Int
  meshlet_view_visibility_buffers : Map[UInt64, MeshletViewVisibilityBuffer]
  mut meshlet_view_visibility_buffer_revision : Int
  mut meshlet_clear_visibility_buffer_bgl : @wgpu.BindGroupLayout?
  mut meshlet_clear_visibility_buffer_pipeline_layout : @wgpu.PipelineLayout?
  mut meshlet_clear_visibility_buffer_pipeline : @wgpu.ComputePipeline?
  mut meshlet_clear_visibility_buffer_constants_buf : @wgpu.Buffer?
  mut meshlet_clear_visibility_buffer_dispatch_count : Int
  mut meshlet_first_instance_cull_bgl : @wgpu.BindGroupLayout?
  mut meshlet_first_instance_cull_pipeline_layout : @wgpu.PipelineLayout?
  mut meshlet_first_instance_cull_pipeline : @wgpu.ComputePipeline?
  mut meshlet_first_instance_cull_constants_buf : @wgpu.Buffer?
  mut meshlet_first_instance_cull_dispatch_count : Int
  mut meshlet_first_bvh_cull_bgl : @wgpu.BindGroupLayout?
  mut meshlet_first_bvh_cull_pipeline_layout : @wgpu.PipelineLayout?
  mut meshlet_first_bvh_cull_pipeline : @wgpu.ComputePipeline?
  mut meshlet_first_bvh_cull_constants_buf : @wgpu.Buffer?
  mut meshlet_first_bvh_cull_dispatch_count : Int
  mut meshlet_first_meshlet_cull_bgl : @wgpu.BindGroupLayout?
  mut meshlet_first_meshlet_cull_pipeline_layout : @wgpu.PipelineLayout?
  mut meshlet_first_meshlet_cull_pipeline : @wgpu.ComputePipeline?
  mut meshlet_first_meshlet_cull_constants_buf : @wgpu.Buffer?
  mut meshlet_first_meshlet_cull_dispatch_count : Int
  mut meshlet_second_instance_cull_bgl : @wgpu.BindGroupLayout?
  mut meshlet_second_instance_cull_pipeline_layout : @wgpu.PipelineLayout?
  mut meshlet_second_instance_cull_pipeline : @wgpu.ComputePipeline?
  mut meshlet_second_instance_cull_constants_buf : @wgpu.Buffer?
  mut meshlet_second_instance_cull_dispatch_count : Int
  mut meshlet_second_bvh_cull_bgl : @wgpu.BindGroupLayout?
  mut meshlet_second_bvh_cull_pipeline_layout : @wgpu.PipelineLayout?
  mut meshlet_second_bvh_cull_pipeline : @wgpu.ComputePipeline?
  mut meshlet_second_bvh_cull_constants_buf : @wgpu.Buffer?
  mut meshlet_second_bvh_cull_dispatch_count : Int
  mut meshlet_second_meshlet_cull_bgl : @wgpu.BindGroupLayout?
  mut meshlet_second_meshlet_cull_pipeline_layout : @wgpu.PipelineLayout?
  mut meshlet_second_meshlet_cull_pipeline : @wgpu.ComputePipeline?
  mut meshlet_second_meshlet_cull_constants_buf : @wgpu.Buffer?
  mut meshlet_second_meshlet_cull_dispatch_count : Int
  mut meshlet_visibility_buffer_raster_bgl : @wgpu.BindGroupLayout?
  mut meshlet_visibility_buffer_raster_pipeline_layout : @wgpu.PipelineLayout?
  mut meshlet_visibility_buffer_software_raster_pipeline : @wgpu.ComputePipeline?
  mut meshlet_visibility_buffer_hardware_raster_pipeline : @wgpu.RenderPipeline?
  mut meshlet_visibility_buffer_raster_constants_buf : @wgpu.Buffer?
  mut meshlet_visibility_buffer_software_raster_dispatch_count : Int
  mut meshlet_visibility_buffer_hardware_raster_dispatch_count : Int
  mut meshlet_resolve_render_targets_bgl : @wgpu.BindGroupLayout?
  mut meshlet_resolve_render_targets_pipeline_layout : @wgpu.PipelineLayout?
  mut meshlet_resolve_depth_pipeline : @wgpu.RenderPipeline?
  mut meshlet_resolve_material_depth_pipeline : @wgpu.RenderPipeline?
  mut meshlet_resolve_render_targets_constants_buf : @wgpu.Buffer?
  mut meshlet_resolve_depth_dispatch_count : Int
  mut meshlet_resolve_material_depth_dispatch_count : Int
  mut meshlet_downsample_depth_bgl : @wgpu.BindGroupLayout?
  mut meshlet_downsample_depth_pipeline_layout : @wgpu.PipelineLayout?
  mut meshlet_downsample_depth_first_pipeline : @wgpu.ComputePipeline?
  mut meshlet_downsample_depth_second_pipeline : @wgpu.ComputePipeline?
  mut meshlet_downsample_depth_sampler : @wgpu.Sampler?
  mut meshlet_downsample_depth_dummy_texture : @wgpu.Texture?
  mut meshlet_downsample_depth_dummy_view : @wgpu.TextureView?
  mut meshlet_downsample_depth_dispatch_count : Int
  mut meshlet_fill_counts_bgl : @wgpu.BindGroupLayout?
  mut meshlet_fill_counts_pipeline_layout : @wgpu.PipelineLayout?
  mut meshlet_fill_counts_pipeline : @wgpu.ComputePipeline?
  mut meshlet_fill_counts_dispatch_count : Int
  mut mesh3d_motion_vector_bgl_view : @wgpu.BindGroupLayout?
  mut mesh3d_motion_vector_bgl_empty : @wgpu.BindGroupLayout?
  mut mesh3d_motion_vector_bgl_mesh : @wgpu.BindGroupLayout?
  mut mesh3d_motion_vector_pipeline_layout : @wgpu.PipelineLayout?
  mut mesh3d_motion_vector_pipeline : @wgpu.RenderPipeline?
  mut mesh3d_motion_vector_pipeline_skinned : @wgpu.RenderPipeline?
  mut mesh3d_motion_vector_pipeline_skinned_prev : @wgpu.RenderPipeline?
  mesh3d_motion_vector_pipeline_cache : Array[
    Mesh3dMotionVectorPipelineCacheEntry,
  ]
  mut mesh3d_motion_vector_view_buf : @wgpu.Buffer?
  mut mesh3d_motion_vector_globals_buf : @wgpu.Buffer?
  mut mesh3d_motion_vector_previous_view_buf : @wgpu.Buffer?
  mut mesh3d_motion_vector_visibility_ranges_buf : @wgpu.Buffer?
  mut mesh3d_motion_vector_view_bg : @wgpu.BindGroup?
  mut mesh3d_motion_vector_empty_bg : @wgpu.BindGroup?
  mesh3d_motion_vector_view_bg_cache : Array[
    Mesh3dMotionVectorViewBindGroupCacheEntry,
  ]
  mesh3d_motion_vector_mesh_slots : Array[GpuStorageSlot]
  mesh3d_motion_vector_mesh_slot_skin_revisions : Array[Int]
  mesh3d_motion_vector_mesh_slot_morph_revisions : Array[Int]
  mesh3d_motion_vector_mesh_slot_morph_target_texture_ids : Array[Int]
  mesh3d_motion_vector_mesh_slot_layout_masks : Array[Int]
  mut mesh3d_motion_vector_mesh_slot_used : Int
  mut mesh3d_motion_vector_instance_mesh_buf : @wgpu.Buffer?
  mut mesh3d_motion_vector_instance_mesh_bg : @wgpu.BindGroup?
  mut mesh3d_motion_vector_instance_mesh_capacity : UInt64
  mut mesh3d_motion_vector_instance_mesh_used : Int
  mut mesh3d_motion_vector_instance_mesh_skin_revision : Int
  mut mesh3d_motion_vector_instance_mesh_morph_revision : Int
  mut mesh3d_motion_vector_instance_mesh_morph_target_texture_id : Int
  mut mesh3d_motion_vector_instance_mesh_layout_mask : Int
  mut effect_stack_bgl : @wgpu.BindGroupLayout?
  mut effect_stack_pipeline_layout : @wgpu.PipelineLayout?
  mut effect_stack_pipeline : @wgpu.RenderPipeline?
  mut effect_stack_pipeline_surface : @wgpu.RenderPipeline?
  mut effect_stack_pipeline_surface_format : @wgpu.TextureFormat?
  mut effect_stack_sampler : @wgpu.Sampler?
  mut effect_stack_lut_sampler : @wgpu.Sampler?
  mut effect_stack_chromatic_settings_buf : @wgpu.Buffer?
  mut effect_stack_vignette_settings_buf : @wgpu.Buffer?
  mut effect_stack_default_lut_texture_id : Int
  mut custom_postprocess3d_bgl : @wgpu.BindGroupLayout?
  mut custom_postprocess3d_pipeline_layout : @wgpu.PipelineLayout?
  mut custom_postprocess3d_sampler : @wgpu.Sampler?
  mut custom_postprocess3d_uniform_buf : @wgpu.Buffer?
  custom_postprocess3d_pipeline_cache : Array[
    CustomPostProcessPipelineCacheEntry,
  ]
  mut skybox_bgl : @wgpu.BindGroupLayout?
  mut skybox_pipeline_layout : @wgpu.PipelineLayout?
  mut skybox_uniform_buf : @wgpu.Buffer?
  skybox_pipeline_cache : Array[SkyboxPipelineCacheEntry]
  skybox_prepared_bind_groups : Array[SkyboxPreparedBindGroupEntry]
  mut skybox_next_prepared_bind_group_id : Int
  mut cas_bgl : @wgpu.BindGroupLayout?
  mut cas_pipeline_layout : @wgpu.PipelineLayout?
  mut cas_sampler : @wgpu.Sampler?
  mut cas_uniform_buf : @wgpu.Buffer?
  cas_pipeline_cache : Array[CasPipelineCacheEntry]
  mut blit_bgl : @wgpu.BindGroupLayout?
  mut blit_pipeline_layout : @wgpu.PipelineLayout?
  mut blit_pipeline : @wgpu.RenderPipeline?
  mut blit_pipeline_format : @wgpu.TextureFormat?
  mut blit_sampler : @wgpu.Sampler?
  mut screenshot_to_screen_bgl : @wgpu.BindGroupLayout?
  mut screenshot_to_screen_pipeline_layout : @wgpu.PipelineLayout?
  mut screenshot_to_screen_pipeline : @wgpu.RenderPipeline?
  mut screenshot_to_screen_pipeline_format : @wgpu.TextureFormat?
  mut fxaa_bgl : @wgpu.BindGroupLayout?
  mut fxaa_pipeline_layout : @wgpu.PipelineLayout?
  mut fxaa_pipeline : @wgpu.RenderPipeline?
  mut fxaa_pipeline_surface : @wgpu.RenderPipeline?
  mut fxaa_pipeline_surface_format : @wgpu.TextureFormat?
  mut fxaa_pipeline_edge_threshold_mode : Int
  mut fxaa_pipeline_edge_threshold_min_mode : Int
  mut fxaa_pipeline_surface_edge_threshold_mode : Int
  mut fxaa_pipeline_surface_edge_threshold_min_mode : Int
  mut fxaa_sampler : @wgpu.Sampler?
  mut taa_bgl : @wgpu.BindGroupLayout?
  mut taa_pipeline_layout : @wgpu.PipelineLayout?
  mut taa_nearest_sampler : @wgpu.Sampler?
  mut taa_linear_sampler : @wgpu.Sampler?
  taa_history_textures : Array[GpuTaaHistoryTextures]
  taa_pipeline_cache : Array[GpuTaaPipelineCacheEntry]
  mut bloom_intermediate_bgl : @wgpu.BindGroupLayout?
  mut bloom_intermediate_pipeline_layout : @wgpu.PipelineLayout?
  mut tonemapping_bgl : @wgpu.BindGroupLayout?
  mut tonemapping_pipeline_layout : @wgpu.PipelineLayout?
  mut tonemapping_view_buf : @wgpu.Buffer?
  mut tonemapping_sampler : @wgpu.Sampler?
  tonemapping_pipeline_cache : Array[TonemappingPipelineCacheEntry]
  mut bloom_downsample_first_pipeline : @wgpu.RenderPipeline?
  mut bloom_downsample_first_no_threshold_pipeline : @wgpu.RenderPipeline?
  mut bloom_downsample_first_uniform_pipeline : @wgpu.RenderPipeline?
  mut bloom_downsample_first_no_threshold_uniform_pipeline : @wgpu.RenderPipeline?
  mut bloom_downsample_pipeline : @wgpu.RenderPipeline?
  mut bloom_downsample_uniform_pipeline : @wgpu.RenderPipeline?
  mut bloom_upsample_pipeline_energy : @wgpu.RenderPipeline?
  mut bloom_upsample_pipeline_additive : @wgpu.RenderPipeline?
  mut bloom_upsample_final_pipeline_energy : @wgpu.RenderPipeline?
  mut bloom_upsample_final_pipeline_additive : @wgpu.RenderPipeline?
  mut bloom_upsample_final_pipeline_format : @wgpu.TextureFormat?
  mut bloom_settings_buf : @wgpu.Buffer?
  mut bloom_sampler : @wgpu.Sampler?
  mut bloom_mip_texture : @wgpu.Texture?
  bloom_mip_views : Array[@wgpu.TextureView]
  mut bloom_mip_count : Int
  mut bloom_mip_width : Int
  mut bloom_mip_height : Int
  mut tonemapping_fallback_lut_texture_id : Int
  mut auto_exposure_compute_bgl : @wgpu.BindGroupLayout?
  mut auto_exposure_compute_pipeline_layout : @wgpu.PipelineLayout?
  mut auto_exposure_histogram_pipeline : @wgpu.ComputePipeline?
  mut auto_exposure_average_pipeline : @wgpu.ComputePipeline?
  mut auto_exposure_globals_buf : @wgpu.Buffer?
  mut auto_exposure_settings_buf : @wgpu.Buffer?
  mut auto_exposure_curve_extents_buf : @wgpu.Buffer?
  mut auto_exposure_histogram_buf : @wgpu.Buffer?
  mut auto_exposure_curve_texture : @wgpu.Texture?
  mut auto_exposure_curve_view : @wgpu.TextureView?
  mut auto_exposure_active_state_buf : @wgpu.Buffer?
  auto_exposure_view_states : Array[GpuAutoExposureViewState]
  mesh3d_view_bg_cache : Array[Mesh3dViewBindGroupCacheEntry]
  mesh3d_material_bg_cache : Array[Mesh3dMaterialBindGroupCacheEntry]
  mut mesh3d_ssao_resources : GpuSsaoResources?
  mut mesh3d_ssao_resource_revision : Int
  mut mesh3d_ssao_pipelines : GpuSsaoPipelines?
  mesh3d_ssao_pipeline_cache : Array[GpuSsaoPipelineCacheEntry]
  mut mesh3d_ssao_pending_pipeline : @wgpu.ComputePipeline?
  mut mesh3d_atmosphere_resources : GpuAtmosphereResources?
  mut mesh3d_atmosphere_resource_revision : Int
  mut light_probe_environment_generator : GpuLightProbeEnvironmentGenerator?
  mut light_probe_environment_intermediate : GpuLightProbeIntermediateTexture?
  mut mesh3d_scattering_medium_resources : GpuScatteringMediumResources?
  mut mesh3d_scattering_medium_resource_revision : Int
  mut mesh3d_deferred_lighting_id_depth_texture : GpuDeferredLightingIdDepthTexture?
  mut mesh3d_copy_deferred_lighting_id_bind_group_layout : @wgpu.BindGroupLayout?
  mut mesh3d_copy_deferred_lighting_id_pipeline_layout : @wgpu.PipelineLayout?
  mut mesh3d_copy_deferred_lighting_id_pipeline : @wgpu.RenderPipeline?
  mesh3d_deferred_lighting_pipeline_cache : Array[
    GpuDeferredLightingPipelineCacheEntry,
  ]
  mut mesh3d_ssr_bind_group_layout : @wgpu.BindGroupLayout?
  mut mesh3d_ssr_color_sampler : @wgpu.Sampler?
  mut mesh3d_ssr_depth_linear_sampler : @wgpu.Sampler?
  mut mesh3d_ssr_depth_nearest_sampler : @wgpu.Sampler?
  mesh3d_ssr_pipeline_cache : Array[GpuScreenSpaceReflectionsPipelineCacheEntry]
  sampler_cache : @hashmap.HashMap[String, @wgpu.Sampler]
  mut next_id : Int
  mut normal_map_fallback_texture_id : Int
  mut point_shadow_fallback_texture_id : Int
  mut directional_shadow_fallback_texture_id : Int
  mut transmission_source_fallback_texture_id : Int
  mut environment_map_fallback_texture_id : Int
  mut irradiance_volume_fallback_texture_id : Int
  surfaces : Array[GpuSurfaceState]
  mut active_surface_target_id : Int
  textures : Array[GpuTextureInfo]
  prepass_depth_textures : Array[GpuPrepassDepthTextureInfo]
  meshes : Array[GpuMeshInfo]
  mesh_allocator : @render_mesh.MeshAllocator
  mesh_allocator_buffers : Array[GpuMeshAllocatorBuffer]
}
