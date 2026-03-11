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
pub(all) enum GltfAssetLabel {
  Scene(Int)
  Node(Int)
  Mesh(Int)
  Primitive(Int, Int)
  MorphTarget(Int, Int)
  Texture(Int)
  Material(Int, Bool)
  DefaultMaterial
  Animation(Int)
  Skin(Int)
  InverseBindMatrices(Int)
}

///|
const GLTF_ASSET_LABEL_MESH_PREFIX : String = "Mesh"

///|
const GLTF_ASSET_LABEL_PRIMITIVE_SEGMENT : String = "/Primitive"

///|
const GLTF_ASSET_LABEL_MORPH_TARGET_SUFFIX : String = "/MorphTargets"

///|
const GLTF_ASSET_LABEL_MATERIAL_PREFIX : String = "Material"

///|
const GLTF_ASSET_LABEL_MATERIAL_INVERTED_SUFFIX : String = " (inverted)"

///|
const GLTF_ASSET_LABEL_SKIN_PREFIX : String = "Skin"

///|
const GLTF_ASSET_LABEL_INVERSE_BIND_MATRICES_SUFFIX : String = "/InverseBindMatrices"

///|
pub fn GltfAssetLabel::to_label(self : GltfAssetLabel) -> String {
  match self {
    Scene(index) => "Scene" + index.to_string()
    Node(index) => "Node" + index.to_string()
    Mesh(index) => "Mesh" + index.to_string()
    Primitive(mesh, primitive) =>
      GLTF_ASSET_LABEL_MESH_PREFIX +
      mesh.to_string() +
      GLTF_ASSET_LABEL_PRIMITIVE_SEGMENT +
      primitive.to_string()
    MorphTarget(mesh, primitive) =>
      GLTF_ASSET_LABEL_MESH_PREFIX +
      mesh.to_string() +
      GLTF_ASSET_LABEL_PRIMITIVE_SEGMENT +
      primitive.to_string() +
      GLTF_ASSET_LABEL_MORPH_TARGET_SUFFIX
    Texture(index) => "Texture" + index.to_string()
    Material(index, is_scale_inverted) => {
      let inverted_suffix = if is_scale_inverted {
        GLTF_ASSET_LABEL_MATERIAL_INVERTED_SUFFIX
      } else {
        ""
      }
      GLTF_ASSET_LABEL_MATERIAL_PREFIX + index.to_string() + inverted_suffix
    }
    DefaultMaterial => "DefaultMaterial"
    Animation(index) => "Animation" + index.to_string()
    Skin(index) => "Skin" + index.to_string()
    InverseBindMatrices(index) =>
      GLTF_ASSET_LABEL_SKIN_PREFIX +
      index.to_string() +
      GLTF_ASSET_LABEL_INVERSE_BIND_MATRICES_SUFFIX
  }
}

///|
pub fn GltfAssetLabel::from_asset(
  self : GltfAssetLabel,
  asset_path : String,
) -> String {
  let base_path = if asset_path.rev_find("#") is Some(index) {
    asset_path[0:index].to_string()
  } else {
    asset_path
  }
  base_path + "#" + self.to_label()
}
