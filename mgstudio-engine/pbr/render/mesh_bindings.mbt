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
pub const RENDER3D_MORPH_WEIGHT_SIZE_BYTES : Int = 4

///|
pub const RENDER3D_MAX_MORPH_WEIGHTS : Int = 64

///|
pub const RENDER3D_MORPH_BUFFER_SIZE_BYTES : Int = RENDER3D_MAX_MORPH_WEIGHTS *
  RENDER3D_MORPH_WEIGHT_SIZE_BYTES

///|
pub const RENDER3D_JOINT_MATRIX_SIZE_BYTES : Int = 64

///|
pub const RENDER3D_MAX_SKIN_JOINTS : Int = 256

///|
pub const RENDER3D_JOINT_BUFFER_SIZE_BYTES : Int = RENDER3D_MAX_SKIN_JOINTS *
  RENDER3D_JOINT_MATRIX_SIZE_BYTES

///|
pub const RENDER3D_LIGHTMAPS_PER_SLAB : Int = 4

///|
pub enum MeshBindingSlot3d {
  Model
  SkinCurrent
  MorphWeightsCurrent
  MorphTargets
  LightmapTexture
  LightmapSampler
  SkinPrevious
  MorphWeightsPrevious
  MorphDescriptors
} derive(Eq, ToJson, FromJson)

///|
pub fn mesh_binding_slot_index(slot : MeshBindingSlot3d) -> Int {
  match slot {
    Model => 0
    SkinCurrent => 1
    MorphWeightsCurrent => 2
    MorphTargets => 3
    LightmapTexture => 4
    LightmapSampler => 5
    SkinPrevious => 6
    MorphWeightsPrevious => 7
    MorphDescriptors => 8
  }
}

///|
pub struct MeshBindingLayoutEntry3d {
  slot : MeshBindingSlot3d
  binding : Int
  count : Int
}

///|
pub struct MeshBindingLayout3d {
  name : String
  entries : Array[MeshBindingLayoutEntry3d]
}

///|
pub struct MeshLayouts3d {
  model_only : MeshBindingLayout3d
  lightmapped : MeshBindingLayout3d
  skinned : MeshBindingLayout3d
  skinned_motion : MeshBindingLayout3d
  morphed : MeshBindingLayout3d
  morphed_motion : MeshBindingLayout3d
  morphed_skinned : MeshBindingLayout3d
  morphed_skinned_motion : MeshBindingLayout3d
}

///|
pub fn MeshBindingLayout3d::name(self : MeshBindingLayout3d) -> String {
  self.name
}

///|
pub fn MeshBindingLayoutEntry3d::new(
  slot : MeshBindingSlot3d,
  binding : Int,
  count? : Int = 0,
) -> MeshBindingLayoutEntry3d {
  { slot, binding, count }
}

///|
pub fn MeshBindingLayoutEntry3d::slot(
  self : MeshBindingLayoutEntry3d,
) -> MeshBindingSlot3d {
  self.slot
}

///|
pub fn MeshBindingLayoutEntry3d::binding(
  self : MeshBindingLayoutEntry3d,
) -> Int {
  self.binding
}

///|
pub fn MeshBindingLayoutEntry3d::count(self : MeshBindingLayoutEntry3d) -> Int {
  self.count
}

///|
pub fn MeshBindingLayout3d::entries(
  self : MeshBindingLayout3d,
) -> Array[MeshBindingLayoutEntry3d] {
  let entries : Array[MeshBindingLayoutEntry3d] = []
  for entry in self.entries {
    entries.push(entry)
  }
  entries
}

///|
pub fn MeshBindingLayout3d::bindings(
  self : MeshBindingLayout3d,
) -> Array[(MeshBindingSlot3d, Int)] {
  let bindings : Array[(MeshBindingSlot3d, Int)] = []
  for entry in self.entries {
    bindings.push((entry.slot(), entry.binding()))
  }
  bindings
}

///|
pub fn MeshBindingLayout3d::binding_array_count(
  self : MeshBindingLayout3d,
  slot : MeshBindingSlot3d,
) -> Int {
  for entry in self.entries {
    if entry.slot() == slot {
      return entry.count()
    }
  }
  0
}

///|
fn mesh_binding_layout_entry(
  slot : MeshBindingSlot3d,
  count? : Int = 0,
) -> MeshBindingLayoutEntry3d {
  MeshBindingLayoutEntry3d::new(slot, mesh_binding_slot_index(slot), count~)
}

///|
fn mesh_binding_layout_slots(
  lightmapped : Bool,
  skinned : Bool,
  morphed : Bool,
  motion_vectors : Bool,
  binding_arrays_are_usable : Bool,
) -> Array[MeshBindingLayoutEntry3d] {
  let slots : Array[MeshBindingLayoutEntry3d] = [
    mesh_binding_layout_entry(Model),
  ]
  if skinned {
    slots.push(mesh_binding_layout_entry(SkinCurrent))
  }
  if morphed {
    slots.push(mesh_binding_layout_entry(MorphWeightsCurrent))
    slots.push(mesh_binding_layout_entry(MorphTargets))
    if !skins_use_uniform_buffers() {
      slots.push(mesh_binding_layout_entry(MorphDescriptors))
    }
  }
  if skinned && motion_vectors {
    slots.push(mesh_binding_layout_entry(SkinPrevious))
  }
  if morphed && motion_vectors {
    slots.push(mesh_binding_layout_entry(MorphWeightsPrevious))
  }
  if lightmapped {
    let lightmap_count = if binding_arrays_are_usable {
      RENDER3D_LIGHTMAPS_PER_SLAB
    } else {
      0
    }
    slots.push(mesh_binding_layout_entry(LightmapTexture, count=lightmap_count))
    slots.push(mesh_binding_layout_entry(LightmapSampler, count=lightmap_count))
  }
  slots
}

///|
fn mesh_binding_layout(
  name : String,
  lightmapped : Bool,
  skinned : Bool,
  morphed : Bool,
  motion_vectors : Bool,
  binding_arrays_are_usable : Bool,
) -> MeshBindingLayout3d {
  {
    name,
    entries: mesh_binding_layout_slots(
      lightmapped, skinned, morphed, motion_vectors, binding_arrays_are_usable,
    ),
  }
}

///|
pub fn render3d_mesh_layouts(
  binding_arrays_are_usable? : Bool = false,
) -> MeshLayouts3d {
  {
    model_only: mesh_binding_layout(
      "mesh_layout", false, false, false, false, binding_arrays_are_usable,
    ),
    lightmapped: mesh_binding_layout(
      "lightmapped_mesh_layout", true, false, false, false, binding_arrays_are_usable,
    ),
    skinned: mesh_binding_layout(
      "skinned_mesh_layout", false, true, false, false, binding_arrays_are_usable,
    ),
    skinned_motion: mesh_binding_layout(
      "skinned_motion_mesh_layout", false, true, false, true, binding_arrays_are_usable,
    ),
    morphed: mesh_binding_layout(
      "morphed_mesh_layout", false, false, true, false, binding_arrays_are_usable,
    ),
    morphed_motion: mesh_binding_layout(
      "morphed_mesh_layout", false, false, true, true, binding_arrays_are_usable,
    ),
    morphed_skinned: mesh_binding_layout(
      "morphed_skinned_mesh_layout", false, true, true, false, binding_arrays_are_usable,
    ),
    morphed_skinned_motion: mesh_binding_layout(
      "morphed_skinned_motion_mesh_layout", false, true, true, true, binding_arrays_are_usable,
    ),
  }
}

///|
pub fn MeshLayouts3d::select(
  self : MeshLayouts3d,
  skinned~ : Bool,
  morphed~ : Bool,
  lightmapped~ : Bool,
  motion_vectors~ : Bool,
) -> MeshBindingLayout3d {
  match (skinned, morphed, lightmapped, motion_vectors) {
    (true, false, _, true) => self.skinned_motion
    (true, false, _, false) => self.skinned
    (true, true, _, true) => self.morphed_skinned_motion
    (true, true, _, false) => self.morphed_skinned
    (false, true, _, true) => self.morphed_motion
    (false, true, _, false) => self.morphed
    (false, false, true, _) => self.lightmapped
    (false, false, false, _) => self.model_only
  }
}

///|
pub struct RenderMeshBindingInput3d {
  mesh_asset_id : Int
  skinned : Bool
  morph_targets : Bool
}

///|
pub fn RenderMeshBindingInput3d::new(
  mesh_asset_id : Int,
  skinned? : Bool = false,
  morph_targets? : Bool = false,
) -> RenderMeshBindingInput3d {
  { mesh_asset_id, skinned, morph_targets }
}

///|
pub fn RenderMeshBindingInput3d::mesh_asset_id(
  self : RenderMeshBindingInput3d,
) -> Int {
  self.mesh_asset_id
}

///|
pub fn RenderMeshBindingInput3d::skinned(
  self : RenderMeshBindingInput3d,
) -> Bool {
  self.skinned
}

///|
pub fn RenderMeshBindingInput3d::morph_targets(
  self : RenderMeshBindingInput3d,
) -> Bool {
  self.morph_targets
}

///|
pub struct MeshPreparedBindGroup3d {
  label : String
  layout_name : String
  bindings : Array[(MeshBindingSlot3d, Int)]
}

///|
fn mesh_prepared_bind_group_3d(
  label : String,
  layout : MeshBindingLayout3d,
) -> MeshPreparedBindGroup3d {
  { label, layout_name: layout.name(), bindings: layout.bindings() }
}

///|
pub fn MeshPreparedBindGroup3d::label(self : MeshPreparedBindGroup3d) -> String {
  self.label
}

///|
pub fn MeshPreparedBindGroup3d::layout_name(
  self : MeshPreparedBindGroup3d,
) -> String {
  self.layout_name
}

///|
pub fn MeshPreparedBindGroup3d::bindings(
  self : MeshPreparedBindGroup3d,
) -> Array[(MeshBindingSlot3d, Int)] {
  let bindings : Array[(MeshBindingSlot3d, Int)] = []
  for binding in self.bindings {
    bindings.push(binding)
  }
  bindings
}

///|
pub fn MeshPreparedBindGroup3d::has_slot(
  self : MeshPreparedBindGroup3d,
  slot : MeshBindingSlot3d,
) -> Bool {
  for binding in self.bindings {
    if binding.0 == slot {
      return true
    }
  }
  false
}

///|
pub fn MeshPreparedBindGroup3d::binding_count(
  self : MeshPreparedBindGroup3d,
) -> Int {
  self.bindings.length()
}

///|
pub struct MeshBindGroupPair3d {
  motion_vectors : MeshPreparedBindGroup3d
  no_motion_vectors : MeshPreparedBindGroup3d
}

///|
fn mesh_bind_group_pair_3d(
  motion_vectors : MeshPreparedBindGroup3d,
  no_motion_vectors : MeshPreparedBindGroup3d,
) -> MeshBindGroupPair3d {
  { motion_vectors, no_motion_vectors }
}

///|
pub fn MeshBindGroupPair3d::get(
  self : MeshBindGroupPair3d,
  motion_vectors : Bool,
) -> MeshPreparedBindGroup3d {
  if motion_vectors {
    self.motion_vectors
  } else {
    self.no_motion_vectors
  }
}

///|
pub struct MeshPhaseBindGroups3d {
  mut model_only : MeshPreparedBindGroup3d?
  mut skinned : MeshBindGroupPair3d?
  mut morph_targets : Map[Int, MeshBindGroupPair3d]
  mut lightmaps : Map[Int, MeshPreparedBindGroup3d]
}

///|
pub fn MeshPhaseBindGroups3d::new() -> MeshPhaseBindGroups3d {
  {
    model_only: None,
    skinned: None,
    morph_targets: Map([]),
    lightmaps: Map([]),
  }
}

///|
pub fn MeshPhaseBindGroups3d::reset(self : MeshPhaseBindGroups3d) -> Unit {
  self.model_only = None
  self.skinned = None
  self.morph_targets = Map([])
  self.lightmaps = Map([])
}

///|
pub fn MeshPhaseBindGroups3d::morph_target_count(
  self : MeshPhaseBindGroups3d,
) -> Int {
  self.morph_targets.length()
}

///|
pub fn MeshPhaseBindGroups3d::lightmap_count(
  self : MeshPhaseBindGroups3d,
) -> Int {
  self.lightmaps.length()
}

///|
pub fn MeshPhaseBindGroups3d::has_model_only(
  self : MeshPhaseBindGroups3d,
) -> Bool {
  self.model_only is Some(_)
}

///|
pub fn MeshPhaseBindGroups3d::has_skinned(self : MeshPhaseBindGroups3d) -> Bool {
  self.skinned is Some(_)
}

///|
pub fn MeshPhaseBindGroups3d::get(
  self : MeshPhaseBindGroups3d,
  mesh_asset_id : Int,
  lightmap_slab_index : Int?,
  skinned : Bool,
  morphed : Bool,
  motion_vectors : Bool,
) -> MeshPreparedBindGroup3d? {
  match (skinned, morphed, lightmap_slab_index) {
    (_, true, _) =>
      match self.morph_targets.get(mesh_asset_id) {
        Some(pair) => Some(pair.get(motion_vectors))
        None => None
      }
    (true, false, _) =>
      match self.skinned {
        Some(pair) => Some(pair.get(motion_vectors))
        None => None
      }
    (false, false, Some(lightmap_slab)) => self.lightmaps.get(lightmap_slab)
    (false, false, None) => self.model_only
  }
}

///|
pub enum MeshBindGroups3d {
  CpuPreprocessing(MeshPhaseBindGroups3d)
  GpuPreprocessing(Map[String, MeshPhaseBindGroups3d])
}

///|
pub fn render3d_mesh_bind_groups_cpu_preprocessing(
  groups : MeshPhaseBindGroups3d,
) -> MeshBindGroups3d {
  CpuPreprocessing(groups)
}

///|
pub fn render3d_mesh_bind_groups_gpu_preprocessing(
  phase_groups : Map[String, MeshPhaseBindGroups3d],
) -> MeshBindGroups3d {
  GpuPreprocessing(phase_groups)
}

///|
pub fn render3d_prepare_mesh_bind_groups_for_phase(
  meshes : Array[RenderMeshBindingInput3d],
  morph_weights_available? : Bool = false,
  lightmap_slab_count? : Int = 0,
) -> MeshPhaseBindGroups3d {
  let layouts = render3d_mesh_layouts()
  let groups = MeshPhaseBindGroups3d::new()
  groups.model_only = Some(
    mesh_prepared_bind_group_3d(
      "model_only_mesh_bind_group",
      layouts.model_only,
    ),
  )
  groups.skinned = Some(
    mesh_bind_group_pair_3d(
      mesh_prepared_bind_group_3d(
        "skinned_motion_mesh_bind_group",
        layouts.skinned_motion,
      ),
      mesh_prepared_bind_group_3d("skinned_mesh_bind_group", layouts.skinned),
    ),
  )
  if morph_weights_available {
    for mesh in meshes {
      if mesh.morph_targets {
        let pair = if mesh.skinned {
          mesh_bind_group_pair_3d(
            mesh_prepared_bind_group_3d(
              "morphed_skinned_motion_mesh_bind_group",
              layouts.morphed_skinned_motion,
            ),
            mesh_prepared_bind_group_3d(
              "morphed_skinned_mesh_bind_group",
              layouts.morphed_skinned,
            ),
          )
        } else {
          mesh_bind_group_pair_3d(
            mesh_prepared_bind_group_3d(
              "morphed_motion_mesh_bind_group",
              layouts.morphed_motion,
            ),
            mesh_prepared_bind_group_3d(
              "morphed_mesh_bind_group",
              layouts.morphed,
            ),
          )
        }
        groups.morph_targets.set(mesh.mesh_asset_id, pair)
      }
    }
  }
  for slab_index in 0..<lightmap_slab_count.max(0) {
    groups.lightmaps.set(
      slab_index,
      mesh_prepared_bind_group_3d(
        "lightmapped_mesh_bind_group",
        layouts.lightmapped,
      ),
    )
  }
  groups
}

///|
pub fn render3d_mesh_bind_group_dynamic_offsets(
  phase_dynamic_offset? : UInt? = None,
  current_skin_byte_offset? : UInt? = None,
  current_morph_index? : UInt? = None,
  prev_morph_index? : UInt? = None,
  motion_vectors? : Bool = false,
  skins_use_uniform_buffers? : Bool = true,
) -> Array[UInt] {
  let offsets : Array[UInt] = []
  match phase_dynamic_offset {
    Some(offset) => offsets.push(offset)
    None => ()
  }
  match current_skin_byte_offset {
    Some(offset) => if skins_use_uniform_buffers { offsets.push(offset) }
    None => ()
  }
  match current_morph_index {
    Some(index) => if skins_use_uniform_buffers { offsets.push(index) }
    None => ()
  }
  if motion_vectors && skins_use_uniform_buffers {
    match current_skin_byte_offset {
      Some(offset) => offsets.push(offset)
      None => ()
    }
    if current_morph_index is Some(_) {
      match prev_morph_index {
        Some(index) => offsets.push(index)
        None => offsets.push(0U)
      }
    }
  }
  offsets
}
