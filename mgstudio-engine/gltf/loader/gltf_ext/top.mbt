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
// Bevy source: `bevy/crates/bevy_gltf/src/loader/gltf_ext/mod.rs`.
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
    Scene(index) => "Scene\{index.to_string()}"
    Node(index) => "Node\{index.to_string()}"
    Mesh(index) => "Mesh\{index.to_string()}"
    Primitive(mesh, primitive) =>
      "\{GLTF_ASSET_LABEL_MESH_PREFIX}\{mesh.to_string()}\{GLTF_ASSET_LABEL_PRIMITIVE_SEGMENT}\{primitive.to_string()}"
    MorphTarget(mesh, primitive) =>
      "\{GLTF_ASSET_LABEL_MESH_PREFIX}\{mesh.to_string()}\{GLTF_ASSET_LABEL_PRIMITIVE_SEGMENT}\{primitive.to_string()}\{GLTF_ASSET_LABEL_MORPH_TARGET_SUFFIX}"
    Texture(index) => "Texture\{index.to_string()}"
    Material(index, is_scale_inverted) => {
      let inverted_suffix = if is_scale_inverted {
        GLTF_ASSET_LABEL_MATERIAL_INVERTED_SUFFIX
      } else {
        ""
      }
      "\{GLTF_ASSET_LABEL_MATERIAL_PREFIX}\{index.to_string()}\{inverted_suffix}"
    }
    DefaultMaterial => "DefaultMaterial"
    Animation(index) => "Animation\{index.to_string()}"
    Skin(index) => "Skin\{index.to_string()}"
    InverseBindMatrices(index) =>
      "\{GLTF_ASSET_LABEL_SKIN_PREFIX}\{index.to_string()}\{GLTF_ASSET_LABEL_INVERSE_BIND_MATRICES_SUFFIX}"
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
  "\{base_path}#\{self.to_label()}"
}

///|
pub struct GltfExtras {
  value : String
}

///|
let gltf_extras_component_key : @ecs.ComponentKey[GltfExtras] = @ecs.register_component(
  debug_name="gltf.extras",
)

///|
pub impl @ecs.Component for GltfExtras with component() {
  gltf_extras_component_key
}

///|
pub fn GltfExtras::new(value : String) -> GltfExtras {
  { value, }
}

///|
pub fn GltfExtras::as_str(self : GltfExtras) -> String {
  self.value
}

///|
pub struct GltfSceneExtras {
  value : String
}

///|
let gltf_scene_extras_component_key : @ecs.ComponentKey[GltfSceneExtras] = @ecs.register_component(
  debug_name="gltf.scene_extras",
)

///|
pub impl @ecs.Component for GltfSceneExtras with component() {
  gltf_scene_extras_component_key
}

///|
pub fn GltfSceneExtras::new(value : String) -> GltfSceneExtras {
  { value, }
}

///|
pub fn GltfSceneExtras::as_str(self : GltfSceneExtras) -> String {
  self.value
}

///|
pub struct GltfMeshExtras {
  value : String
}

///|
let gltf_mesh_extras_component_key : @ecs.ComponentKey[GltfMeshExtras] = @ecs.register_component(
  debug_name="gltf.mesh_extras",
)

///|
pub impl @ecs.Component for GltfMeshExtras with component() {
  gltf_mesh_extras_component_key
}

///|
pub fn GltfMeshExtras::new(value : String) -> GltfMeshExtras {
  { value, }
}

///|
pub fn GltfMeshExtras::as_str(self : GltfMeshExtras) -> String {
  self.value
}

///|
pub struct GltfMaterialExtras {
  value : String
}

///|
let gltf_material_extras_component_key : @ecs.ComponentKey[GltfMaterialExtras] = @ecs.register_component(
  debug_name="gltf.material_extras",
)

///|
pub impl @ecs.Component for GltfMaterialExtras with component() {
  gltf_material_extras_component_key
}

///|
pub fn GltfMaterialExtras::new(value : String) -> GltfMaterialExtras {
  { value, }
}

///|
pub fn GltfMaterialExtras::as_str(self : GltfMaterialExtras) -> String {
  self.value
}

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

///|
pub struct GltfSceneIndex {
  scene_index : Int
}

///|
let gltf_scene_index_component_key : @ecs.ComponentKey[GltfSceneIndex] = @ecs.register_component(
  debug_name="gltf.scene_index",
)

///|
pub impl @ecs.Component for GltfSceneIndex with component() {
  gltf_scene_index_component_key
}

///|
pub fn GltfSceneIndex::new(scene_index : Int) -> GltfSceneIndex {
  { scene_index, }
}

///|
pub fn GltfSceneIndex::index(self : GltfSceneIndex) -> Int {
  self.scene_index
}

///|
pub struct GltfNodeIndex {
  node_index : Int
}

///|
let gltf_node_index_component_key : @ecs.ComponentKey[GltfNodeIndex] = @ecs.register_component(
  debug_name="gltf.node_index",
)

///|
pub impl @ecs.Component for GltfNodeIndex with component() {
  gltf_node_index_component_key
}

///|
pub fn GltfNodeIndex::new(node_index : Int) -> GltfNodeIndex {
  { node_index, }
}

///|
pub fn GltfNodeIndex::index(self : GltfNodeIndex) -> Int {
  self.node_index
}

///|
pub struct GltfMeshIndex {
  mesh_index : Int
}

///|
let gltf_mesh_index_component_key : @ecs.ComponentKey[GltfMeshIndex] = @ecs.register_component(
  debug_name="gltf.mesh_index",
)

///|
pub impl @ecs.Component for GltfMeshIndex with component() {
  gltf_mesh_index_component_key
}

///|
pub fn GltfMeshIndex::new(mesh_index : Int) -> GltfMeshIndex {
  { mesh_index, }
}

///|
pub fn GltfMeshIndex::index(self : GltfMeshIndex) -> Int {
  self.mesh_index
}

///|
pub struct GltfPrimitiveIndex {
  mesh_index : Int
  primitive_index : Int
}

///|
let gltf_primitive_index_component_key : @ecs.ComponentKey[GltfPrimitiveIndex] = @ecs.register_component(
  debug_name="gltf.primitive_index",
)

///|
pub impl @ecs.Component for GltfPrimitiveIndex with component() {
  gltf_primitive_index_component_key
}

///|
pub fn GltfPrimitiveIndex::new(
  mesh_index : Int,
  primitive_index : Int,
) -> GltfPrimitiveIndex {
  { mesh_index, primitive_index }
}

///|
pub fn GltfPrimitiveIndex::mesh_index(self : GltfPrimitiveIndex) -> Int {
  self.mesh_index
}

///|
pub fn GltfPrimitiveIndex::primitive_index(self : GltfPrimitiveIndex) -> Int {
  self.primitive_index
}

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

///|
pub fn gltf_extras(value : String) -> GltfExtras {
  GltfExtras::new(value)
}

///|
pub fn gltf_animation_asset_label(animation_index : Int) -> GltfAssetLabel {
  GltfAssetLabel::Animation(animation_index)
}

///|
pub fn gltf_inverse_bind_matrices_asset_label(
  skin_index : Int,
) -> GltfAssetLabel {
  GltfAssetLabel::InverseBindMatrices(skin_index)
}
