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
pub enum MeshBindingSlot3d {
  Model
  SkinCurrent
  MorphWeightsCurrent
  MorphTargets
  LightmapTexture
  LightmapSampler
  SkinPrevious
  MorphWeightsPrevious
} derive(Eq, ToJson, FromJson)

///|
pub fn mesh_binding_slot_index(slot : MeshBindingSlot3d) -> Int {
  match slot {
    MeshBindingSlot3d::Model => 0
    MeshBindingSlot3d::SkinCurrent => 1
    MeshBindingSlot3d::MorphWeightsCurrent => 2
    MeshBindingSlot3d::MorphTargets => 3
    MeshBindingSlot3d::LightmapTexture => 4
    MeshBindingSlot3d::LightmapSampler => 5
    MeshBindingSlot3d::SkinPrevious => 6
    MeshBindingSlot3d::MorphWeightsPrevious => 7
  }
}

///|
pub struct MeshBindingLayout3d {
  name : String
  bindings : Array[(MeshBindingSlot3d, Int)]
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
fn mesh_binding_layout_slots(
  lightmapped : Bool,
  skinned : Bool,
  morphed : Bool,
  motion_vectors : Bool,
) -> Array[(MeshBindingSlot3d, Int)] {
  let slots : Array[(MeshBindingSlot3d, Int)] = [
    (
      MeshBindingSlot3d::Model,
      mesh_binding_slot_index(MeshBindingSlot3d::Model),
    ),
  ]
  if skinned {
    slots.push(
      (
        MeshBindingSlot3d::SkinCurrent,
        mesh_binding_slot_index(MeshBindingSlot3d::SkinCurrent),
      ),
    )
    if motion_vectors {
      slots.push(
        (
          MeshBindingSlot3d::SkinPrevious,
          mesh_binding_slot_index(MeshBindingSlot3d::SkinPrevious),
        ),
      )
    }
  }
  if morphed {
    slots.push(
      (
        MeshBindingSlot3d::MorphWeightsCurrent,
        mesh_binding_slot_index(MeshBindingSlot3d::MorphWeightsCurrent),
      ),
    )
    slots.push(
      (
        MeshBindingSlot3d::MorphTargets,
        mesh_binding_slot_index(MeshBindingSlot3d::MorphTargets),
      ),
    )
    if motion_vectors {
      slots.push(
        (
          MeshBindingSlot3d::MorphWeightsPrevious,
          mesh_binding_slot_index(MeshBindingSlot3d::MorphWeightsPrevious),
        ),
      )
    }
  }
  if lightmapped {
    slots.push(
      (
        MeshBindingSlot3d::LightmapTexture,
        mesh_binding_slot_index(MeshBindingSlot3d::LightmapTexture),
      ),
    )
    slots.push(
      (
        MeshBindingSlot3d::LightmapSampler,
        mesh_binding_slot_index(MeshBindingSlot3d::LightmapSampler),
      ),
    )
  }
  slots
}

///|
fn mesh_binding_layout_name(
  lightmapped : Bool,
  skinned : Bool,
  morphed : Bool,
  motion_vectors : Bool,
) -> String {
  let mut name = "mesh_layout"
  if lightmapped {
    name = "\{name}_lightmapped"
  }
  if skinned {
    name = "\{name}_skinned"
  }
  if morphed {
    name = "\{name}_morphed"
  }
  if motion_vectors {
    name = "\{name}_motion"
  }
  name
}

///|
fn mesh_binding_layout(
  lightmapped : Bool,
  skinned : Bool,
  morphed : Bool,
  motion_vectors : Bool,
) -> MeshBindingLayout3d {
  MeshBindingLayout3d::{
    name: mesh_binding_layout_name(
      lightmapped, skinned, morphed, motion_vectors,
    ),
    bindings: mesh_binding_layout_slots(
      lightmapped, skinned, morphed, motion_vectors,
    ),
  }
}

///|
pub fn render3d_mesh_layouts() -> MeshLayouts3d {
  MeshLayouts3d::{
    model_only: mesh_binding_layout(false, false, false, false),
    lightmapped: mesh_binding_layout(true, false, false, false),
    skinned: mesh_binding_layout(false, true, false, false),
    skinned_motion: mesh_binding_layout(false, true, false, true),
    morphed: mesh_binding_layout(false, false, true, false),
    morphed_motion: mesh_binding_layout(false, false, true, true),
    morphed_skinned: mesh_binding_layout(false, true, true, false),
    morphed_skinned_motion: mesh_binding_layout(false, true, true, true),
  }
}
