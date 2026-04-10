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
// Bevy source: `bevy/crates/bevy_mesh/src/primitives/dim3/torus.rs`.
// Bridge surface to current `Milky2018/mgstudio/math` runtime owner.

///|
pub fn torus(major_radius : Float, minor_radius : Float) -> @math.Torus {
  @math.Torus::new(major_radius, minor_radius)
}

///|
pub const MESH_TORUS_MODULE_TAG : String = "bevy_mesh::primitives::dim3::torus"

///|
pub fn torus_unit() -> @math.Torus {
  torus(1.0, 0.3)
}

///|
pub fn torus_module_tag() -> String {
  MESH_TORUS_MODULE_TAG
}
