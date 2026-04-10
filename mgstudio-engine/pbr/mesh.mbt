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
type ProjectionRuntime3d = @pbr_render.ProjectionRuntime3d

///|
let ecs_key_projection_runtime3d : @ecs.ComponentKey[ProjectionRuntime3d] = @pbr_render.ecs_key_projection_runtime3d

///|
type Render3dLightingState = @pbr_render.Render3dLightingState

///|
type MeshPreprocessStatic3d = @pbr_render.MeshPreprocessStatic3d

///|
type GpuPreprocessPhaseRange3d = @pbr_render.GpuPreprocessPhaseRange3d

///|
type GpuPreprocessIndirectParametersCpuMetadata3d = @pbr_render.GpuPreprocessIndirectParametersCpuMetadata3d

///|
type GpuPreprocessIndirectParametersGpuMetadata3d = @pbr_render.GpuPreprocessIndirectParametersGpuMetadata3d

///|
type GpuPreprocessIndirectBatchSet3d = @pbr_render.GpuPreprocessIndirectBatchSet3d

///|
type GpuPreprocessIndirectMeshClassMetadata3d = @pbr_render.GpuPreprocessIndirectMeshClassMetadata3d

///|
type GpuPreprocessIndirectMetadata3d = @pbr_render.GpuPreprocessIndirectMetadata3d

///|
type GpuPreprocessShaderWorkItem3d = @pbr_render.GpuPreprocessShaderWorkItem3d

///|
type GpuOcclusionCullingWorkItemBuffers3d = @pbr_render.GpuOcclusionCullingWorkItemBuffers3d

///|
type GpuPreprocessWorkItemBuffers3d = @pbr_render.GpuPreprocessWorkItemBuffers3d

///|
const RENDER3D_GPU_PREPROCESS_WORKGROUP_SIZE : Int = @pbr_render.RENDER3D_GPU_PREPROCESS_WORKGROUP_SIZE

///|
type GpuPreprocessDispatchMetadata3d = @pbr_render.GpuPreprocessDispatchMetadata3d

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
let render3d_runtime_initialized_ref : Ref[Bool] = @pbr_render.render3d_runtime_initialized_ref

///|
let render3d_diagnostic_queued_visible_mesh_count_ref : Ref[Int] = @pbr_render.render3d_diagnostic_queued_visible_mesh_count_ref

///|
let render3d_diagnostic_prepared_camera_count_ref : Ref[Int] = @pbr_render.render3d_diagnostic_prepared_camera_count_ref

///|
let render3d_diagnostic_queue_cpu_ms_ref : Ref[Float] = @pbr_render.render3d_diagnostic_queue_cpu_ms_ref

///|
let render3d_diagnostic_execute_cpu_ms_ref : Ref[Float] = @pbr_render.render3d_diagnostic_execute_cpu_ms_ref

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
    if @pbr_render.absf(d) <= 1.0e-9F {
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
    min_x = @pbr_render.minf(min_x, p.x)
    min_y = @pbr_render.minf(min_y, p.y)
    min_z = @pbr_render.minf(min_z, p.z)
    max_x = @pbr_render.maxf(max_x, p.x)
    max_y = @pbr_render.maxf(max_y, p.y)
    max_z = @pbr_render.maxf(max_z, p.z)
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
