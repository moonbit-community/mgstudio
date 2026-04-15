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
pub struct SceneNode3d {
  name : @ecs.Name?
  parent_node_index : Int?
  mesh : @pbr.Mesh3d?
  material : @pbr.MeshMaterial3d?
  camera : @sprite.Camera?
  camera3d : @pbr.Camera3d?
  projection : @pbr.Projection?
  directional_light : @light.DirectionalLight?
  point_light : @light.PointLight?
  spot_light : @light.SpotLight?
  gltf_scene_index : @gltf.GltfSceneIndex?
  gltf_scene_extras : @gltf.GltfSceneExtras?
  gltf_node_index : @gltf.GltfNodeIndex?
  gltf_mesh_index : @gltf.GltfMeshIndex?
  gltf_primitive_index : @gltf.GltfPrimitiveIndex?
  gltf_skin_index : @gltf.GltfSkinIndex?
  gltf_material_name : @gltf.GltfMaterialName?
  gltf_extras : @gltf.GltfExtras?
  gltf_mesh_extras : @gltf.GltfMeshExtras?
  gltf_material_extras : @gltf.GltfMaterialExtras?
  transform : @transform.Transform
  visibility_range : @visibility.VisibilityRange?
  animation_target : @animation.AnimationTargetId?
  skinned_joint_node_indices : Array[Int]?
  skinned_inverse_bindposes : @asset.Handle[@mesh.SkinnedMeshInverseBindposes]?
  skinned_mesh_bounds_policy : @gltf.GltfSkinnedMeshBoundsPolicy?
  default_morph_weights : Array[Float]?
}

///|
pub fn SceneNode3d::new(
  mesh : @pbr.Mesh3d,
  material : @pbr.MeshMaterial3d,
  transform : @transform.Transform,
  visibility_range : @visibility.VisibilityRange?,
  animation_target : @animation.AnimationTargetId?,
  parent_node_index? : Int? = None,
  name? : @ecs.Name? = None,
  gltf_scene_index? : @gltf.GltfSceneIndex? = None,
  gltf_scene_extras? : @gltf.GltfSceneExtras? = None,
  gltf_node_index? : @gltf.GltfNodeIndex? = None,
  gltf_mesh_index? : @gltf.GltfMeshIndex? = None,
  gltf_primitive_index? : @gltf.GltfPrimitiveIndex? = None,
  gltf_skin_index? : @gltf.GltfSkinIndex? = None,
  gltf_material_name? : @gltf.GltfMaterialName? = None,
  gltf_extras? : @gltf.GltfExtras? = None,
  gltf_mesh_extras? : @gltf.GltfMeshExtras? = None,
  gltf_material_extras? : @gltf.GltfMaterialExtras? = None,
  camera? : @sprite.Camera? = None,
  camera3d? : @pbr.Camera3d? = None,
  projection? : @pbr.Projection? = None,
  directional_light? : @light.DirectionalLight? = None,
  point_light? : @light.PointLight? = None,
  spot_light? : @light.SpotLight? = None,
  skinned_joint_node_indices? : Array[Int]? = None,
  skinned_inverse_bindposes? : @asset.Handle[@mesh.SkinnedMeshInverseBindposes]? = None,
  skinned_mesh_bounds_policy? : @gltf.GltfSkinnedMeshBoundsPolicy? = None,
  default_morph_weights? : Array[Float]? = None,
) -> SceneNode3d {
  SceneNode3d::{
    name,
    parent_node_index,
    mesh: Some(mesh),
    material: Some(material),
    camera,
    camera3d,
    projection,
    directional_light,
    point_light,
    spot_light,
    gltf_scene_index,
    gltf_scene_extras,
    gltf_node_index,
    gltf_mesh_index,
    gltf_primitive_index,
    gltf_skin_index,
    gltf_material_name,
    gltf_extras,
    gltf_mesh_extras,
    gltf_material_extras,
    transform,
    visibility_range,
    animation_target,
    skinned_joint_node_indices,
    skinned_inverse_bindposes,
    skinned_mesh_bounds_policy,
    default_morph_weights,
  }
}

///|
pub fn SceneNode3d::new_empty(
  transform : @transform.Transform,
  visibility_range : @visibility.VisibilityRange?,
  animation_target : @animation.AnimationTargetId?,
  parent_node_index? : Int? = None,
  name? : @ecs.Name? = None,
  gltf_scene_index? : @gltf.GltfSceneIndex? = None,
  gltf_scene_extras? : @gltf.GltfSceneExtras? = None,
  gltf_node_index? : @gltf.GltfNodeIndex? = None,
  gltf_skin_index? : @gltf.GltfSkinIndex? = None,
  gltf_extras? : @gltf.GltfExtras? = None,
  camera? : @sprite.Camera? = None,
  camera3d? : @pbr.Camera3d? = None,
  projection? : @pbr.Projection? = None,
  directional_light? : @light.DirectionalLight? = None,
  point_light? : @light.PointLight? = None,
  spot_light? : @light.SpotLight? = None,
) -> SceneNode3d {
  SceneNode3d::{
    name,
    parent_node_index,
    mesh: None,
    material: None,
    camera,
    camera3d,
    projection,
    directional_light,
    point_light,
    spot_light,
    gltf_scene_index,
    gltf_scene_extras,
    gltf_node_index,
    gltf_mesh_index: None,
    gltf_primitive_index: None,
    gltf_skin_index,
    gltf_material_name: None,
    gltf_extras,
    gltf_mesh_extras: None,
    gltf_material_extras: None,
    transform,
    visibility_range,
    animation_target,
    skinned_joint_node_indices: None,
    skinned_inverse_bindposes: None,
    skinned_mesh_bounds_policy: None,
    default_morph_weights: None,
  }
}

///|
pub struct Scene {
  nodes3d : Array[SceneNode3d]
  gltf_scene_extras : @gltf.GltfSceneExtras?
  ready : Bool
}

///|
pub fn Scene::new(nodes3d : Array[SceneNode3d]) -> Scene {
  Scene::{ nodes3d, gltf_scene_extras: None, ready: true }
}

///|
pub fn Scene::with_gltf_scene_extras(
  self : Scene,
  extras : @gltf.GltfSceneExtras?,
) -> Scene {
  Scene::{ ..self, gltf_scene_extras: extras }
}

///|
const GLTF_LOD_DEFAULT_FIRST_START_MARGIN_MIN : Float = 0.0F

///|
const GLTF_LOD_DEFAULT_FIRST_START_MARGIN_MAX : Float = 0.0F

///|
const GLTF_LOD_DEFAULT_FIRST_END_MARGIN_MIN : Float = 3.0F

///|
const GLTF_LOD_DEFAULT_FIRST_END_MARGIN_MAX : Float = 4.0F

///|
const GLTF_LOD_DEFAULT_STEP : Float = 5.0F

///|
pub struct GltfLodVisibilityPolicy {
  enabled : Bool
  first_start_margin_min : Float
  first_start_margin_max : Float
  first_end_margin_min : Float
  first_end_margin_max : Float
  step : Float
}

///|
pub fn GltfLodVisibilityPolicy::default() -> GltfLodVisibilityPolicy {
  GltfLodVisibilityPolicy::{
    enabled: true,
    first_start_margin_min: GLTF_LOD_DEFAULT_FIRST_START_MARGIN_MIN,
    first_start_margin_max: GLTF_LOD_DEFAULT_FIRST_START_MARGIN_MAX,
    first_end_margin_min: GLTF_LOD_DEFAULT_FIRST_END_MARGIN_MIN,
    first_end_margin_max: GLTF_LOD_DEFAULT_FIRST_END_MARGIN_MAX,
    step: GLTF_LOD_DEFAULT_STEP,
  }
}

///|
pub fn GltfLodVisibilityPolicy::with_enabled(
  self : GltfLodVisibilityPolicy,
  enabled : Bool,
) -> GltfLodVisibilityPolicy {
  GltfLodVisibilityPolicy::{ ..self, enabled, }
}

///|
pub fn GltfLodVisibilityPolicy::with_first_lod_range(
  self : GltfLodVisibilityPolicy,
  start_margin_min : Float,
  start_margin_max : Float,
  end_margin_min : Float,
  end_margin_max : Float,
) -> GltfLodVisibilityPolicy {
  GltfLodVisibilityPolicy::{
    ..self,
    first_start_margin_min: start_margin_min,
    first_start_margin_max: start_margin_max,
    first_end_margin_min: end_margin_min,
    first_end_margin_max: end_margin_max,
  }
}

///|
pub fn GltfLodVisibilityPolicy::with_step(
  self : GltfLodVisibilityPolicy,
  step : Float,
) -> GltfLodVisibilityPolicy {
  let safe_step = if step < 0.0F { 0.0F } else { step }
  GltfLodVisibilityPolicy::{ ..self, step: safe_step }
}

///|
fn scene_pending() -> Scene {
  Scene::{ nodes3d: [], gltf_scene_extras: None, ready: false }
}
