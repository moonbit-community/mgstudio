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
// Bevy source: `bevy/crates/bevy_material/src/specialize.rs`.

///|
pub type MaterialPipelineKey = String

///|
pub type MaterialMeshVertexLayout = Int

///|
pub suberror SpecializedMeshPipelineError {
  MissingVertexAttribute(String)
}

///|
pub type BaseSpecializeFn = (
  @ecs.World,
  MaterialPipelineKey,
  MaterialMeshVertexLayout,
) -> @render_resource.RenderPipelineId raise

///|
pub type UserSpecializeFn = (
  MaterialPipelineKey,
  MaterialMeshVertexLayout,
) -> Unit raise

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
  key : MaterialPipelineKey,
  layout : MaterialMeshVertexLayout,
) -> @render_resource.RenderPipelineId raise {
  specialize(world, key, layout)
}

///|
pub fn material_specialize_user(
  specialize : UserSpecializeFn,
  key : MaterialPipelineKey,
  layout : MaterialMeshVertexLayout,
) -> Unit raise {
  specialize(key, layout)
}
