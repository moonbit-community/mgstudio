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
pub struct GltfSkinIndex {
  index : Int
}

///|
pub fn GltfSkinIndex::new(index : Int) -> GltfSkinIndex {
  { index, }
}

///|
pub fn GltfSkinIndex::index(self : GltfSkinIndex) -> Int {
  self.index
}

///|
pub impl ToJson for GltfSkinIndex with to_json(self) {
  self.index.to_json()
}

///|
pub impl @json.FromJson for GltfSkinIndex with from_json(json, path) {
  GltfSkinIndex::new(@json.from_json(json, path~))
}

///|
let ecs_key_gltf_skin_index : @ecs.ComponentKey[GltfSkinIndex] = @ecs.register_component(
  debug_name="bevy_gltf::GltfSkinIndex",
)

///|
pub impl @ecs.Component for GltfSkinIndex with component() {
  ecs_key_gltf_skin_index
}
