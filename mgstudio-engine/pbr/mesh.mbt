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

// Core pipeline and camera settings live in `core_pipeline.mbt`.

///|
pub type AlphaMode3d = @material.AlphaMode3d

///|
pub type Face3d = @material.Face3d

///|
pub type ParallaxMappingMethod = @material.ParallaxMappingMethod

///|
pub type OpaqueRendererMethod = @material.OpaqueRendererMethod

///|
pub type DefaultOpaqueRendererMethod = @material.DefaultOpaqueRendererMethod

///|
pub type StandardMaterial = @material.StandardMaterial

///|
pub(open) trait IntoPbrMaterialAsset {
  into_pbr_material_asset(Self) -> StandardMaterial
}

///|
pub fn[S : IntoPbrMaterialAsset] add_material(
  assets : @asset.Assets[StandardMaterial],
  value : S,
) -> @asset.Handle[StandardMaterial] {
  assets.add(value.into_pbr_material_asset())
}

///|
pub impl IntoPbrMaterialAsset for StandardMaterial with into_pbr_material_asset(
  self,
) {
  self
}

///|
pub impl IntoPbrMaterialAsset for @sprite.Color with into_pbr_material_asset(
  self,
) {
  @material.StandardMaterial::from_color(self)
}

///|
pub impl IntoPbrMaterialAsset for @asset.Handle[@asset.Image] with into_pbr_material_asset(
  self,
) {
  @material.StandardMaterial::default().with_base_color_texture(Some(self))
}

///|
pub type ExtendedMaterialMetadata3d = @material.ExtendedMaterialMetadata3d

///|
pub type MeshMaterial3d = @material.MeshMaterial3d

///|
pub type ForwardDecalMaterialExt = @material.ForwardDecalMaterialExt

///|
/// Light-facing ownership lives in `Milky2018/mgstudio/light`.
pub type VolumetricLight = @light.VolumetricLight

///|
pub type VolumetricFog = @light.VolumetricFog

///|
pub type FogVolume = @light.FogVolume

///|
pub type AtmosphereMode = @light.AtmosphereMode

///|
pub type AtmosphereSettings = @light.AtmosphereSettings

///|
pub type ScatteringMedium = @light.ScatteringMedium

///|
pub type Atmosphere = @light.Atmosphere

///|
pub type AtmosphereEnvironmentMapLight = @light.AtmosphereEnvironmentMapLight

///|
pub fn standard_material_add(
  material : StandardMaterial,
) -> @asset.Handle[StandardMaterial] {
  @material.standard_material_add(material)
}

///|
pub fn standard_material_get(
  handle : @asset.Handle[StandardMaterial],
) -> StandardMaterial? {
  @material.standard_material_get(handle)
}

///|
pub fn standard_material_set(
  handle : @asset.Handle[StandardMaterial],
  material : StandardMaterial,
) -> Bool {
  @material.standard_material_set(handle, material)
}

///|
pub fn standard_material_assets_mut_or_abort() -> Ref[
  @asset.Assets[StandardMaterial],
] {
  let assets_ref : Ref[@asset.Assets[StandardMaterial]] = @asset.asset_assets_ref_mut_or_abort()
  assets_ref
}

///|
pub fn mesh_assets_mut_or_abort() -> Ref[@asset.Assets[@mesh.Mesh]] {
  @sprite.mesh_assets_mut_or_abort()
}

///|
struct Render3dInternalAssetsState {
  mut skybox_proxy_mesh : @asset.Handle[@mesh.Mesh]?
  mut tonemapping_luts : Render3dTonemappingLutHandles?
}

///|
fn Render3dInternalAssetsState::new() -> Render3dInternalAssetsState {
  Render3dInternalAssetsState::{
    skybox_proxy_mesh: None,
    tonemapping_luts: None,
  }
}

///|
fn render3d_internal_assets_ref(
  world : @ecs.World,
) -> Ref[Render3dInternalAssetsState]? {
  try! world.get_resource_ref_mut(ecs_key_internal_assets)
}

///|
fn render3d_internal_assets_ref_or_abort(
  world : @ecs.World,
) -> Ref[Render3dInternalAssetsState] {
  if render3d_internal_assets_ref(world) is None {
    world.insert_resource(
      ecs_key_internal_assets,
      Render3dInternalAssetsState::new(),
    )
  }
  match render3d_internal_assets_ref(world) {
    Some(state) => state
    None =>
      abort(
        "render3d internal assets resource is missing after lazy initialization",
      )
  }
}

///|
fn render3d_asset_server_from_world_or_abort(
  world : @ecs.World,
) -> @asset.AssetServer {
  let key : @ecs.ResourceKey[@asset.AssetServer] = @asset.asset_server_resource_key()
  if (try! world.get_resource(key)) is None {
    world.insert_resource(key, @asset.AssetServer::new())
  }
  match (try! world.get_resource(key)) {
    Some(asset_server) => asset_server
    None =>
      abort("render3d failed to initialize or acquire AssetServer resource")
  }
}

///|
fn render3d_skybox_proxy_mesh_id(world : @ecs.World) -> Int {
  let internal_assets = render3d_internal_assets_ref_or_abort(world)
  let handle = match internal_assets.val.skybox_proxy_mesh {
    Some(handle) => handle
    None => {
      let mesh = Mesh3d::new(
        mesh_assets_mut_or_abort().val.add(
          Mesh::from_3d_geometry(mesh3d_geometry_cuboid(2.0F, 2.0F, 2.0F)),
        ),
      )
      internal_assets.val.skybox_proxy_mesh = Some(mesh.mesh)
      mesh.mesh
    }
  }
  @sprite_render.render2d_upload_mesh_handle(handle)
}

///|
/// Marker component aligned with Bevy's `ForwardDecal`.
///
/// Current runtime note: projected forward-decal shading is not wired in this
/// backend yet. This component preserves scene/API parity for example
/// migration and future renderer integration.
pub struct ForwardDecal {} derive(ToJson, FromJson)

///|
pub fn ForwardDecal::default() -> ForwardDecal {
  ForwardDecal::{  }
}

///|
fn clustered_decal_tag_safe(tag : Int) -> Int {
  if tag < 0 {
    0
  } else {
    tag
  }
}

///|
/// Clustered decal parameters aligned with Bevy's `ClusteredDecal`.
///
/// The decal volume follows Bevy semantics: a transformed unit cube that
/// projects textures along local `-Z`.
///
/// Current runtime note: clustered projection is not yet active in this
/// backend; this component currently carries scene intent metadata.
pub struct ClusteredDecal {
  base_color_texture : @asset.Handle[@asset.Image]?
  normal_map_texture : @asset.Handle[@asset.Image]?
  metallic_roughness_texture : @asset.Handle[@asset.Image]?
  emissive_texture : @asset.Handle[@asset.Image]?
  tag : Int
} derive(ToJson, FromJson)

///|
pub fn ClusteredDecal::default() -> ClusteredDecal {
  ClusteredDecal::{
    base_color_texture: None,
    normal_map_texture: None,
    metallic_roughness_texture: None,
    emissive_texture: None,
    tag: 0,
  }
}

///|
pub fn ClusteredDecal::new() -> ClusteredDecal {
  ClusteredDecal::default()
}

///|
pub fn ClusteredDecal::with_base_color_texture(
  self : ClusteredDecal,
  base_color_texture : @asset.Handle[@asset.Image]?,
) -> ClusteredDecal {
  ClusteredDecal::{ ..self, base_color_texture, }
}

///|
pub fn ClusteredDecal::with_normal_map_texture(
  self : ClusteredDecal,
  normal_map_texture : @asset.Handle[@asset.Image]?,
) -> ClusteredDecal {
  ClusteredDecal::{ ..self, normal_map_texture, }
}

///|
pub fn ClusteredDecal::with_metallic_roughness_texture(
  self : ClusteredDecal,
  metallic_roughness_texture : @asset.Handle[@asset.Image]?,
) -> ClusteredDecal {
  ClusteredDecal::{ ..self, metallic_roughness_texture, }
}

///|
pub fn ClusteredDecal::with_emissive_texture(
  self : ClusteredDecal,
  emissive_texture : @asset.Handle[@asset.Image]?,
) -> ClusteredDecal {
  ClusteredDecal::{ ..self, emissive_texture, }
}

///|
pub fn ClusteredDecal::with_tag(
  self : ClusteredDecal,
  tag : Int,
) -> ClusteredDecal {
  ClusteredDecal::{ ..self, tag: clustered_decal_tag_safe(tag) }
}

///|
/// Light-facing ownership lives in `Milky2018/mgstudio/light`.
pub type PointLight = @light.PointLight

///|
pub type LightGizmoColor = @light.LightGizmoColor

///|
pub type LightGizmoConfigGroup = @light.LightGizmoConfigGroup

///|
pub type ShowLightGizmo = @light.ShowLightGizmo

///|
pub type PointLightShadowMap = @light.PointLightShadowMap

///|
pub type DirectionalLightShadowMap = @light.DirectionalLightShadowMap

///|
pub type CascadeShadowConfig = @light.CascadeShadowConfig

///|
pub type CascadeShadowConfigBuilder = @light.CascadeShadowConfigBuilder

///|
pub type DirectionalLight = @light.DirectionalLight

///|
pub type SpotLight = @light.SpotLight

///|
pub type CubemapLayout3d = @light.CubemapLayout3d

///|
pub type DirectionalLightTexture = @light.DirectionalLightTexture

///|
pub type SpotLightTexture = @light.SpotLightTexture

///|
pub type PointLightTexture = @light.PointLightTexture

///|
pub type LightProbe = @light.LightProbe

///|
pub type EnvironmentMapLight = @light.EnvironmentMapLight

///|
pub type GeneratedEnvironmentMapLight = @light.GeneratedEnvironmentMapLight

///|
pub type ParallaxCorrection = @light.ParallaxCorrection

///|
pub type IrradianceVolume = @light.IrradianceVolume

///|
pub type GlobalAmbientLight = @light.GlobalAmbientLight

///|
priv struct ProjectionRuntime3d {
  last_view_width : Float
  last_view_height : Float
}

///|
let ecs_key_projection_runtime3d : @ecs.ComponentKey[ProjectionRuntime3d] = @ecs.register_component(
  debug_name="render3d.projection_runtime3d",
)

///|
priv struct Render3dLightingState {
  ambient_color : @sprite.Color
  ambient_brightness : Float
  directional_dir : @math.Vec3
  directional_color : @sprite.Color
  directional_illuminance : Float
  point_entity : @core.Entity
  point_pos : @math.Vec3
  point_color : @sprite.Color
  point_intensity : Float
  point_range : Float
  point_shadow_maps_enabled : Bool
  point_shadow_depth_bias : Float
  point_shadow_map_near_z : Float
  spot_pos : @math.Vec3
  spot_dir : @math.Vec3
  spot_color : @sprite.Color
  spot_intensity : Float
  spot_range : Float
  spot_inner_angle : Float
  spot_outer_angle : Float
}

///|
priv struct PreparedSkinBinding3d {
  entity_generation : Int
  key_hi : Int
  key_lo : Int
}

///|
priv struct MeshPreprocessStatic3d {
  is_indexed : Bool
  first_vertex_index : Int
  first_index_index : Int
  index_count : Int
  has_local_aabb : Bool
  aabb_center : @math.Vec3
  aabb_half_extents : @math.Vec3
}

///|
priv struct GpuPreprocessPhaseRange3d {
  phase : Int
  start : Int
  end : Int
}

///|
priv struct GpuPreprocessIndirectParametersCpuMetadata3d {
  base_output_index : Int
  batch_set_index : Int
}

///|
priv struct GpuPreprocessIndirectParametersGpuMetadata3d {
  mesh_index : Int
  early_instance_count : Int
  late_instance_count : Int
}

///|
priv struct GpuPreprocessIndirectBatchSet3d {
  indirect_parameters_count : Int
  indirect_parameters_base : Int
}

///|
priv struct GpuPreprocessIndirectMeshClassMetadata3d {
  indirect_parameters_cpu_metadata : Array[
    GpuPreprocessIndirectParametersCpuMetadata3d,
  ]
  indirect_parameters_gpu_metadata : Array[
    GpuPreprocessIndirectParametersGpuMetadata3d,
  ]
  indirect_batch_sets : Array[GpuPreprocessIndirectBatchSet3d]
}

///|
priv struct GpuPreprocessIndirectMetadata3d {
  indexed : GpuPreprocessIndirectMeshClassMetadata3d
  non_indexed : GpuPreprocessIndirectMeshClassMetadata3d
}

///|
priv struct GpuPreprocessShaderWorkItem3d {
  input_index : Int
  output_or_indirect_parameters_index : Int
}

///|
priv struct GpuOcclusionCullingWorkItemBuffers3d {
  enabled : Bool
}

///|
priv enum GpuPreprocessWorkItemBuffers3d {
  Direct(Array[GpuPreprocessShaderWorkItem3d])
  Indirect(
    Array[GpuPreprocessShaderWorkItem3d],
    Array[GpuPreprocessShaderWorkItem3d],
    GpuOcclusionCullingWorkItemBuffers3d?
  )
}

///|
const RENDER3D_GPU_PREPROCESS_WORKGROUP_SIZE : Int = 64

///|
priv struct GpuPreprocessDispatchMetadata3d {
  direct_workgroup_count : Int
  indexed_workgroup_count : Int
  non_indexed_workgroup_count : Int
  late_indexed_workgroup_count : Int
  late_non_indexed_workgroup_count : Int
}

///|
priv struct GpuPreprocessResolvedCameraQueueEntry3d {
  draw_items : Array[MeshPhaseItem3d]
  phase_ranges : Array[GpuPreprocessPhaseRange3d]
  indirect_metadata : GpuPreprocessIndirectMetadata3d
  dispatch_metadata : GpuPreprocessDispatchMetadata3d
  work_item_buffers : GpuPreprocessWorkItemBuffers3d
  mesh_culling_data : Array[@render.HostMesh3dPreprocessMeshCullingData]
  mesh_inputs : Array[@render.HostMesh3dPreprocessMeshInput]
}

///|
let render3d_runtime_initialized_ref : Ref[Bool] = Ref::new(false)

///|
let render3d_diagnostic_queued_visible_mesh_count_ref : Ref[Int] = Ref::new(0)

///|
let render3d_diagnostic_prepared_camera_count_ref : Ref[Int] = Ref::new(0)

///|
let render3d_diagnostic_queue_cpu_ms_ref : Ref[Float] = Ref::new(0.0F)

///|
let render3d_diagnostic_execute_cpu_ms_ref : Ref[Float] = Ref::new(0.0F)

///|
fn render3d_ray_local_aabb_hit(
  origin : @math.Vec3,
  direction : @math.Vec3,
  min_corner : @math.Vec3,
  max_corner : @math.Vec3,
  ray_epsilon : Float,
  max_distance : Float,
) -> (Float, @math.Vec3)? {
  let mut t_min = -max_distance
  let mut t_max = max_distance
  let mut enter_normal = @math.Vec3::new(1.0F, 0.0F, 0.0F)
  let mut exit_normal = @math.Vec3::new(-1.0F, 0.0F, 0.0F)

  let axes : Array[(@math.Vec3, Float, Float, Float, Float)] = [
    (
      @math.Vec3::new(1.0F, 0.0F, 0.0F),
      origin.x,
      direction.x,
      min_corner.x,
      max_corner.x,
    ),
    (
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
      origin.y,
      direction.y,
      min_corner.y,
      max_corner.y,
    ),
    (
      @math.Vec3::new(0.0F, 0.0F, 1.0F),
      origin.z,
      direction.z,
      min_corner.z,
      max_corner.z,
    ),
  ]

  for axis_data in axes {
    let axis = axis_data.0
    let o = axis_data.1
    let d = axis_data.2
    let slab_min = axis_data.3
    let slab_max = axis_data.4
    if absf(d) <= 1.0e-9F {
      if o < slab_min || o > slab_max {
        return None
      }
      continue
    }

    let inv_d = 1.0F / d
    let mut t1 = (slab_min - o) * inv_d
    let mut t2 = (slab_max - o) * inv_d
    let mut near_normal = axis.neg()
    let mut far_normal = axis
    if t1 > t2 {
      let t_swap = t1
      t1 = t2
      t2 = t_swap
      let normal_swap = near_normal
      near_normal = far_normal
      far_normal = normal_swap
    }
    if t1 > t_min {
      t_min = t1
      enter_normal = near_normal
    }
    if t2 < t_max {
      t_max = t2
      exit_normal = far_normal
    }
    if t_min > t_max {
      return None
    }
  }

  if t_max < ray_epsilon {
    return None
  }
  let (distance, normal) = if t_min >= ray_epsilon {
    (t_min, enter_normal)
  } else {
    (t_max, exit_normal)
  }
  if distance < ray_epsilon || distance > max_distance {
    return None
  }
  Some((distance, normal))
}

///|
fn render3d_mesh_local_aabb(mesh3d : Mesh3d) -> (@math.Vec3, @math.Vec3)? {
  guard @sprite.render_mesh_asset_get(mesh3d.mesh) is Some(mesh_asset) else {
    return None
  }
  guard mesh_asset.geometry is @mesh.MeshGeometry::Geometry3d(geometry3d) else {
    return None
  }
  guard geometry3d.positions.length() > 0 else { return None }
  let mut min_x = geometry3d.positions[0].x
  let mut min_y = geometry3d.positions[0].y
  let mut min_z = geometry3d.positions[0].z
  let mut max_x = geometry3d.positions[0].x
  let mut max_y = geometry3d.positions[0].y
  let mut max_z = geometry3d.positions[0].z
  for i in 1..<geometry3d.positions.length() {
    let p = geometry3d.positions[i]
    min_x = minf(min_x, p.x)
    min_y = minf(min_y, p.y)
    min_z = minf(min_z, p.z)
    max_x = maxf(max_x, p.x)
    max_y = maxf(max_y, p.y)
    max_z = maxf(max_z, p.z)
  }
  Some(
    (@math.Vec3::new(min_x, min_y, min_z), @math.Vec3::new(max_x, max_y, max_z)),
  )
}

///|
fn render3d_mesh_local_aabb_center(mesh3d : Mesh3d) -> @math.Vec3? {
  if render3d_mesh_local_aabb(mesh3d) is Some((min_corner, max_corner)) {
    Some(
      @math.Vec3::new(
        (min_corner.x + max_corner.x) * 0.5F,
        (min_corner.y + max_corner.y) * 0.5F,
        (min_corner.z + max_corner.z) * 0.5F,
      ),
    )
  } else {
    None
  }
}

///|
fn render3d_visibility_range_visible(
  visibility_range : @visibility.VisibilityRange,
  camera_transform : @transform.Transform,
  mesh_transform : @transform.Transform,
  mesh_aabb_center_world : @math.Vec3?,
) -> Bool {
  let mesh_position = if visibility_range.use_aabb {
    match mesh_aabb_center_world {
      Some(center) => center
      None => mesh_transform.translation
    }
  } else {
    mesh_transform.translation
  }
  let to_mesh = mesh_position.sub(camera_transform.translation)
  let distance = to_mesh.length()
  let near_bound = visibility_range.start_margin_min
  let far_bound = visibility_range.end_margin_max
  if far_bound < near_bound {
    return false
  }
  distance >= near_bound && distance < far_bound
}

///|
