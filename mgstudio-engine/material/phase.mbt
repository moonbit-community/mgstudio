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
// Bevy source: `bevy/crates/bevy_material/src/phase.rs`.

///|
pub(all) enum RenderPhaseType {
  Opaque
  AlphaMask
  Transmissive
  Transparent
}

///|
pub fn RenderPhaseType::default() -> RenderPhaseType {
  RenderPhaseType::Opaque
}

///|
pub impl Default for RenderPhaseType with default() {
  RenderPhaseType::default()
}

///|
pub type MaterialRenderPhaseType = RenderPhaseType

///|
pub type MaterialMesh3dComponent = MeshMaterial3d

///|
pub type MaterialForwardDecalExt = ForwardDecalMaterialExt

///|
pub let ecs_key_material_mesh3d : @ecs.ComponentKey[MaterialMesh3dComponent] = ecs_key_mesh_material3d

///|
pub let ecs_key_material_forward_decal_ext : @ecs.ComponentKey[
  MaterialForwardDecalExt,
] = ecs_key_forward_decal_material_ext
