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
// Bevy source: `bevy/crates/bevy_mesh/src/primitives/dim3/cylinder.rs`.
// Bridge surface to current `Milky2018/mgstudio/math` runtime owner.

///|
pub fn cylinder(radius : Float, height : Float) -> @math.Cylinder {
  @math.Cylinder::new(radius, height)
}

///|
pub const MESH_CYLINDER_MODULE_TAG : String = "bevy_mesh::primitives::dim3::cylinder"

///|
pub fn cylinder_unit() -> @math.Cylinder {
  cylinder(0.5, 1.0)
}

///|
pub fn cylinder_module_tag() -> String {
  MESH_CYLINDER_MODULE_TAG
}
