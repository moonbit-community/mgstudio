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
test "pbr material: key encodes common standard material toggles" {
  let material = StandardMaterial::default()
    .with_base_color_texture(Some(@asset.Handle::new(1)))
    .with_emissive_texture(Some(@asset.Handle::new(2)))
    .with_normal_map_texture(Some(@asset.Handle::new(3)))
    .with_diffuse_transmission(0.4)
    .with_specular_transmission(0.2)
  let key = standard_material_key_from_material(material)
  inspect(
    key.contains(STANDARD_MATERIAL_KEY_BASE_COLOR_TEXTURE),
    content="true",
  )
  inspect(key.contains(STANDARD_MATERIAL_KEY_EMISSIVE_TEXTURE), content="true")
  inspect(key.contains(STANDARD_MATERIAL_KEY_NORMAL_MAP), content="true")
  inspect(
    key.contains(STANDARD_MATERIAL_KEY_DIFFUSE_TRANSMISSION),
    content="true",
  )
  inspect(
    key.contains(STANDARD_MATERIAL_KEY_SPECULAR_TRANSMISSION),
    content="true",
  )
}

///|
test "pbr material: key depth bias roundtrips" {
  let key = StandardMaterialKey::empty().with_depth_bias(42U)
  inspect(key.depth_bias(), content="42")
}
