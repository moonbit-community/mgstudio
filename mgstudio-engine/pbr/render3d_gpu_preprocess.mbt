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
fn render3d_absf(value : Float) -> Float {
  if value < 0.0F {
    0.0F - value
  } else {
    value
  }
}

///|
fn render3d_mesh_preprocess_static_for_payload(
  payload : Mesh3dExtractedPayload,
  mesh_preprocess_static_cache : Map[Int, MeshPreprocessStatic3d],
) -> MeshPreprocessStatic3d? {
  let mesh_handle_id = payload.mesh_handle.id()
  if mesh_handle_id < 0 {
    return None
  }
  match mesh_preprocess_static_cache.get(mesh_handle_id) {
    Some(metadata) => Some(metadata)
    None => Some(render3d_mesh_preprocess_static(payload.mesh_handle))
  }
}

///|
fn render3d_mesh_frustum_visible(
  payload : Mesh3dExtractedPayload,
  camera_frustum_planes : Array[@render.HostMesh3dPreprocessFrustumPlane],
  mesh_preprocess_static_cache : Map[Int, MeshPreprocessStatic3d],
) -> Bool {
  guard render3d_mesh_preprocess_static_for_payload(
      payload, mesh_preprocess_static_cache,
    )
    is Some(mesh_static) else {
    return true
  }
  if !mesh_static.has_local_aabb {
    return true
  }
  let center_world = render3d_transform_point(
    payload.transform,
    mesh_static.aabb_center,
  )
  let scaled_half_extents = @math.Vec3::new(
    mesh_static.aabb_half_extents.x * render3d_absf(payload.transform.scale.x),
    mesh_static.aabb_half_extents.y * render3d_absf(payload.transform.scale.y),
    mesh_static.aabb_half_extents.z * render3d_absf(payload.transform.scale.z),
  )
  let radius = scaled_half_extents.length()
  for plane in camera_frustum_planes {
    let signed_distance = plane.normal_x * center_world.x +
      plane.normal_y * center_world.y +
      plane.normal_z * center_world.z +
      plane.distance
    if signed_distance < 0.0F - radius {
      return false
    }
  }
  true
}

///|
fn render3d_queue_mesh_phase_items_cpu_builder(
  meshes : Array[ExtractedMesh3d],
  layers : @sprite.RenderLayers,
  camera_transform : @transform.Transform,
  camera_frustum_planes : Array[@render.HostMesh3dPreprocessFrustumPlane],
  mesh_preprocess_static_cache : Map[Int, MeshPreprocessStatic3d],
) -> Array[MeshPhaseItem3d] {
  let items : Array[MeshPhaseItem3d] = []
  for i in 0..<meshes.length() {
    let mesh = meshes[i]
    let payload = mesh.payload
    if payload.mesh_id <= 0 {
      continue
    }
    if !payload.layers.matches(layers) {
      continue
    }
    if payload.visibility_range is Some(visibility_range) &&
      !render3d_visibility_range_visible(
        visibility_range,
        camera_transform,
        payload.transform,
        payload.aabb_center_world,
      ) {
      continue
    }
    if !payload.has_no_frustum_culling &&
      !render3d_mesh_frustum_visible(
        payload, camera_frustum_planes, mesh_preprocess_static_cache,
      ) {
      continue
    }
    let alpha = payload.material.base_color.a
    if render3d_mesh_phase_kind(payload.material.alpha_mode, alpha) is None {
      continue
    }
    let phase = render3d_mesh_phase_kind(payload.material.alpha_mode, alpha).unwrap()
    items.push(MeshPhaseItem3d::{
      entity: mesh.entity,
      extracted_index: i,
      phase,
      distance: render3d_mesh_view_depth(payload.transform, camera_transform),
    })
  }
  items.sort_by(fn(a, b) {
    let phase_cmp = cmp_int(a.phase, b.phase)
    if phase_cmp != 0 {
      return phase_cmp
    }
    if a.phase == RENDER3D_PHASE_TRANSPARENT {
      let depth_cmp = cmp_float(b.distance, a.distance)
      if depth_cmp != 0 {
        return depth_cmp
      }
    } else {
      let depth_cmp = cmp_float(a.distance, b.distance)
      if depth_cmp != 0 {
        return depth_cmp
      }
    }
    phase_entity_ref3d_cmp(a.entity, b.entity)
  })
  items
}

///|
priv struct GpuPreprocessWorkItem3d {
  entity : PhaseEntityRef3d
  extracted_index : Int
  phase : Int
  distance : Float
}

///|
fn render3d_collect_meshes_for_gpu_building(
  meshes : Array[ExtractedMesh3d],
  layers : @sprite.RenderLayers,
  camera_transform : @transform.Transform,
  camera_frustum_planes : Array[@render.HostMesh3dPreprocessFrustumPlane],
  mesh_preprocess_static_cache : Map[Int, MeshPreprocessStatic3d],
) -> Array[GpuPreprocessWorkItem3d] {
  let work_items : Array[GpuPreprocessWorkItem3d] = []
  for i in 0..<meshes.length() {
    let mesh = meshes[i]
    let payload = mesh.payload
    if payload.mesh_id <= 0 {
      continue
    }
    if !payload.layers.matches(layers) {
      continue
    }
    if payload.visibility_range is Some(visibility_range) &&
      !render3d_visibility_range_visible(
        visibility_range,
        camera_transform,
        payload.transform,
        payload.aabb_center_world,
      ) {
      continue
    }
    if !payload.has_no_frustum_culling &&
      !render3d_mesh_frustum_visible(
        payload, camera_frustum_planes, mesh_preprocess_static_cache,
      ) {
      continue
    }
    let alpha = payload.material.base_color.a
    guard render3d_mesh_phase_kind(payload.material.alpha_mode, alpha)
      is Some(phase) else {
      continue
    }
    work_items.push(GpuPreprocessWorkItem3d::{
      entity: mesh.entity,
      extracted_index: i,
      phase,
      distance: render3d_mesh_view_depth(payload.transform, camera_transform),
    })
  }
  work_items
}

///|
fn render3d_sort_gpu_preprocess_work_items(
  work_items : Array[GpuPreprocessWorkItem3d],
) -> Array[GpuPreprocessWorkItem3d] {
  let opaque_items : Array[GpuPreprocessWorkItem3d] = []
  let alpha_mask_items : Array[GpuPreprocessWorkItem3d] = []
  let transparent_items : Array[GpuPreprocessWorkItem3d] = []
  for work_item in work_items {
    if work_item.phase == RENDER3D_PHASE_OPAQUE {
      opaque_items.push(work_item)
    } else if work_item.phase == RENDER3D_PHASE_ALPHA_MASK {
      alpha_mask_items.push(work_item)
    } else if work_item.phase == RENDER3D_PHASE_TRANSPARENT {
      transparent_items.push(work_item)
    }
  }
  transparent_items.sort_by(fn(a, b) {
    let depth_cmp = cmp_float(b.distance, a.distance)
    if depth_cmp != 0 {
      return depth_cmp
    }
    phase_entity_ref3d_cmp(a.entity, b.entity)
  })
  let sorted : Array[GpuPreprocessWorkItem3d] = []
  for item in opaque_items {
    sorted.push(item)
  }
  for item in alpha_mask_items {
    sorted.push(item)
  }
  for item in transparent_items {
    sorted.push(item)
  }
  sorted
}

///|
fn render3d_write_batched_instance_buffers(
  work_items : Array[GpuPreprocessWorkItem3d],
) -> Array[MeshPhaseItem3d] {
  let phase_items : Array[MeshPhaseItem3d] = []
  for work_item in render3d_sort_gpu_preprocess_work_items(work_items) {
    phase_items.push(MeshPhaseItem3d::{
      entity: work_item.entity,
      extracted_index: work_item.extracted_index,
      phase: work_item.phase,
      distance: work_item.distance,
    })
  }
  phase_items
}

///|
fn render3d_build_gpu_preprocess_phase_ranges_from_draw_items(
  draw_items : Array[MeshPhaseItem3d],
) -> Array[GpuPreprocessPhaseRange3d] {
  let phase_ranges : Array[GpuPreprocessPhaseRange3d] = []
  if draw_items.length() == 0 {
    return phase_ranges
  }
  let mut current_phase = draw_items[0].phase
  let mut range_start = 0
  for i in 1..<draw_items.length() {
    if draw_items[i].phase == current_phase {
      continue
    }
    phase_ranges.push(GpuPreprocessPhaseRange3d::{
      phase: current_phase,
      start: range_start,
      end: i,
    })
    current_phase = draw_items[i].phase
    range_start = i
  }
  phase_ranges.push(GpuPreprocessPhaseRange3d::{
    phase: current_phase,
    start: range_start,
    end: draw_items.length(),
  })
  phase_ranges
}

///|
fn render3d_empty_gpu_preprocess_indirect_mesh_class_metadata() -> GpuPreprocessIndirectMeshClassMetadata3d {
  let indirect_parameters_cpu_metadata : Array[
    GpuPreprocessIndirectParametersCpuMetadata3d,
  ] = []
  let indirect_parameters_gpu_metadata : Array[
    GpuPreprocessIndirectParametersGpuMetadata3d,
  ] = []
  let indirect_batch_sets : Array[GpuPreprocessIndirectBatchSet3d] = []
  GpuPreprocessIndirectMeshClassMetadata3d::{
    indirect_parameters_cpu_metadata,
    indirect_parameters_gpu_metadata,
    indirect_batch_sets,
  }
}

///|
fn render3d_build_gpu_preprocess_indirect_mesh_class_metadata(
  items : Array[GpuPreprocessShaderWorkItem3d],
) -> GpuPreprocessIndirectMeshClassMetadata3d {
  let indirect_parameters_cpu_metadata : Array[
    GpuPreprocessIndirectParametersCpuMetadata3d,
  ] = []
  let indirect_parameters_gpu_metadata : Array[
    GpuPreprocessIndirectParametersGpuMetadata3d,
  ] = []
  let indirect_batch_sets : Array[GpuPreprocessIndirectBatchSet3d] = []
  let has_items = items.length() > 0
  for item in items {
    let indirect_parameters_index = item.output_or_indirect_parameters_index
    indirect_parameters_cpu_metadata.push(GpuPreprocessIndirectParametersCpuMetadata3d::{
      base_output_index: item.input_index,
      batch_set_index: if has_items {
        0
      } else {
        -1
      },
    })
    indirect_parameters_gpu_metadata.push(GpuPreprocessIndirectParametersGpuMetadata3d::{
      mesh_index: item.input_index,
      early_instance_count: 0,
      late_instance_count: 0,
    })
    indirect_parameters_index |> ignore
  }
  if has_items {
    indirect_batch_sets.push(GpuPreprocessIndirectBatchSet3d::{
      indirect_parameters_count: items.length(),
      indirect_parameters_base: 0,
    })
  }
  GpuPreprocessIndirectMeshClassMetadata3d::{
    indirect_parameters_cpu_metadata,
    indirect_parameters_gpu_metadata,
    indirect_batch_sets,
  }
}

///|
fn render3d_build_gpu_preprocess_indirect_metadata(
  work_item_buffers : GpuPreprocessWorkItemBuffers3d,
) -> GpuPreprocessIndirectMetadata3d {
  match work_item_buffers {
    Direct(_) =>
      GpuPreprocessIndirectMetadata3d::{
        indexed: render3d_empty_gpu_preprocess_indirect_mesh_class_metadata(),
        non_indexed: render3d_empty_gpu_preprocess_indirect_mesh_class_metadata(),
      }
    Indirect(indexed_items, non_indexed_items, _) =>
      GpuPreprocessIndirectMetadata3d::{
        indexed: render3d_build_gpu_preprocess_indirect_mesh_class_metadata(
          indexed_items,
        ),
        non_indexed: render3d_build_gpu_preprocess_indirect_mesh_class_metadata(
          non_indexed_items,
        ),
      }
  }
}

///|
fn render3d_gpu_preprocess_workgroup_count(item_count : Int) -> Int {
  if item_count <= 0 {
    return 0
  }
  let quotient = item_count / RENDER3D_GPU_PREPROCESS_WORKGROUP_SIZE
  if item_count % RENDER3D_GPU_PREPROCESS_WORKGROUP_SIZE == 0 {
    quotient
  } else {
    quotient + 1
  }
}

///|
fn render3d_build_gpu_preprocess_dispatch_metadata(
  work_item_buffers : GpuPreprocessWorkItemBuffers3d,
) -> GpuPreprocessDispatchMetadata3d {
  match work_item_buffers {
    Direct(items) =>
      GpuPreprocessDispatchMetadata3d::{
        direct_workgroup_count: render3d_gpu_preprocess_workgroup_count(
          items.length(),
        ),
        indexed_workgroup_count: 0,
        non_indexed_workgroup_count: 0,
        late_indexed_workgroup_count: 0,
        late_non_indexed_workgroup_count: 0,
      }
    Indirect(indexed_items, non_indexed_items, gpu_occlusion_culling) => {
      let late_indexed_item_count = match gpu_occlusion_culling {
        Some(_culling_buffers) => indexed_items.length()
        None => 0
      }
      let late_non_indexed_item_count = match gpu_occlusion_culling {
        Some(_culling_buffers) => non_indexed_items.length()
        None => 0
      }
      GpuPreprocessDispatchMetadata3d::{
        direct_workgroup_count: 0,
        indexed_workgroup_count: render3d_gpu_preprocess_workgroup_count(
          indexed_items.length(),
        ),
        non_indexed_workgroup_count: render3d_gpu_preprocess_workgroup_count(
          non_indexed_items.length(),
        ),
        late_indexed_workgroup_count: render3d_gpu_preprocess_workgroup_count(
          late_indexed_item_count,
        ),
        late_non_indexed_workgroup_count: render3d_gpu_preprocess_workgroup_count(
          late_non_indexed_item_count,
        ),
      }
    }
  }
}

///|
fn render3d_build_gpu_occlusion_culling_work_item_buffers(
  indexed_work_items : Array[GpuPreprocessShaderWorkItem3d],
  non_indexed_work_items : Array[GpuPreprocessShaderWorkItem3d],
  enabled : Bool,
) -> GpuOcclusionCullingWorkItemBuffers3d? {
  if !enabled {
    return None
  }
  ignore(indexed_work_items)
  ignore(non_indexed_work_items)
  Some(GpuOcclusionCullingWorkItemBuffers3d::{ enabled: true })
}

///|
fn render3d_mesh_preprocess_indirect_eligible(
  extracted_mesh : ExtractedMesh3d,
) -> Bool {
  extracted_mesh.payload.mesh_id > 0
}

///|
fn render3d_build_gpu_preprocess_work_item_buffers_from_draw_items(
  draw_items : Array[MeshPhaseItem3d],
  meshes : Array[ExtractedMesh3d],
  indirect_enabled : Bool,
  gpu_occlusion_culling_enabled : Bool,
) -> GpuPreprocessWorkItemBuffers3d {
  if !indirect_enabled {
    let direct_work_items : Array[GpuPreprocessShaderWorkItem3d] = []
    for i in 0..<draw_items.length() {
      direct_work_items.push(GpuPreprocessShaderWorkItem3d::{
        input_index: i,
        output_or_indirect_parameters_index: i,
      })
    }
    return GpuPreprocessWorkItemBuffers3d::Direct(direct_work_items)
  }
  let indexed_work_items : Array[GpuPreprocessShaderWorkItem3d] = []
  let non_indexed_work_items : Array[GpuPreprocessShaderWorkItem3d] = []
  for i in 0..<draw_items.length() {
    let draw_item = draw_items[i]
    if draw_item.phase != RENDER3D_PHASE_OPAQUE &&
      draw_item.phase != RENDER3D_PHASE_ALPHA_MASK {
      continue
    }
    if draw_item.extracted_index < 0 ||
      draw_item.extracted_index >= meshes.length() {
      continue
    }
    let extracted_mesh = meshes[draw_item.extracted_index]
    if !render3d_mesh_preprocess_indirect_eligible(extracted_mesh) {
      continue
    }
    let indexed = extracted_mesh.payload.mesh_is_indexed
    if indexed {
      indexed_work_items.push(GpuPreprocessShaderWorkItem3d::{
        input_index: i,
        output_or_indirect_parameters_index: indexed_work_items.length(),
      })
    } else {
      non_indexed_work_items.push(GpuPreprocessShaderWorkItem3d::{
        input_index: i,
        output_or_indirect_parameters_index: non_indexed_work_items.length(),
      })
    }
  }
  GpuPreprocessWorkItemBuffers3d::Indirect(
    indexed_work_items,
    non_indexed_work_items,
    render3d_build_gpu_occlusion_culling_work_item_buffers(
      indexed_work_items, non_indexed_work_items, gpu_occlusion_culling_enabled,
    ),
  )
}

///|
fn render3d_make_fallback_gpu_preprocess_queue_entry(
  draw_items : Array[MeshPhaseItem3d],
  meshes : Array[ExtractedMesh3d],
  mesh_preprocess_static_cache : Map[Int, MeshPreprocessStatic3d],
  indirect_enabled : Bool,
  gpu_occlusion_culling_enabled : Bool,
) -> GpuPreprocessResolvedCameraQueueEntry3d {
  let phase_ranges = render3d_build_gpu_preprocess_phase_ranges_from_draw_items(
    draw_items,
  )
  let work_item_buffers = render3d_build_gpu_preprocess_work_item_buffers_from_draw_items(
    draw_items, meshes, indirect_enabled, gpu_occlusion_culling_enabled,
  )
  let indirect_metadata = render3d_build_gpu_preprocess_indirect_metadata(
    work_item_buffers,
  )
  let dispatch_metadata = render3d_build_gpu_preprocess_dispatch_metadata(
    work_item_buffers,
  )
  let mesh_culling_data : Array[@render.HostMesh3dPreprocessMeshCullingData] = []
  let mesh_inputs : Array[@render.HostMesh3dPreprocessMeshInput] = []
  for draw_item in draw_items {
    mesh_culling_data.push(
      render3d_host_preprocess_mesh_culling_data(
        draw_item, meshes, mesh_preprocess_static_cache,
      ),
    )
    mesh_inputs.push(
      render3d_host_preprocess_mesh_input(
        draw_item, meshes, mesh_preprocess_static_cache,
      ),
    )
  }
  GpuPreprocessResolvedCameraQueueEntry3d::{
    draw_items,
    phase_ranges,
    indirect_metadata,
    dispatch_metadata,
    work_item_buffers,
    mesh_culling_data,
    mesh_inputs,
  }
}

///|
fn render3d_gpu_preprocess_opaque_alpha_end_index(
  phase_ranges : Array[GpuPreprocessPhaseRange3d],
) -> Int {
  let mut opaque_alpha_end = 0
  for phase_range in phase_ranges {
    if phase_range.start < 0 {
      continue
    }
    if phase_range.phase != RENDER3D_PHASE_OPAQUE &&
      phase_range.phase != RENDER3D_PHASE_ALPHA_MASK {
      continue
    }
    if phase_range.end > opaque_alpha_end {
      opaque_alpha_end = phase_range.end
    }
  }
  opaque_alpha_end
}

///|
fn render3d_host_preprocess_shader_work_item(
  item : GpuPreprocessShaderWorkItem3d,
) -> @render.HostMesh3dPreprocessShaderWorkItem {
  @render.HostMesh3dPreprocessShaderWorkItem::{
    input_index: item.input_index,
    output_or_indirect_parameters_index: item.output_or_indirect_parameters_index,
  }
}

///|
fn render3d_host_preprocess_cpu_metadata(
  metadata : GpuPreprocessIndirectParametersCpuMetadata3d,
) -> @render.HostMesh3dPreprocessIndirectParametersCpuMetadata {
  @render.HostMesh3dPreprocessIndirectParametersCpuMetadata::{
    base_output_index: metadata.base_output_index,
    batch_set_index: metadata.batch_set_index,
  }
}

///|
fn render3d_host_preprocess_gpu_metadata(
  metadata : GpuPreprocessIndirectParametersGpuMetadata3d,
) -> @render.HostMesh3dPreprocessIndirectParametersGpuMetadata {
  @render.HostMesh3dPreprocessIndirectParametersGpuMetadata::{
    mesh_index: metadata.mesh_index,
    early_instance_count: metadata.early_instance_count,
    late_instance_count: metadata.late_instance_count,
  }
}

///|
fn render3d_host_preprocess_batch_set(
  batch_set : GpuPreprocessIndirectBatchSet3d,
) -> @render.HostMesh3dPreprocessIndirectBatchSet {
  @render.HostMesh3dPreprocessIndirectBatchSet::{
    indirect_parameters_count: batch_set.indirect_parameters_count,
    indirect_parameters_base: batch_set.indirect_parameters_base,
  }
}

///|
fn render3d_host_preprocess_view_frustum_planes(
  projection : Projection,
  camera_transform : @transform.Transform,
) -> Array[@render.HostMesh3dPreprocessFrustumPlane] {
  let planes : Array[@render.HostMesh3dPreprocessFrustumPlane] = []
  for half_space in projection.compute_frustum(camera_transform).half_spaces {
    let normal_d = half_space.normal_d
    planes.push(@render.HostMesh3dPreprocessFrustumPlane::{
      normal_x: normal_d.x,
      normal_y: normal_d.y,
      normal_z: normal_d.z,
      distance: normal_d.w,
    })
  }
  planes
}

///|
fn render3d_host_preprocess_view(
  projection : Projection,
  pass_projection : Render3dPassProjection,
  camera_transform : @transform.Transform,
  viewport_x : Int,
  viewport_y : Int,
  viewport_width : Int,
  viewport_height : Int,
  camera_exposure_value : Float,
) -> @render.HostMesh3dPreprocessView {
  let clip_from_world = render3d_pass_projection_clip_from_world(
    pass_projection, camera_transform,
  )
  let unjittered_clip_from_world = render3d_pass_projection_unjittered_clip_from_world(
    pass_projection, camera_transform,
  )
  let view_from_world = render3d_view_from_world_matrix(camera_transform)
  let world_from_view = render3d_world_from_view_matrix(camera_transform)
  let world_from_clip = match
    render3d_projection_matrix_inverse(clip_from_world) {
    Some(value) => value
    None => render3d_projection_matrix_identity()
  }
  let view_from_clip = match
    render3d_projection_matrix_inverse(pass_projection.clip_from_view) {
    Some(value) => value
    None => render3d_projection_matrix_identity()
  }
  @render.HostMesh3dPreprocessView::{
    clip_from_world: render3d_host_gpu_clip_matrix(clip_from_world),
    unjittered_clip_from_world: render3d_host_gpu_clip_matrix(
      unjittered_clip_from_world,
    ),
    world_from_clip: render3d_host_gpu_clip_matrix(world_from_clip),
    world_from_view: render3d_host_gpu_clip_matrix(world_from_view),
    view_from_world: render3d_host_gpu_clip_matrix(view_from_world),
    clip_from_view: render3d_host_gpu_clip_matrix(
      pass_projection.clip_from_view,
    ),
    view_from_clip: render3d_host_gpu_clip_matrix(view_from_clip),
    world_position_x: camera_transform.translation.x,
    world_position_y: camera_transform.translation.y,
    world_position_z: camera_transform.translation.z,
    exposure: camera_exposure_value,
    viewport_x: Float::from_double(viewport_x.to_double()),
    viewport_y: Float::from_double(viewport_y.to_double()),
    viewport_width: Float::from_double(viewport_width.to_double()),
    viewport_height: Float::from_double(viewport_height.to_double()),
    main_pass_viewport_x: Float::from_double(viewport_x.to_double()),
    main_pass_viewport_y: Float::from_double(viewport_y.to_double()),
    main_pass_viewport_width: Float::from_double(viewport_width.to_double()),
    main_pass_viewport_height: Float::from_double(viewport_height.to_double()),
    frustum_planes: render3d_host_preprocess_view_frustum_planes(
      projection, camera_transform,
    ),
    mip_bias: 0.0F,
  }
}

///|
fn render3d_projection_matrix_identity() -> ProjectionMatrix3d {
  ProjectionMatrix3d::from_cols(
    @math.Vec4::new(1.0F, 0.0F, 0.0F, 0.0F),
    @math.Vec4::new(0.0F, 1.0F, 0.0F, 0.0F),
    @math.Vec4::new(0.0F, 0.0F, 1.0F, 0.0F),
    @math.Vec4::new(0.0F, 0.0F, 0.0F, 1.0F),
  )
}

///|
fn render3d_host_preprocess_previous_view(
  pass_projection : Render3dPassProjection,
  previous_transform : @transform.Transform,
  previous_clip_from_world : ProjectionMatrix3d?,
) -> @render.HostMesh3dPreprocessPreviousView {
  let resolved_previous_view_from_world = render3d_view_from_world_matrix(
    previous_transform,
  )
  let resolved_previous_clip_from_world = match previous_clip_from_world {
    Some(value) => value
    None =>
      render3d_pass_projection_clip_from_world(
        pass_projection, previous_transform,
      )
  }
  let resolved_previous_world_from_clip = match
    render3d_projection_matrix_inverse(resolved_previous_clip_from_world) {
    Some(value) => value
    None => render3d_projection_matrix_identity()
  }
  let resolved_previous_world_from_view = render3d_world_from_view_matrix(
    previous_transform,
  )
  let resolved_previous_clip_from_view = resolved_previous_clip_from_world.mul(
    resolved_previous_world_from_view,
  )
  let resolved_previous_view_from_clip = match
    render3d_projection_matrix_inverse(resolved_previous_clip_from_view) {
    Some(value) => value
    None => render3d_projection_matrix_identity()
  }
  @render.HostMesh3dPreprocessPreviousView::{
    view_from_world: render3d_host_gpu_clip_matrix(
      resolved_previous_view_from_world,
    ),
    clip_from_world: render3d_host_gpu_clip_matrix(
      resolved_previous_clip_from_world,
    ),
    clip_from_view: render3d_host_gpu_clip_matrix(
      resolved_previous_clip_from_view,
    ),
    world_from_clip: render3d_host_gpu_clip_matrix(
      resolved_previous_world_from_clip,
    ),
    view_from_clip: render3d_host_gpu_clip_matrix(
      resolved_previous_view_from_clip,
    ),
  }
}

///|
fn render3d_host_preprocess_mesh_culling_data(
  draw_item : MeshPhaseItem3d,
  meshes : Array[ExtractedMesh3d],
  mesh_preprocess_static_cache : Map[Int, MeshPreprocessStatic3d],
) -> @render.HostMesh3dPreprocessMeshCullingData {
  match
    render3d_mesh_preprocess_static_for_draw_item(
      draw_item, meshes, mesh_preprocess_static_cache,
    ) {
    Some(metadata) =>
      @render.HostMesh3dPreprocessMeshCullingData::{
        aabb_center_x: metadata.aabb_center.x,
        aabb_center_y: metadata.aabb_center.y,
        aabb_center_z: metadata.aabb_center.z,
        aabb_half_extents_x: metadata.aabb_half_extents.x,
        aabb_half_extents_y: metadata.aabb_half_extents.y,
        aabb_half_extents_z: metadata.aabb_half_extents.z,
      }
    None =>
      @render.HostMesh3dPreprocessMeshCullingData::{
        aabb_center_x: 0.0F,
        aabb_center_y: 0.0F,
        aabb_center_z: 0.0F,
        aabb_half_extents_x: 0.0F,
        aabb_half_extents_y: 0.0F,
        aabb_half_extents_z: 0.0F,
      }
  }
}

///|
fn render3d_mesh_handle_preprocess_counts(
  mesh_handle : @asset.Handle[@mesh.Mesh],
) -> (Bool, Int, Int, Int) {
  match @sprite.render_mesh_asset_get(mesh_handle) {
    Some(mesh_asset) =>
      match mesh_asset.geometry {
        @mesh.MeshGeometry::Geometry3d(geometry3d) => {
          let is_indexed = geometry3d.indices is Some(_)
          let first_vertex_index = 0
          let first_index_index = 0
          let index_count = match geometry3d.indices {
            Some(indices) => indices.length()
            None => geometry3d.positions.length()
          }
          (is_indexed, first_vertex_index, first_index_index, index_count)
        }
        _ => (false, 0, 0, 0)
      }
    None => (false, 0, 0, 0)
  }
}

///|
fn render3d_mesh_handle_local_aabb(
  mesh_handle : @asset.Handle[@mesh.Mesh],
) -> (@math.Vec3, @math.Vec3)? {
  match @sprite.render_mesh_asset_get(mesh_handle) {
    Some(mesh_asset) =>
      match mesh_asset.geometry {
        @mesh.MeshGeometry::Geometry3d(geometry3d) => {
          guard geometry3d.positions.length() > 0 else { return None }
          let mut min_x = geometry3d.positions[0].x
          let mut min_y = geometry3d.positions[0].y
          let mut min_z = geometry3d.positions[0].z
          let mut max_x = geometry3d.positions[0].x
          let mut max_y = geometry3d.positions[0].y
          let mut max_z = geometry3d.positions[0].z
          for i in 1..<geometry3d.positions.length() {
            let p = geometry3d.positions[i]
            min_x = minf(min_x, p.x)
            min_y = minf(min_y, p.y)
            min_z = minf(min_z, p.z)
            max_x = maxf(max_x, p.x)
            max_y = maxf(max_y, p.y)
            max_z = maxf(max_z, p.z)
          }
          Some(
            (
              @math.Vec3::new(min_x, min_y, min_z),
              @math.Vec3::new(max_x, max_y, max_z),
            ),
          )
        }
        _ => None
      }
    None => None
  }
}

///|
fn render3d_mesh_preprocess_static(
  mesh_handle : @asset.Handle[@mesh.Mesh],
) -> MeshPreprocessStatic3d {
  let (is_indexed, first_vertex_index, first_index_index, index_count) = render3d_mesh_handle_preprocess_counts(
    mesh_handle,
  )
  let (has_local_aabb, aabb_center, aabb_half_extents) = match
    render3d_mesh_handle_local_aabb(mesh_handle) {
    Some((min_corner, max_corner)) =>
      (
        true,
        @math.Vec3::new(
          (min_corner.x + max_corner.x) * 0.5F,
          (min_corner.y + max_corner.y) * 0.5F,
          (min_corner.z + max_corner.z) * 0.5F,
        ),
        @math.Vec3::new(
          (max_corner.x - min_corner.x) * 0.5F,
          (max_corner.y - min_corner.y) * 0.5F,
          (max_corner.z - min_corner.z) * 0.5F,
        ),
      )
    None =>
      (
        false,
        @math.Vec3::new(0.0F, 0.0F, 0.0F),
        @math.Vec3::new(0.0F, 0.0F, 0.0F),
      )
  }
  MeshPreprocessStatic3d::{
    is_indexed,
    first_vertex_index,
    first_index_index,
    index_count,
    has_local_aabb,
    aabb_center,
    aabb_half_extents,
  }
}

///|
fn render3d_update_mesh_preprocess_static_cache(
  cache : Map[Int, MeshPreprocessStatic3d],
  meshes : Array[ExtractedMesh3d],
) -> Unit {
  for mesh in meshes {
    let mesh_handle_id = mesh.payload.mesh_handle.id()
    if mesh_handle_id < 0 {
      continue
    }
    if cache.get(mesh_handle_id) is Some(_) {
      continue
    }
    cache.set(
      mesh_handle_id,
      render3d_mesh_preprocess_static(mesh.payload.mesh_handle),
    )
  }
}

///|
fn render3d_mesh_preprocess_static_for_draw_item(
  draw_item : MeshPhaseItem3d,
  meshes : Array[ExtractedMesh3d],
  mesh_preprocess_static_cache : Map[Int, MeshPreprocessStatic3d],
) -> MeshPreprocessStatic3d? {
  if draw_item.extracted_index < 0 ||
    draw_item.extracted_index >= meshes.length() {
    return None
  }
  let mesh_handle = meshes[draw_item.extracted_index].payload.mesh_handle
  let mesh_handle_id = mesh_handle.id()
  if mesh_handle_id < 0 {
    return None
  }
  match mesh_preprocess_static_cache.get(mesh_handle_id) {
    Some(metadata) => Some(metadata)
    None => Some(render3d_mesh_preprocess_static(mesh_handle))
  }
}

///|
fn render3d_mesh_handle_is_indexed_cached(
  mesh_handle : @asset.Handle[@mesh.Mesh],
  mesh_preprocess_static_cache : Map[Int, MeshPreprocessStatic3d],
) -> Bool {
  let mesh_handle_id = mesh_handle.id()
  if mesh_handle_id < 0 {
    return false
  }
  match mesh_preprocess_static_cache.get(mesh_handle_id) {
    Some(metadata) => metadata.is_indexed
    None => {
      let metadata = render3d_mesh_preprocess_static(mesh_handle)
      mesh_preprocess_static_cache.set(mesh_handle_id, metadata)
      metadata.is_indexed
    }
  }
}

///|
fn render3d_host_gpu_clip_matrix(
  matrix : ProjectionMatrix3d,
) -> @render.HostGpuClipMatrix {
  @render.host_gpu_clip_matrix(
    matrix.x_axis.x,
    matrix.x_axis.y,
    matrix.x_axis.z,
    matrix.x_axis.w,
    matrix.y_axis.x,
    matrix.y_axis.y,
    matrix.y_axis.z,
    matrix.y_axis.w,
    matrix.z_axis.x,
    matrix.z_axis.y,
    matrix.z_axis.z,
    matrix.z_axis.w,
    matrix.w_axis.x,
    matrix.w_axis.y,
    matrix.w_axis.z,
    matrix.w_axis.w,
  )
}

///|
fn render3d_world_from_view_matrix(
  transform : @transform.Transform,
) -> ProjectionMatrix3d {
  let x_axis = quat_rotate_vec3(
    transform.rotation,
    @math.Vec3::new(transform.scale.x, 0.0F, 0.0F),
  )
  let y_axis = quat_rotate_vec3(
    transform.rotation,
    @math.Vec3::new(0.0F, transform.scale.y, 0.0F),
  )
  let z_axis = quat_rotate_vec3(
    transform.rotation,
    @math.Vec3::new(0.0F, 0.0F, transform.scale.z),
  )
  ProjectionMatrix3d::from_cols(
    @math.Vec4::new(x_axis.x, x_axis.y, x_axis.z, 0.0F),
    @math.Vec4::new(y_axis.x, y_axis.y, y_axis.z, 0.0F),
    @math.Vec4::new(z_axis.x, z_axis.y, z_axis.z, 0.0F),
    @math.Vec4::new(
      transform.translation.x,
      transform.translation.y,
      transform.translation.z,
      1.0F,
    ),
  )
}

///|
fn render3d_host_preprocess_mesh_input(
  draw_item : MeshPhaseItem3d,
  meshes : Array[ExtractedMesh3d],
  mesh_preprocess_static_cache : Map[Int, MeshPreprocessStatic3d],
) -> @render.HostMesh3dPreprocessMeshInput {
  if draw_item.extracted_index < 0 ||
    draw_item.extracted_index >= meshes.length() {
    return @render.HostMesh3dPreprocessMeshInput::{
      translation_x: 0.0F,
      translation_y: 0.0F,
      translation_z: 0.0F,
      rotation_x: 0.0F,
      rotation_y: 0.0F,
      rotation_z: 0.0F,
      rotation_w: 1.0F,
      scale_x: 1.0F,
      scale_y: 1.0F,
      scale_z: 1.0F,
      previous_translation_x: 0.0F,
      previous_translation_y: 0.0F,
      previous_translation_z: 0.0F,
      previous_rotation_x: 0.0F,
      previous_rotation_y: 0.0F,
      previous_rotation_z: 0.0F,
      previous_rotation_w: 1.0F,
      previous_scale_x: 1.0F,
      previous_scale_y: 1.0F,
      previous_scale_z: 1.0F,
      flags: 0U,
      first_vertex_index: 0,
      first_index_index: 0,
      index_count: 0,
      tag: 0,
    }
  }
  let mesh = meshes[draw_item.extracted_index].payload
  let metadata = match
    render3d_mesh_preprocess_static_for_draw_item(
      draw_item, meshes, mesh_preprocess_static_cache,
    ) {
    Some(value) => value
    None =>
      MeshPreprocessStatic3d::{
        is_indexed: false,
        first_vertex_index: 0,
        first_index_index: 0,
        index_count: 0,
        has_local_aabb: false,
        aabb_center: @math.Vec3::new(0.0F, 0.0F, 0.0F),
        aabb_half_extents: @math.Vec3::new(0.0F, 0.0F, 0.0F),
      }
  }
  let flags = if metadata.has_local_aabb {
    0U
  } else {
    @render.MESH3D_PREPROCESS_INPUT_FLAG_NO_FRUSTUM_CULLING
  }
  @render.HostMesh3dPreprocessMeshInput::{
    translation_x: mesh.transform.translation.x,
    translation_y: mesh.transform.translation.y,
    translation_z: mesh.transform.translation.z,
    rotation_x: mesh.transform.rotation.x,
    rotation_y: mesh.transform.rotation.y,
    rotation_z: mesh.transform.rotation.z,
    rotation_w: mesh.transform.rotation.w,
    scale_x: mesh.transform.scale.x,
    scale_y: mesh.transform.scale.y,
    scale_z: mesh.transform.scale.z,
    previous_translation_x: mesh.previous_transform.translation.x,
    previous_translation_y: mesh.previous_transform.translation.y,
    previous_translation_z: mesh.previous_transform.translation.z,
    previous_rotation_x: mesh.previous_transform.rotation.x,
    previous_rotation_y: mesh.previous_transform.rotation.y,
    previous_rotation_z: mesh.previous_transform.rotation.z,
    previous_rotation_w: mesh.previous_transform.rotation.w,
    previous_scale_x: mesh.previous_transform.scale.x,
    previous_scale_y: mesh.previous_transform.scale.y,
    previous_scale_z: mesh.previous_transform.scale.z,
    flags,
    first_vertex_index: metadata.first_vertex_index,
    first_index_index: metadata.first_index_index,
    index_count: metadata.index_count,
    tag: draw_item.extracted_index,
  }
}

///|
fn render3d_host_preprocess_camera_payload(
  queue_entry : GpuPreprocessResolvedCameraQueueEntry3d,
  camera : Camera3dViewPayload,
  pass_projection : Render3dPassProjection,
  viewport_x : Int,
  viewport_y : Int,
  viewport_width : Int,
  viewport_height : Int,
  camera_exposure_value : Float,
) -> @render.HostMesh3dPreprocessCameraPayload {
  let view = render3d_host_preprocess_view(
    camera.projection,
    pass_projection,
    camera.transform,
    viewport_x,
    viewport_y,
    viewport_width,
    viewport_height,
    camera_exposure_value,
  )
  let previous_view = render3d_host_preprocess_previous_view(
    pass_projection,
    camera.previous_transform,
    camera.previous_clip_from_world,
  )
  let mesh_culling_data = queue_entry.mesh_culling_data
  let mesh_inputs = queue_entry.mesh_inputs
  let direct_work_items : Array[@render.HostMesh3dPreprocessShaderWorkItem] = []
  let indexed_work_items : Array[@render.HostMesh3dPreprocessShaderWorkItem] = []
  let non_indexed_work_items : Array[@render.HostMesh3dPreprocessShaderWorkItem] = []
  let late_indexed_work_items : Array[
    @render.HostMesh3dPreprocessShaderWorkItem,
  ] = []
  let late_non_indexed_work_items : Array[
    @render.HostMesh3dPreprocessShaderWorkItem,
  ] = []
  match queue_entry.work_item_buffers {
    Direct(items) =>
      for item in items {
        direct_work_items.push(render3d_host_preprocess_shader_work_item(item))
      }
    Indirect(indexed_items, non_indexed_items, gpu_occlusion_culling) => {
      for item in indexed_items {
        indexed_work_items.push(render3d_host_preprocess_shader_work_item(item))
      }
      for item in non_indexed_items {
        non_indexed_work_items.push(
          render3d_host_preprocess_shader_work_item(item),
        )
      }
      if gpu_occlusion_culling is Some(culling) {
        if culling.enabled {
          for item in indexed_items {
            late_indexed_work_items.push(
              render3d_host_preprocess_shader_work_item(item),
            )
          }
          for item in non_indexed_items {
            late_non_indexed_work_items.push(
              render3d_host_preprocess_shader_work_item(item),
            )
          }
        }
      }
    }
  }
  let indexed_cpu_metadata : Array[
    @render.HostMesh3dPreprocessIndirectParametersCpuMetadata,
  ] = []
  for
    metadata in queue_entry.indirect_metadata.indexed.indirect_parameters_cpu_metadata {
    indexed_cpu_metadata.push(render3d_host_preprocess_cpu_metadata(metadata))
  }
  let indexed_gpu_metadata : Array[
    @render.HostMesh3dPreprocessIndirectParametersGpuMetadata,
  ] = []
  for
    metadata in queue_entry.indirect_metadata.indexed.indirect_parameters_gpu_metadata {
    indexed_gpu_metadata.push(render3d_host_preprocess_gpu_metadata(metadata))
  }
  let indexed_batch_sets : Array[@render.HostMesh3dPreprocessIndirectBatchSet] = []
  for batch_set in queue_entry.indirect_metadata.indexed.indirect_batch_sets {
    indexed_batch_sets.push(render3d_host_preprocess_batch_set(batch_set))
  }
  let non_indexed_cpu_metadata : Array[
    @render.HostMesh3dPreprocessIndirectParametersCpuMetadata,
  ] = []
  for
    metadata in queue_entry.indirect_metadata.non_indexed.indirect_parameters_cpu_metadata {
    non_indexed_cpu_metadata.push(
      render3d_host_preprocess_cpu_metadata(metadata),
    )
  }
  let non_indexed_gpu_metadata : Array[
    @render.HostMesh3dPreprocessIndirectParametersGpuMetadata,
  ] = []
  for
    metadata in queue_entry.indirect_metadata.non_indexed.indirect_parameters_gpu_metadata {
    non_indexed_gpu_metadata.push(
      render3d_host_preprocess_gpu_metadata(metadata),
    )
  }
  let non_indexed_batch_sets : Array[
    @render.HostMesh3dPreprocessIndirectBatchSet,
  ] = []
  for batch_set in queue_entry.indirect_metadata.non_indexed.indirect_batch_sets {
    non_indexed_batch_sets.push(render3d_host_preprocess_batch_set(batch_set))
  }
  let dispatch_metadata = @render.HostMesh3dPreprocessDispatchMetadata::{
    direct_workgroup_count: queue_entry.dispatch_metadata.direct_workgroup_count,
    indexed_workgroup_count: queue_entry.dispatch_metadata.indexed_workgroup_count,
    non_indexed_workgroup_count: queue_entry.dispatch_metadata.non_indexed_workgroup_count,
    late_indexed_workgroup_count: queue_entry.dispatch_metadata.late_indexed_workgroup_count,
    late_non_indexed_workgroup_count: queue_entry.dispatch_metadata.late_non_indexed_workgroup_count,
  }
  @render.HostMesh3dPreprocessCameraPayload::{
    view,
    previous_view,
    mesh_culling_data,
    mesh_inputs,
    direct_work_items,
    indexed_work_items,
    non_indexed_work_items,
    late_indexed_work_items,
    late_non_indexed_work_items,
    indexed_cpu_metadata,
    indexed_gpu_metadata,
    indexed_batch_sets,
    non_indexed_cpu_metadata,
    non_indexed_gpu_metadata,
    non_indexed_batch_sets,
    dispatch_metadata,
  }
}

///|
fn render3d_gpu_preprocess_opaque_alpha_draw_item_indices(
  draw_items : Array[MeshPhaseItem3d],
  phase_ranges : Array[GpuPreprocessPhaseRange3d],
  work_item_buffers : GpuPreprocessWorkItemBuffers3d,
) -> Array[Int] {
  let opaque_alpha_end_index_raw = render3d_gpu_preprocess_opaque_alpha_end_index(
    phase_ranges,
  )
  let opaque_alpha_end_index = if opaque_alpha_end_index_raw >
    draw_items.length() {
    draw_items.length()
  } else {
    opaque_alpha_end_index_raw
  }
  let indices : Array[Int] = []
  let included : Array[Bool] = []
  for _ in draw_items {
    included.push(false)
  }
  let push_if_valid = fn(index : Int) {
    if index < 0 || index >= opaque_alpha_end_index {
      return
    }
    if draw_items[index].phase == RENDER3D_PHASE_OPAQUE ||
      draw_items[index].phase == RENDER3D_PHASE_ALPHA_MASK {
      if included[index] {
        return
      }
      included[index] = true
      indices.push(index)
    }
  }
  match work_item_buffers {
    Direct(items) =>
      for item in items {
        push_if_valid(item.output_or_indirect_parameters_index)
      }
    Indirect(indexed_items, non_indexed_items, _) => {
      for item in indexed_items {
        push_if_valid(item.input_index)
      }
      for item in non_indexed_items {
        push_if_valid(item.input_index)
      }
    }
  }
  for i in 0..<opaque_alpha_end_index {
    if draw_items[i].phase == RENDER3D_PHASE_OPAQUE ||
      draw_items[i].phase == RENDER3D_PHASE_ALPHA_MASK {
      if included[i] {
        continue
      }
      included[i] = true
      indices.push(i)
    }
  }
  indices
}

///|
fn render3d_gpu_preprocess_indirect_parameter_index_maps(
  draw_items : Array[MeshPhaseItem3d],
  work_item_buffers : GpuPreprocessWorkItemBuffers3d,
) -> (Array[Int], Array[Int]) {
  let indexed : Array[Int] = []
  let non_indexed : Array[Int] = []
  for _ in draw_items {
    indexed.push(-1)
    non_indexed.push(-1)
  }
  match work_item_buffers {
    Direct(_) => ()
    Indirect(indexed_items, non_indexed_items, _) => {
      for item in indexed_items {
        if item.input_index >= 0 && item.input_index < indexed.length() {
          indexed[item.input_index] = item.output_or_indirect_parameters_index
        }
      }
      for item in non_indexed_items {
        if item.input_index >= 0 && item.input_index < non_indexed.length() {
          non_indexed[item.input_index] = item.output_or_indirect_parameters_index
        }
      }
    }
  }
  (indexed, non_indexed)
}

///|
fn render3d_queue_mesh_phase_items_gpu_builder(
  meshes : Array[ExtractedMesh3d],
  layers : @sprite.RenderLayers,
  camera_transform : @transform.Transform,
  camera_frustum_planes : Array[@render.HostMesh3dPreprocessFrustumPlane],
  mesh_preprocess_static_cache : Map[Int, MeshPreprocessStatic3d],
) -> Array[MeshPhaseItem3d] {
  // Keep the same high-level architecture as Bevy's GPU preprocessing path:
  // collect mesh work items, then write batched instance work payloads.
  let work_items = render3d_collect_meshes_for_gpu_building(
    meshes, layers, camera_transform, camera_frustum_planes, mesh_preprocess_static_cache,
  )
  render3d_write_batched_instance_buffers(work_items)
}

///|
fn render3d_queue_mesh_phase_items(
  meshes : Array[ExtractedMesh3d],
  layers : @sprite.RenderLayers,
  camera_transform : @transform.Transform,
  camera_frustum_planes : Array[@render.HostMesh3dPreprocessFrustumPlane],
  mesh_preprocess_static_cache : Map[Int, MeshPreprocessStatic3d],
  use_gpu_instance_buffer_builder : Bool,
) -> Array[MeshPhaseItem3d] {
  if use_gpu_instance_buffer_builder {
    return render3d_queue_mesh_phase_items_gpu_builder(
      meshes, layers, camera_transform, camera_frustum_planes, mesh_preprocess_static_cache,
    )
  }
  render3d_queue_mesh_phase_items_cpu_builder(
    meshes, layers, camera_transform, camera_frustum_planes, mesh_preprocess_static_cache,
  )
}
