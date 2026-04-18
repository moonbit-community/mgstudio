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
// Bevy source: `bevy/crates/bevy_material/src/specialize.rs`.

///|
pub type MaterialMeshVertexLayout = Int

///|
pub suberror SpecializedMeshPipelineError {
  MissingVertexAttribute(String)
}

///|
pub type BaseSpecializeFn = (
  @ecs.World,
  ErasedMaterialPipelineKey,
  MaterialMeshVertexLayout,
  MaterialProperties,
) -> CachedRenderPipelineId raise SpecializedMeshPipelineError

///|
pub type PrepassSpecializeFn = (
  @ecs.World,
  ErasedMaterialPipelineKey,
  MaterialMeshVertexLayout,
  MaterialProperties,
) -> CachedRenderPipelineId raise SpecializedMeshPipelineError

///|
pub type UserSpecializeFn = (
  String,
  RenderPipelineDescriptor,
  MaterialMeshVertexLayout,
  ErasedMaterialPipelineKey,
) -> RenderPipelineDescriptor raise SpecializedMeshPipelineError

///|
pub fn missing_vertex_attribute_error(
  attribute : String,
) -> SpecializedMeshPipelineError {
  MissingVertexAttribute(attribute)
}

///|
pub fn material_specialize_base(
  specialize : BaseSpecializeFn,
  world : @ecs.World,
  key : ErasedMaterialPipelineKey,
  layout : MaterialMeshVertexLayout,
  properties : MaterialProperties,
) -> CachedRenderPipelineId raise {
  specialize(world, key, layout, properties)
}

///|
pub fn material_specialize_prepass(
  specialize : PrepassSpecializeFn,
  world : @ecs.World,
  key : ErasedMaterialPipelineKey,
  layout : MaterialMeshVertexLayout,
  properties : MaterialProperties,
) -> CachedRenderPipelineId raise {
  specialize(world, key, layout, properties)
}

///|
pub fn material_specialize_user(
  specialize : UserSpecializeFn,
  user_key : String,
  descriptor : RenderPipelineDescriptor,
  layout : MaterialMeshVertexLayout,
  key : ErasedMaterialPipelineKey,
) -> RenderPipelineDescriptor raise {
  specialize(user_key, descriptor, layout, key)
}
