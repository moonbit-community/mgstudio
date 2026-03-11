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
fn gltf_parse_non_negative_int(payload : String) -> Int? {
  let parsed = @strconv.parse_int(payload[:], base=10) catch { _ => -1 }
  if parsed < 0 {
    None
  } else {
    Some(parsed)
  }
}

///|
fn gltf_parse_prefixed_index(label : String, prefix : String) -> Int? {
  if !label.has_prefix(prefix) {
    return None
  }
  let suffix = label[prefix.length():label.length()].to_string()
  if suffix.length() == 0 {
    None
  } else {
    gltf_parse_non_negative_int(suffix)
  }
}

///|
fn gltf_parse_mesh_primitive_label(label : String) -> (Int, Int)? {
  if !label.has_prefix(GLTF_ASSET_LABEL_MESH_PREFIX) {
    return None
  }
  guard label.find(GLTF_ASSET_LABEL_PRIMITIVE_SEGMENT) is Some(split_index) else {
    return None
  }
  let mesh_start = GLTF_ASSET_LABEL_MESH_PREFIX.length()
  let primitive_start = split_index +
    GLTF_ASSET_LABEL_PRIMITIVE_SEGMENT.length()
  let mesh_text = label[mesh_start:split_index].to_string()
  let primitive_text = label[primitive_start:label.length()].to_string()
  if mesh_text.length() == 0 || primitive_text.length() == 0 {
    return None
  }
  guard gltf_parse_non_negative_int(mesh_text) is Some(mesh_index) else {
    return None
  }
  guard gltf_parse_non_negative_int(primitive_text) is Some(primitive_index) else {
    return None
  }
  Some((mesh_index, primitive_index))
}

///|
fn gltf_parse_material_label(label : String) -> (Int, Bool)? {
  if !label.has_prefix(GLTF_ASSET_LABEL_MATERIAL_PREFIX) {
    return None
  }
  let payload = label[GLTF_ASSET_LABEL_MATERIAL_PREFIX.length():label.length()].to_string()
  if payload.length() == 0 {
    return None
  }
  let mut is_scale_inverted = false
  let mut index_payload = payload
  if payload.has_suffix(GLTF_ASSET_LABEL_MATERIAL_INVERTED_SUFFIX) {
    let end = payload.length() -
      GLTF_ASSET_LABEL_MATERIAL_INVERTED_SUFFIX.length()
    if end <= 0 {
      return None
    }
    index_payload = payload[0:end].to_string()
    is_scale_inverted = true
  }
  guard gltf_parse_non_negative_int(index_payload) is Some(index) else {
    return None
  }
  Some((index, is_scale_inverted))
}

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
pub fn GltfAssetLabel::parse(label : String) -> GltfAssetLabel? {
  if label == "DefaultMaterial" {
    return Some(DefaultMaterial)
  }
  if label.has_suffix(GLTF_ASSET_LABEL_MORPH_TARGET_SUFFIX) {
    let end = label.length() - GLTF_ASSET_LABEL_MORPH_TARGET_SUFFIX.length()
    if end <= 0 {
      return None
    }
    let primitive_label = label[0:end].to_string()
    if gltf_parse_mesh_primitive_label(primitive_label)
      is Some((mesh, primitive)) {
      return Some(MorphTarget(mesh, primitive))
    }
    return None
  }
  if gltf_parse_mesh_primitive_label(label) is Some((mesh, primitive)) {
    return Some(Primitive(mesh, primitive))
  }
  if label.has_suffix(GLTF_ASSET_LABEL_INVERSE_BIND_MATRICES_SUFFIX) &&
    label.has_prefix(GLTF_ASSET_LABEL_SKIN_PREFIX) {
    let end = label.length() -
      GLTF_ASSET_LABEL_INVERSE_BIND_MATRICES_SUFFIX.length()
    if end <= GLTF_ASSET_LABEL_SKIN_PREFIX.length() {
      return None
    }
    let index_payload = label[GLTF_ASSET_LABEL_SKIN_PREFIX.length():end].to_string()
    if gltf_parse_non_negative_int(index_payload) is Some(index) {
      return Some(InverseBindMatrices(index))
    }
    return None
  }
  if gltf_parse_material_label(label) is Some((index, is_scale_inverted)) {
    return Some(Material(index, is_scale_inverted))
  }
  if gltf_parse_prefixed_index(label, "Scene") is Some(index) {
    return Some(Scene(index))
  }
  if gltf_parse_prefixed_index(label, "Node") is Some(index) {
    return Some(Node(index))
  }
  if gltf_parse_prefixed_index(label, "Mesh") is Some(index) {
    return Some(Mesh(index))
  }
  if gltf_parse_prefixed_index(label, "Texture") is Some(index) {
    return Some(Texture(index))
  }
  if gltf_parse_prefixed_index(label, "Animation") is Some(index) {
    return Some(Animation(index))
  }
  if gltf_parse_prefixed_index(label, "Skin") is Some(index) {
    return Some(Skin(index))
  }
  None
}

///|
pub fn gltf_split_asset_path_with_label(
  asset_path : String,
) -> (String, GltfAssetLabel?) {
  if asset_path.rev_find("#") is Some(index) {
    let base_path = asset_path[0:index].to_string()
    let label_start = index + 1
    if label_start >= asset_path.length() {
      return (base_path, None)
    }
    let label = asset_path[label_start:asset_path.length()].to_string()
    (base_path, GltfAssetLabel::parse(label))
  } else {
    (asset_path, None)
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
