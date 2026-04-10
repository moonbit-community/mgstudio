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
// Bevy source: `bevy/crates/bevy_math/src/sampling/mesh_sampling.rs`.
// Bridge surface to current `Milky2018/mgstudio/math` runtime owner.

///|
pub type UniformMeshSampler = @math.UniformMeshSampler

///|
pub type UniformMeshSamplerError = @math.UniformMeshSamplerError

///|
pub const MATH_MESH_SAMPLING_MODULE_TAG : String = "bevy_math::sampling::mesh_sampling"

///|
pub fn uniform_mesh_sampler_identity(
  sampler : UniformMeshSampler,
) -> UniformMeshSampler {
  sampler
}

///|
pub fn uniform_mesh_sampler_error_identity(
  error : UniformMeshSamplerError,
) -> UniformMeshSamplerError {
  error
}
