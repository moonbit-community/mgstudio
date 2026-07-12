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
test "pbr/render mesh bindings: prepare phase builds bevy mesh bind group families" {
  let groups = render3d_prepare_mesh_bind_groups_for_phase(
    [
      RenderMeshBindingInput3d::new(7, skinned=false, morph_targets=true),
      RenderMeshBindingInput3d::new(9, skinned=true, morph_targets=true),
      RenderMeshBindingInput3d::new(11, skinned=true, morph_targets=false),
    ],
    morph_weights_available=true,
    lightmap_slab_count=2,
  )
  inspect(groups.has_model_only(), content="true")
  inspect(groups.has_skinned(), content="true")
  inspect(groups.morph_target_count(), content="2")
  inspect(groups.lightmap_count(), content="2")
  let cpu_groups = MeshBindGroups3d::CpuPreprocessing(groups)
  debug_inspect(
    cpu_groups is MeshBindGroups3d::CpuPreprocessing(_),
    content="true",
  )
  let gpu_map : Map[String, MeshPhaseBindGroups3d] = Map([])
  gpu_map.set("Opaque3d", groups)
  let gpu_groups = MeshBindGroups3d::GpuPreprocessing(gpu_map)
  debug_inspect(
    gpu_groups is MeshBindGroups3d::GpuPreprocessing(_),
    content="true",
  )
  let morphed = groups.get(7, None, false, true, false).unwrap()
  inspect(morphed.label(), content="morphed_mesh_bind_group")
  inspect(morphed.layout_name(), content="morphed_mesh_layout")
  inspect(
    morphed.has_slot(MeshBindingSlot3d::MorphWeightsCurrent),
    content="true",
  )
  inspect(morphed.has_slot(MeshBindingSlot3d::MorphTargets), content="true")
  let morphed_skinned_motion = groups.get(9, None, true, true, true).unwrap()
  inspect(
    morphed_skinned_motion.label(),
    content="morphed_skinned_motion_mesh_bind_group",
  )
  inspect(
    morphed_skinned_motion.layout_name(),
    content="morphed_skinned_motion_mesh_layout",
  )
  inspect(morphed_skinned_motion.binding_count(), content="7")
  let bindings = morphed_skinned_motion.bindings()
  inspect(bindings[0].1, content="0")
  inspect(bindings[1].1, content="1")
  inspect(bindings[2].1, content="2")
  inspect(bindings[3].1, content="3")
  inspect(bindings[4].1, content="8")
  inspect(bindings[5].1, content="6")
  inspect(bindings[6].1, content="7")
}

///|
test "pbr/render mesh bindings: selection mirrors bevy morph skin lightmap priority" {
  let groups = render3d_prepare_mesh_bind_groups_for_phase(
    [RenderMeshBindingInput3d::new(7, skinned=true, morph_targets=true)],
    morph_weights_available=true,
    lightmap_slab_count=1,
  )
  let morphed = groups.get(7, Some(0), true, true, false).unwrap()
  inspect(morphed.label(), content="morphed_skinned_mesh_bind_group")
  let skinned = groups.get(99, Some(0), true, false, true).unwrap()
  inspect(skinned.label(), content="skinned_motion_mesh_bind_group")
  let lightmapped = groups.get(99, Some(0), false, false, false).unwrap()
  inspect(lightmapped.label(), content="lightmapped_mesh_bind_group")
  let model_only = groups.get(99, None, false, false, false).unwrap()
  inspect(model_only.label(), content="model_only_mesh_bind_group")
}

///|
test "pbr/render mesh bindings: bindless lightmap layouts keep bevy slab counts" {
  let default_lightmapped = render3d_mesh_layouts().select(
    skinned=false,
    morphed=false,
    lightmapped=true,
    motion_vectors=false,
  )
  inspect(
    default_lightmapped.binding_array_count(MeshBindingSlot3d::LightmapTexture),
    content="0",
  )
  inspect(
    default_lightmapped.binding_array_count(MeshBindingSlot3d::LightmapSampler),
    content="0",
  )
  let bindless_lightmapped = render3d_mesh_layouts(
    binding_arrays_are_usable=true,
  ).select(skinned=false, morphed=false, lightmapped=true, motion_vectors=false)
  inspect(
    bindless_lightmapped.binding_array_count(MeshBindingSlot3d::LightmapTexture),
    content="4",
  )
  inspect(
    bindless_lightmapped.binding_array_count(MeshBindingSlot3d::LightmapSampler),
    content="4",
  )
  inspect(bindless_lightmapped.bindings()[1].1, content="4")
}

///|
test "pbr/render mesh bindings: dynamic offsets follow SetMeshBindGroup order" {
  let offsets = render3d_mesh_bind_group_dynamic_offsets(
    phase_dynamic_offset=Some(3U),
    current_skin_byte_offset=Some(64U),
    current_morph_index=Some(128U),
    prev_morph_index=Some(256U),
    motion_vectors=true,
    skins_use_uniform_buffers=true,
  )
  debug_inspect(offsets, content="[3, 64, 128, 64, 256]")
  let storage_skin_offsets = render3d_mesh_bind_group_dynamic_offsets(
    current_skin_byte_offset=Some(64U),
    current_morph_index=Some(128U),
    motion_vectors=true,
    skins_use_uniform_buffers=false,
  )
  debug_inspect(storage_skin_offsets, content="[]")
}
