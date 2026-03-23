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
  let flags = render3d_standard_material_flags(
    material, 11, 12, 13, 14, 15, 16, 17, 18,
  )
  let ok = (flags & STANDARD_MATERIAL_FLAGS_BASE_COLOR_TEXTURE_BIT) != 0U &&
    (flags & STANDARD_MATERIAL_FLAGS_EMISSIVE_TEXTURE_BIT) != 0U &&
    (flags & STANDARD_MATERIAL_FLAGS_METALLIC_ROUGHNESS_TEXTURE_BIT) != 0U &&
    (flags & STANDARD_MATERIAL_FLAGS_OCCLUSION_TEXTURE_BIT) != 0U &&
    (flags & STANDARD_MATERIAL_FLAGS_DOUBLE_SIDED_BIT) != 0U &&
    (flags & STANDARD_MATERIAL_FLAGS_UNLIT_BIT) != 0U &&
    (flags & STANDARD_MATERIAL_FLAGS_FLIP_NORMAL_MAP_Y) != 0U &&
    (flags & STANDARD_MATERIAL_FLAGS_DEPTH_MAP_BIT) != 0U &&
    (flags & STANDARD_MATERIAL_FLAGS_ANISOTROPY_TEXTURE_BIT) != 0U &&
    (flags & STANDARD_MATERIAL_FLAGS_SPECULAR_TINT_TEXTURE_BIT) != 0U &&
    (flags & (7U << 29)) == STANDARD_MATERIAL_FLAGS_ALPHA_MODE_MASK
  inspect(ok, content="true")
  inspect(
    render3d_flags_approx_eq(
      render3d_standard_material_alpha_cutoff(material.alpha_mode),
      0.37F,
    ),
    content="true",
  )
}

///|
test "render3d: standard material flags keep opaque default when maps are absent" {
  let flags = render3d_standard_material_flags(
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
  inspect(flags == STANDARD_MATERIAL_FLAGS_ALPHA_MODE_OPAQUE, content="true")
}

///|
test "render3d: normal map encoding bits stay host-minimal without bound texture" {
  let flags = render3d_standard_material_flags(
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
  inspect(
    (flags & STANDARD_MATERIAL_FLAGS_FLIP_NORMAL_MAP_Y) == 0U &&
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
      distance: 1.0F,
    },
    MeshPhaseItem3d::{
      entity: phase_entity_ref3d_for_main(@core.Entity::new(2, 0)),
      extracted_index: 1,
      phase: RENDER3D_PHASE_OPAQUE,
      distance: 2.0F,
    },
    MeshPhaseItem3d::{
      entity: phase_entity_ref3d_for_main(@core.Entity::new(3, 0)),
      extracted_index: 2,
      phase: RENDER3D_PHASE_ALPHA_MASK,
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
  inspect(
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
  inspect(
    render3d_camera_indirect_enabled(true, true, false) &&
    !render3d_camera_indirect_enabled(true, false, false) &&
    !render3d_camera_indirect_enabled(true, true, true) &&
    !render3d_camera_indirect_enabled(false, true, false),
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
    metadata.indirect_batch_sets.length() == 2 &&
    metadata.indirect_parameters_cpu_metadata[0].base_output_index == 3 &&
    metadata.indirect_parameters_cpu_metadata[0].batch_set_index == -1 &&
    metadata.indirect_parameters_cpu_metadata[1].base_output_index == 7 &&
    metadata.indirect_parameters_cpu_metadata[1].batch_set_index == -1 &&
    metadata.indirect_parameters_gpu_metadata[0].mesh_index == 3 &&
    metadata.indirect_parameters_gpu_metadata[0].early_instance_count == 0 &&
    metadata.indirect_parameters_gpu_metadata[0].late_instance_count == 0 &&
    metadata.indirect_parameters_gpu_metadata[1].mesh_index == 7 &&
    metadata.indirect_parameters_gpu_metadata[1].early_instance_count == 0 &&
    metadata.indirect_parameters_gpu_metadata[1].late_instance_count == 0 &&
    metadata.indirect_batch_sets[0].indirect_parameters_count == 0 &&
    metadata.indirect_batch_sets[0].indirect_parameters_base == 0 &&
    metadata.indirect_batch_sets[1].indirect_parameters_count == 0 &&
    metadata.indirect_batch_sets[1].indirect_parameters_base == 1
  inspect(ok, content="true")
}
