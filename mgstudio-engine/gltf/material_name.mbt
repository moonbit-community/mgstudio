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
pub struct GltfMaterialName {
  name : String
}

///|
let gltf_material_name_component_key : @ecs.ComponentKey[GltfMaterialName] = @ecs.register_component(
  debug_name="gltf.material_name",
)

///|
pub impl @ecs.Component for GltfMaterialName with component() {
  gltf_material_name_component_key
}

///|
pub fn GltfMaterialName::new(name : String) -> GltfMaterialName {
  { name, }
}

///|
pub fn GltfMaterialName::as_str(self : GltfMaterialName) -> String {
  self.name
}
