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
fn render3d_flags_approx_eq(lhs : Float, rhs : Float) -> Bool {
  let delta = lhs - rhs
  if delta < 0.0F {
    -delta < 0.0001F
  } else {
    delta < 0.0001F
  }
}

///|
test "render3d: standard material flags pack current Bevy subset bits" {
  let material = StandardMaterial::default()
    .with_unlit(true)
    .with_double_sided(true)
    .with_flip_normal_map_y(true)
    .with_alpha_mode(Mask(0.37F))
  let flags = @pbr_render.render3d_standard_material_flags(
    material, 11, 12, 13, 14, 15, 16, 17, 18,
  )
  let ok = (flags & @pbr_render.STANDARD_MATERIAL_FLAGS_BASE_COLOR_TEXTURE_BIT) !=
    0U &&
    (flags & @pbr_render.STANDARD_MATERIAL_FLAGS_EMISSIVE_TEXTURE_BIT) != 0U &&
    (flags & @pbr_render.STANDARD_MATERIAL_FLAGS_METALLIC_ROUGHNESS_TEXTURE_BIT) !=
    0U &&
    (flags & @pbr_render.STANDARD_MATERIAL_FLAGS_OCCLUSION_TEXTURE_BIT) != 0U &&
    (flags & @pbr_render.STANDARD_MATERIAL_FLAGS_DOUBLE_SIDED_BIT) != 0U &&
    (flags & @pbr_render.STANDARD_MATERIAL_FLAGS_UNLIT_BIT) != 0U &&
    (flags & @pbr_render.STANDARD_MATERIAL_FLAGS_FLIP_NORMAL_MAP_Y) != 0U &&
    (flags & @pbr_render.STANDARD_MATERIAL_FLAGS_DEPTH_MAP_BIT) != 0U &&
    (flags & @pbr_render.STANDARD_MATERIAL_FLAGS_ANISOTROPY_TEXTURE_BIT) != 0U &&
    (flags & @pbr_render.STANDARD_MATERIAL_FLAGS_SPECULAR_TINT_TEXTURE_BIT) !=
    0U &&
    (flags & (7U << 29)) == @pbr_render.STANDARD_MATERIAL_FLAGS_ALPHA_MODE_MASK
  debug_inspect(ok, content="true")
  debug_inspect(
    render3d_flags_approx_eq(
      @pbr_render.render3d_standard_material_alpha_cutoff(material.alpha_mode),
      0.37F,
    ),
    content="true",
  )
}

///|
test "render3d: forward decal specialization bit is carried into material flags" {
  let flags = @pbr_render.render3d_standard_material_flags(
    StandardMaterial::default(),
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    forward_decal=true,
  )
  debug_inspect(
    (flags & @pbr_render.STANDARD_MATERIAL_FLAGS_FORWARD_DECAL_BIT) != 0U,
    content="true",
  )
}

///|
test "render3d: standard material flags keep opaque default when maps are absent" {
  let flags = @pbr_render.render3d_standard_material_flags(
    StandardMaterial::default(),
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
  )
  debug_inspect(
    flags ==
    (
      @pbr_render.STANDARD_MATERIAL_FLAGS_ALPHA_MODE_OPAQUE |
      @pbr_render.STANDARD_MATERIAL_FLAGS_FOG_ENABLED_BIT
    ),
    content="true",
  )
}

///|
test "render3d: normal map encoding bits stay host-minimal without bound texture" {
  let flags = @pbr_render.render3d_standard_material_flags(
    StandardMaterial::default().with_flip_normal_map_y(true),
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
  )
  debug_inspect(
    (flags & @pbr_render.STANDARD_MATERIAL_FLAGS_FLIP_NORMAL_MAP_Y) == 0U &&
    (flags & (1U << 6)) == 0U,
    content="true",
  )
}

///|
test "render3d: preprocess indirect index maps preserve per-draw indexed slots" {
  let draw_items = [
    MeshPhaseItem3d::{
      entity: phase_entity_ref3d_for_main(@core.Entity::new(1, 0)),
      extracted_index: 0,
      phase: RENDER3D_PHASE_OPAQUE,
      pipeline_id: None,
      distance: 1.0F,
    },
    MeshPhaseItem3d::{
      entity: phase_entity_ref3d_for_main(@core.Entity::new(2, 0)),
      extracted_index: 1,
      phase: RENDER3D_PHASE_OPAQUE,
      pipeline_id: None,
      distance: 2.0F,
    },
    MeshPhaseItem3d::{
      entity: phase_entity_ref3d_for_main(@core.Entity::new(3, 0)),
      extracted_index: 2,
      phase: RENDER3D_PHASE_ALPHA_MASK,
      pipeline_id: None,
      distance: 3.0F,
    },
  ]
  let (indexed, non_indexed) = render3d_gpu_preprocess_indirect_parameter_index_maps(
    draw_items,
    GpuPreprocessWorkItemBuffers3d::Indirect(
      [
        GpuPreprocessShaderWorkItem3d::{
          input_index: 0,
          output_or_indirect_parameters_index: 0,
        },
        GpuPreprocessShaderWorkItem3d::{
          input_index: 2,
          output_or_indirect_parameters_index: 1,
        },
      ],
      [
        GpuPreprocessShaderWorkItem3d::{
          input_index: 1,
          output_or_indirect_parameters_index: 0,
        },
      ],
      None,
    ),
  )
  debug_inspect(
    indexed.length() == 3 &&
    non_indexed.length() == 3 &&
    indexed[0] == 0 &&
    indexed[1] == -1 &&
    indexed[2] == 1 &&
    non_indexed[0] == -1 &&
    non_indexed[1] == 0 &&
    non_indexed[2] == -1,
    content="true",
  )
}

///|
test "render3d: camera indirect path requires feature support and no marker" {
  debug_inspect(
    @pbr_render.render3d_camera_indirect_enabled(true, true, false) &&
    !@pbr_render.render3d_camera_indirect_enabled(true, false, false) &&
    !@pbr_render.render3d_camera_indirect_enabled(true, true, true) &&
    !@pbr_render.render3d_camera_indirect_enabled(false, true, false),
    content="true",
  )
}

///|
fn render3d_test_extracted_mesh_for_flags(
  has_no_frustum_culling : Bool,
  has_not_shadow_receiver : Bool,
  has_transmitted_shadow_receiver : Bool,
  scale : @math.Vec3,
) -> ExtractedMesh3d {
  let transform = @transform.Transform::identity().with_scale(scale)
  let world_from_local = @math.Affine3::from_scale_rotation_translation(
    scale,
    @math.Quat::identity(),
    @math.Vec3::zero(),
  )
  ExtractedMesh3d::{
    entity: phase_entity_ref3d_for_main(@core.Entity::new(1, 0)),
    payload: Mesh3dExtractedPayload::{
      mesh_handle: @asset.Handle::new(1),
      mesh_id: 1,
      mesh_topology_kind: 0,
      mesh_is_indexed: true,
      mesh_preprocess_static: None,
      world_from_local,
      previous_world_from_local: world_from_local,
      transform,
      previous_transform: transform,
      visibility_range: None,
      aabb: None,
      aabb_center_world: None,
      material: StandardMaterial::default(),
      material_extension: None,
      material_properties: @material.MaterialProperties::default(),
      material_vertex_shader_path: None,
      material_fragment_shader_path: None,
      material_pipeline_id: None,
      lightmap: None,
      is_forward_decal: false,
      forward_decal_material_ext: None,
      clustered_decal: None,
      has_not_shadow_caster: false,
      has_not_shadow_receiver,
      has_transmitted_shadow_receiver,
      has_no_frustum_culling,
      has_no_cpu_culling: false,
      layers: @sprite.RenderLayers::default(),
      has_wireframe: false,
      has_no_wireframe: false,
      wireframe_color: None,
      skinning_key_hi: -1,
      has_previous_skin: false,
      motion_vector_enabled: false,
    },
  }
}

///|
fn render3d_test_transparent_mesh_for_queue(
  entity_id : Int,
  z : Float,
  depth_bias : Float,
) -> ExtractedMesh3d {
  let transform = @transform.Transform::from_xyz(0.0F, 0.0F, z)
  let world_from_local = @math.Affine3::from_translation(transform.translation)
  let material = StandardMaterial::default().with_alpha_mode(
    @material.AlphaMode3d::Blend,
  )
  ExtractedMesh3d::{
    entity: phase_entity_ref3d_for_main(@core.Entity::new(entity_id, 0)),
    payload: Mesh3dExtractedPayload::{
      mesh_handle: @asset.Handle::new(entity_id),
      mesh_id: entity_id,
      mesh_topology_kind: 0,
      mesh_is_indexed: true,
      mesh_preprocess_static: None,
      world_from_local,
      previous_world_from_local: world_from_local,
      transform,
      previous_transform: transform,
      visibility_range: None,
      aabb: None,
      aabb_center_world: None,
      material,
      material_extension: None,
      material_properties: render3d_material_properties_for_standard_material(
        material,
        None,
        OpaqueRendererMethod::Forward,
        true,
      ).with_depth_bias(depth_bias),
      material_vertex_shader_path: None,
      material_fragment_shader_path: None,
      material_pipeline_id: None,
      lightmap: None,
      is_forward_decal: false,
      forward_decal_material_ext: None,
      clustered_decal: None,
      has_not_shadow_caster: false,
      has_not_shadow_receiver: false,
      has_transmitted_shadow_receiver: false,
      has_no_frustum_culling: false,
      has_no_cpu_culling: false,
      layers: @sprite.RenderLayers::default(),
      has_wireframe: false,
      has_no_wireframe: false,
      wireframe_color: None,
      skinning_key_hi: -1,
      has_previous_skin: false,
      motion_vector_enabled: false,
    },
  }
}

///|
test "render3d: transparent phase ordering includes bevy material depth bias" {
  let meshes = [
    render3d_test_transparent_mesh_for_queue(1, -1.0F, 0.0F),
    render3d_test_transparent_mesh_for_queue(2, -1.0F, 2.0F),
  ]
  let camera_transform = @transform.Transform::identity()
  let cpu_items = render3d_queue_mesh_phase_items(
    meshes,
    @sprite.RenderLayers::default(),
    camera_transform,
    [],
    false,
    false,
  )
  let gpu_items = render3d_queue_mesh_phase_items(
    meshes,
    @sprite.RenderLayers::default(),
    camera_transform,
    [],
    false,
    true,
  )
  debug_inspect(cpu_items[0].entity.main_entity.id, content="2")
  debug_inspect(cpu_items[0].distance, content="3")
  debug_inspect(gpu_items[0].entity.main_entity.id, content="2")
  debug_inspect(gpu_items[0].distance, content="3")
}

///|
test "render3d: transmissive materials use a distinct sorted phase" {
  let material = StandardMaterial::default().with_specular_transmission(0.5F)
  let transform = @transform.Transform::from_xyz(0.0F, 0.0F, -1.0F)
  let world_from_local = @math.Affine3::from_translation(transform.translation)
  let mesh = ExtractedMesh3d::{
    entity: phase_entity_ref3d_for_main(@core.Entity::new(3, 0)),
    payload: Mesh3dExtractedPayload::{
      mesh_handle: @asset.Handle::new(3),
      mesh_id: 3,
      mesh_topology_kind: 0,
      mesh_is_indexed: true,
      mesh_preprocess_static: None,
      world_from_local,
      previous_world_from_local: world_from_local,
      transform,
      previous_transform: transform,
      visibility_range: None,
      aabb: None,
      aabb_center_world: None,
      material,
      material_extension: None,
      material_properties: render3d_material_properties_for_standard_material(
        material,
        None,
        OpaqueRendererMethod::Forward,
        true,
      ),
      material_vertex_shader_path: None,
      material_fragment_shader_path: None,
      material_pipeline_id: None,
      lightmap: None,
      is_forward_decal: false,
      forward_decal_material_ext: None,
      clustered_decal: None,
      has_not_shadow_caster: false,
      has_not_shadow_receiver: false,
      has_transmitted_shadow_receiver: false,
      has_no_frustum_culling: false,
      has_no_cpu_culling: false,
      layers: @sprite.RenderLayers::default(),
      has_wireframe: false,
      has_no_wireframe: false,
      wireframe_color: None,
      skinning_key_hi: -1,
      has_previous_skin: false,
      motion_vector_enabled: false,
    },
  }
  let items = render3d_queue_mesh_phase_items(
    [mesh],
    @sprite.RenderLayers::default(),
    @transform.Transform::identity(),
    [],
    false,
    false,
  )
  debug_inspect(items[0].phase, content="2")
  debug_inspect(
    items[0].phase != RENDER3D_PHASE_OPAQUE &&
    items[0].phase != RENDER3D_PHASE_ALPHA_MASK,
    content="true",
  )
}

///|
test "render3d: standard material pipeline key includes render mesh topology" {
  let line_key = @mesh.BaseMeshPipelineKey::from_primitive_topology(
    @mesh.Mesh3dPrimitiveTopology::LineList,
  )
  let render_mesh = @render_mesh.RenderMesh::new(
    vertex_count=2,
    key_bits=line_key,
  )
  let pipeline_key = material_pipeline_key_for_standard_material_render_mesh(
    @material.MaterialProperties::default(),
    render_mesh,
  )
  let mesh_key_bits = pipeline_key.mesh_key().downcast_u64("MeshPipelineKey")
  debug_inspect(
    (mesh_key_bits & line_key.bits()) == line_key.bits(),
    content="true",
  )
}

///|
test "render3d: mesh flags default to shadow receiver and positive determinant" {
  let flags = render3d_mesh_flags(
    render3d_test_extracted_mesh_for_flags(
      false,
      false,
      false,
      @math.Vec3::splat(1.0F),
    ),
  )
  debug_inspect(
    flags ==
    (
      RENDER3D_MESH_FLAGS_LOD_INDEX_NONE |
      RENDER3D_MESH_FLAGS_SHADOW_RECEIVER |
      RENDER3D_MESH_FLAGS_SIGN_DETERMINANT_MODEL_3X3
    ),
    content="true",
  )
}

///|
test "render3d: mesh flags honor culling, receiver, transmission, and determinant bits" {
  let flags = render3d_mesh_flags(
    render3d_test_extracted_mesh_for_flags(
      true,
      true,
      true,
      @math.Vec3::new(-1.0F, 1.0F, 1.0F),
    ),
  )
  debug_inspect(
    flags ==
    (
      RENDER3D_MESH_FLAGS_LOD_INDEX_NONE |
      RENDER3D_MESH_FLAGS_NO_FRUSTUM_CULLING |
      RENDER3D_MESH_FLAGS_TRANSMITTED_SHADOW_RECEIVER
    ),
    content="true",
  )
}

///|
test "render3d: indirect metadata starts visible counts at zero" {
  let metadata = render3d_build_gpu_preprocess_indirect_mesh_class_metadata([
    GpuPreprocessShaderWorkItem3d::{
      input_index: 3,
      output_or_indirect_parameters_index: 0,
    },
    GpuPreprocessShaderWorkItem3d::{
      input_index: 7,
      output_or_indirect_parameters_index: 1,
    },
  ])
  let ok = metadata.indirect_parameters_gpu_metadata.length() == 2 &&
    metadata.indirect_parameters_cpu_metadata.length() == 2 &&
    metadata.indirect_batch_sets.length() == 1 &&
    metadata.indirect_parameters_cpu_metadata[0].base_output_index == 3 &&
    metadata.indirect_parameters_cpu_metadata[0].batch_set_index == 0 &&
    metadata.indirect_parameters_cpu_metadata[1].base_output_index == 7 &&
    metadata.indirect_parameters_cpu_metadata[1].batch_set_index == 0 &&
    metadata.indirect_parameters_gpu_metadata[0].mesh_index == 3 &&
    metadata.indirect_parameters_gpu_metadata[0].early_instance_count == 0 &&
    metadata.indirect_parameters_gpu_metadata[0].late_instance_count == 0 &&
    metadata.indirect_parameters_gpu_metadata[1].mesh_index == 7 &&
    metadata.indirect_parameters_gpu_metadata[1].early_instance_count == 0 &&
    metadata.indirect_parameters_gpu_metadata[1].late_instance_count == 0 &&
    metadata.indirect_batch_sets[0].indirect_parameters_count == 0 &&
    metadata.indirect_batch_sets[0].indirect_parameters_base == 0
  debug_inspect(ok, content="true")
}
