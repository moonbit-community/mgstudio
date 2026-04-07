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
priv struct RenderTargetComputed3d {
  target_id : Int
  target_size : @math.IVec2
  scale_factor : Float
}

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
priv struct Render3dPhaseState {
  mut prepared_camera_order : Array[@core.Entity]
  mut camera_order_needs_refresh : Bool
  mut last_camera3d_count : Int
  mesh_upload_cache : Map[Int, Int]
  mesh_preprocess_static_cache : Map[Int, MeshPreprocessStatic3d]
  prepared_skin_bindings : Map[Int, PreparedSkinBinding3d]
  skin_joint_to_skins : Map[UInt64, Array[@core.Entity]]
  skin_joints_by_skin : Map[UInt64, Array[@core.Entity]]
  skin_joint_count_by_skin : Map[UInt64, Int]
  mut total_skin_joints : Int
  skin_upload_queue : Array[@core.Entity]
}

///|
fn Render3dPhaseState::new() -> Render3dPhaseState {
  Render3dPhaseState::{
    prepared_camera_order: [],
    camera_order_needs_refresh: true,
    last_camera3d_count: 0,
    mesh_upload_cache: {},
    mesh_preprocess_static_cache: {},
    prepared_skin_bindings: {},
    skin_joint_to_skins: {},
    skin_joints_by_skin: {},
    skin_joint_count_by_skin: {},
    total_skin_joints: 0,
    skin_upload_queue: [],
  }
}

///|
let render3d_phase_state_key : @ecs.ResourceKey[Render3dPhaseState] = @ecs.register_resource(
  debug_name="bevy_pbr::Render3dPhaseState",
)

///|
impl @app.Resource for Render3dPhaseState with resource() {
  render3d_phase_state_key
}

///|
fn ensure_render3d_phase_state_resource(world : @ecs.World) -> Unit {
  if (try! world.get_resource(Render3dPhaseState::resource())) is None {
    world.insert_resource(
      Render3dPhaseState::resource(),
      Render3dPhaseState::new(),
    )
  }
}

///|
fn render3d_phase_state_ref_or_abort(
  world : @ecs.World,
) -> Ref[Render3dPhaseState] {
  ensure_render3d_phase_state_resource(world)
  match (try! world.get_resource_ref_mut(Render3dPhaseState::resource())) {
    Some(state) => state
    None => abort("Missing Render3dPhaseState resource in render world")
  }
}

///|
fn render3d_phase_state_or_default(world : @ecs.World) -> Render3dPhaseState {
  ensure_render3d_phase_state_resource(world)
  match (try! world.get_resource(Render3dPhaseState::resource())) {
    Some(state) => state
    None => Render3dPhaseState::new()
  }
}

///|
fn cmp_int(a : Int, b : Int) -> Int {
  if a < b {
    -1
  } else if a > b {
    1
  } else {
    0
  }
}

///|
fn cmp_float(a : Float, b : Float) -> Int {
  if a < b {
    -1
  } else if a > b {
    1
  } else {
    0
  }
}

///|
fn render3d_pass_clear_enabled_for_target(
  cleared_targets : Array[Int],
  target_id : Int,
  requested : Bool,
) -> Int {
  if !requested {
    return 0
  }
  for cleared_target_id in cleared_targets {
    if cleared_target_id == target_id {
      return 0
    }
  }
  cleared_targets.push(target_id)
  1
}

///|
fn render3d_pass_viewport_for_target(
  pass_target_id : Int,
  camera_target_id : Int,
  camera_viewport_x : Int,
  camera_viewport_y : Int,
  camera_viewport_width : Int,
  camera_viewport_height : Int,
) -> (Int, Int, Int, Int) {
  if pass_target_id == camera_target_id {
    (
      camera_viewport_x, camera_viewport_y, camera_viewport_width, camera_viewport_height,
    )
  } else {
    (0, 0, camera_viewport_width, camera_viewport_height)
  }
}

///|
fn render3d_target_info(
  world : @ecs.World,
  target : @sprite.RenderTarget,
) -> RenderTargetComputed3d? {
  match target {
    @sprite.RenderTarget::Screen => {
      let width = @window.window_physical_width_for(
        world,
        @window.WindowRef::Primary,
      )
      let height = @window.window_physical_height_for(
        world,
        @window.WindowRef::Primary,
      )
      if width <= 0 || height <= 0 {
        return None
      }
      let mut scale_factor = @window.window_scale_factor_for(
        world,
        @window.WindowRef::Primary,
      )
      if scale_factor <= 0.0F {
        scale_factor = 1.0F
      }
      Some(RenderTargetComputed3d::{
        target_id: -1,
        target_size: @math.IVec2::new(width, height),
        scale_factor,
      })
    }
    @sprite.RenderTarget::Window(window_ref) => {
      guard @window.window_host_window_for_ref(world, window_ref)
        is Some(host_window) else {
        return None
      }
      let surface_target_id = @render.host_gpu_surface_target_id_for_window(
        host_window,
      )
      if surface_target_id >= 0 {
        return None
      }
      let width = @window.window_physical_width_for(world, window_ref)
      let height = @window.window_physical_height_for(world, window_ref)
      if width <= 0 || height <= 0 {
        return None
      }
      let mut scale_factor = @window.window_scale_factor_for(world, window_ref)
      if scale_factor <= 0.0F {
        scale_factor = 1.0F
      }
      Some(RenderTargetComputed3d::{
        target_id: surface_target_id,
        target_size: @math.IVec2::new(width, height),
        scale_factor,
      })
    }
    @sprite.RenderTarget::Image(handle) => {
      let width = @asset.asset_texture_width(handle)
      let height = @asset.asset_texture_height(handle)
      if width <= 0 || height <= 0 {
        return None
      }
      Some(RenderTargetComputed3d::{
        target_id: handle.id(),
        target_size: @math.IVec2::new(width, height),
        scale_factor: 1.0F,
      })
    }
  }
}

///|
fn render3d_clamp_viewport(
  viewport : @sprite.Viewport,
  target_size : @math.IVec2,
) -> @sprite.Viewport {
  let mut position_x = viewport.physical_position.x
  let mut position_y = viewport.physical_position.y
  let mut size_x = viewport.physical_size.x
  let mut size_y = viewport.physical_size.y
  if position_x < 0 {
    position_x = 0
  }
  if position_y < 0 {
    position_y = 0
  }
  if size_x < 0 {
    size_x = 0
  }
  if size_y < 0 {
    size_y = 0
  }
  let max_width = if target_size.x - position_x < 0 {
    0
  } else {
    target_size.x - position_x
  }
  let max_height = if target_size.y - position_y < 0 {
    0
  } else {
    target_size.y - position_y
  }
  if size_x > max_width {
    size_x = max_width
  }
  if size_y > max_height {
    size_y = max_height
  }
  @sprite.Viewport::new(
    @math.IVec2::new(position_x, position_y),
    @math.IVec2::new(size_x, size_y),
  ).with_depth(viewport.depth_min, viewport.depth_max)
}

///|
fn quat_rotate_vec3(q : @math.Quat, v : @math.Vec3) -> @math.Vec3 {
  let qv = @math.Vec3::new(q.x, q.y, q.z)
  let t = qv.cross(v).mul_scalar(2.0F)
  v.add(t.mul_scalar(q.w)).add(qv.cross(t))
}

///|
fn render3d_quat_inverse(q : @math.Quat) -> @math.Quat {
  let length_squared = q.x * q.x + q.y * q.y + q.z * q.z + q.w * q.w
  if length_squared <= 1.0e-8F {
    return @math.Quat::identity()
  }
  let inv = 1.0F / length_squared
  @math.Quat::new(-q.x * inv, -q.y * inv, -q.z * inv, q.w * inv)
}

///|
fn render3d_transform_forward(transform : @transform.Transform) -> @math.Vec3 {
  quat_rotate_vec3(transform.rotation, @math.Vec3::new(0.0F, 0.0F, -1.0F)).normalize_or_zero()
}

///|
fn render3d_float_clamp(
  value : Float,
  min_value : Float,
  max_value : Float,
) -> Float {
  if value < min_value {
    min_value
  } else if value > max_value {
    max_value
  } else {
    value
  }
}

///|
fn render3d_lightmap_uv_transform(uv_rect : @math.Rect) -> @transform.Affine2 {
  let size = uv_rect.size()
  @transform.Affine2::from_scale_translation(size, uv_rect.min)
}

///|
const RENDER3D_PASS_KIND_BASE_SCENE : Int = 0

///|
const RENDER3D_PASS_KIND_BASE_MOTION_VECTOR : Int = 1

///|
const RENDER3D_PASS_KIND_BASE_POINT_SHADOW : Int = 2

///|
const RENDER3D_PASS_KIND_DISABLE_POSTPROCESS_FLAG : Int = 1 << 8

///|
const RENDER3D_PASS_KIND_DISABLE_FOG_FLAG : Int = 1 << 9

///|
const RENDER3D_PASS_KIND_DISABLE_DECAL_FLAG : Int = 1 << 10

///|
const RENDER3D_MESH3D_DRAW_FLAG_DECAL : Int = 1 << 8

///|
const STANDARD_MATERIAL_FLAGS_BASE_COLOR_TEXTURE_BIT : UInt = 1U << 0

///|
const STANDARD_MATERIAL_FLAGS_EMISSIVE_TEXTURE_BIT : UInt = 1U << 1

///|
const STANDARD_MATERIAL_FLAGS_METALLIC_ROUGHNESS_TEXTURE_BIT : UInt = 1U << 2

///|
const STANDARD_MATERIAL_FLAGS_OCCLUSION_TEXTURE_BIT : UInt = 1U << 3

///|
const STANDARD_MATERIAL_FLAGS_DOUBLE_SIDED_BIT : UInt = 1U << 4

///|
const STANDARD_MATERIAL_FLAGS_UNLIT_BIT : UInt = 1U << 5

///|
const STANDARD_MATERIAL_FLAGS_FLIP_NORMAL_MAP_Y : UInt = 1U << 7

///|
const STANDARD_MATERIAL_FLAGS_DEPTH_MAP_BIT : UInt = 1U << 9

///|
const STANDARD_MATERIAL_FLAGS_ANISOTROPY_TEXTURE_BIT : UInt = 1U << 17

///|
const STANDARD_MATERIAL_FLAGS_SPECULAR_TINT_TEXTURE_BIT : UInt = 1U << 19

///|
const STANDARD_MATERIAL_FLAGS_ALPHA_MODE_OPAQUE : UInt = 0U << 29

///|
const STANDARD_MATERIAL_FLAGS_ALPHA_MODE_MASK : UInt = 1U << 29

///|
const STANDARD_MATERIAL_FLAGS_ALPHA_MODE_BLEND : UInt = 2U << 29

///|
const STANDARD_MATERIAL_FLAGS_ALPHA_MODE_PREMULTIPLIED : UInt = 3U << 29

///|
const STANDARD_MATERIAL_FLAGS_ALPHA_MODE_ADD : UInt = 4U << 29

///|
const STANDARD_MATERIAL_FLAGS_ALPHA_MODE_MULTIPLY : UInt = 5U << 29

///|
const STANDARD_MATERIAL_FLAGS_ALPHA_MODE_ALPHA_TO_COVERAGE : UInt = 6U << 29

///|
fn render3d_pass_kind_encode(
  base_kind : Int,
  postprocess_enabled : Bool,
  fog_enabled : Bool,
  decal_enabled : Bool,
) -> Int {
  let mut value = base_kind
  if !postprocess_enabled {
    value = value | RENDER3D_PASS_KIND_DISABLE_POSTPROCESS_FLAG
  }
  if !fog_enabled {
    value = value | RENDER3D_PASS_KIND_DISABLE_FOG_FLAG
  }
  if !decal_enabled {
    value = value | RENDER3D_PASS_KIND_DISABLE_DECAL_FLAG
  }
  value
}

///|
fn render3d_mesh_draw_flags(mesh : ExtractedMesh3d) -> Int {
  let mut flags = 0
  if mesh.payload.is_forward_decal || mesh.payload.clustered_decal is Some(_) {
    flags = flags | RENDER3D_MESH3D_DRAW_FLAG_DECAL
  }
  flags
}

///|
fn render3d_standard_material_alpha_mode_flags(
  alpha_mode : AlphaMode3d,
) -> UInt {
  match alpha_mode {
    Opaque => STANDARD_MATERIAL_FLAGS_ALPHA_MODE_OPAQUE
    Mask(_) => STANDARD_MATERIAL_FLAGS_ALPHA_MODE_MASK
    Blend => STANDARD_MATERIAL_FLAGS_ALPHA_MODE_BLEND
    Premultiplied => STANDARD_MATERIAL_FLAGS_ALPHA_MODE_PREMULTIPLIED
    Add => STANDARD_MATERIAL_FLAGS_ALPHA_MODE_ADD
    Multiply => STANDARD_MATERIAL_FLAGS_ALPHA_MODE_MULTIPLY
    AlphaToCoverage => STANDARD_MATERIAL_FLAGS_ALPHA_MODE_ALPHA_TO_COVERAGE
  }
}

///|
fn render3d_standard_material_alpha_cutoff(alpha_mode : AlphaMode3d) -> Float {
  match alpha_mode {
    Mask(cutoff) => cutoff
    _ => 0.5F
  }
}

///|
fn render3d_standard_material_flags(
  material : StandardMaterial,
  base_color_texture_id : Int,
  normal_texture_id : Int,
  emissive_texture_id : Int,
  metallic_roughness_texture_id : Int,
  occlusion_texture_id : Int,
  depth_texture_id : Int,
  anisotropy_texture_id : Int,
  specular_tint_texture_id : Int,
) -> UInt {
  let mut flags = render3d_standard_material_alpha_mode_flags(
    material.alpha_mode,
  )
  if base_color_texture_id >= 0 {
    flags = flags | STANDARD_MATERIAL_FLAGS_BASE_COLOR_TEXTURE_BIT
  }
  if emissive_texture_id >= 0 {
    flags = flags | STANDARD_MATERIAL_FLAGS_EMISSIVE_TEXTURE_BIT
  }
  if metallic_roughness_texture_id >= 0 {
    flags = flags | STANDARD_MATERIAL_FLAGS_METALLIC_ROUGHNESS_TEXTURE_BIT
  }
  if occlusion_texture_id >= 0 {
    flags = flags | STANDARD_MATERIAL_FLAGS_OCCLUSION_TEXTURE_BIT
  }
  if material.cull_mode is None {
    flags = flags | STANDARD_MATERIAL_FLAGS_DOUBLE_SIDED_BIT
  }
  if material.unlit {
    flags = flags | STANDARD_MATERIAL_FLAGS_UNLIT_BIT
  }
  if normal_texture_id >= 0 && material.flip_normal_map_y {
    flags = flags | STANDARD_MATERIAL_FLAGS_FLIP_NORMAL_MAP_Y
  }
  if depth_texture_id >= 0 {
    flags = flags | STANDARD_MATERIAL_FLAGS_DEPTH_MAP_BIT
  }
  if anisotropy_texture_id >= 0 {
    flags = flags | STANDARD_MATERIAL_FLAGS_ANISOTROPY_TEXTURE_BIT
  }
  if specular_tint_texture_id >= 0 {
    flags = flags | STANDARD_MATERIAL_FLAGS_SPECULAR_TINT_TEXTURE_BIT
  }
  flags
}

///|
fn render3d_decal_mode_allows_forward(mode : DecalRenderMode3d) -> Bool {
  match mode {
    Disabled => false
    ForwardOnly => true
    ClusteredOnly => false
    ForwardAndClustered => true
  }
}

///|
fn render3d_decal_mode_allows_clustered(mode : DecalRenderMode3d) -> Bool {
  match mode {
    Disabled => false
    ForwardOnly => false
    ClusteredOnly => true
    ForwardAndClustered => true
  }
}

///|
fn render3d_camera_deferred_mode(
  config : CameraDeferredConfig3d,
  default_method : OpaqueRendererMethod,
  deferred_lighting_enabled : Bool,
) -> OpaqueRendererMethod {
  if !deferred_lighting_enabled {
    return OpaqueRendererMethod::Forward
  }
  match config.mode {
    CameraDeferredMode3d::Forward => OpaqueRendererMethod::Forward
    CameraDeferredMode3d::Deferred => OpaqueRendererMethod::Deferred
    CameraDeferredMode3d::Auto =>
      match default_method {
        OpaqueRendererMethod::Forward => OpaqueRendererMethod::Forward
        OpaqueRendererMethod::Deferred => OpaqueRendererMethod::Deferred
        OpaqueRendererMethod::Auto => OpaqueRendererMethod::Forward
      }
  }
}

///|
fn render3d_apply_extended_material_metadata(
  material : StandardMaterial,
  extension : ExtendedMaterialMetadata3d?,
) -> StandardMaterial {
  guard extension is Some(extension_value) else { return material }
  let mut out = material
  if extension_value.alpha_mode_override is Some(alpha_mode_override) {
    out = out.with_alpha_mode(alpha_mode_override)
  }
  if extension_value.opaque_render_method_override
    is Some(opaque_render_method_override) {
    out = out.with_opaque_render_method(opaque_render_method_override)
  }
  out
}

///|
fn render3d_default_time_or_default(world : @ecs.World) -> @time.Time[Unit] {
  match (try! world.get_resource(@time.default_time_resource_key())) {
    Some(time) => time
    None => abort("Missing Time<Unit> resource in render3d systems")
  }
}

///|
fn render3d_runtime_config_or_default(
  world : @ecs.World,
) -> PbrPluginRuntimeConfig {
  match (try! world.get_resource(ecs_key_pbr_plugin_runtime_config)) {
    Some(config) => config
    None => pbr_plugin_runtime_config()
  }
}

///|
fn render3d_gpu_preprocess_forced_disabled() -> Bool {
  @render.host_gpu_mesh3d_preprocess_disabled()
}

///|
fn render3d_use_gpu_instance_buffer_builder(
  runtime_config : PbrPluginRuntimeConfig,
) -> Bool {
  runtime_config.use_gpu_instance_buffer_builder &&
  !render3d_gpu_preprocess_forced_disabled()
}

///|
fn render3d_gpu_culling_supported() -> Bool {
  @render.host_gpu_mesh3d_gpu_culling_supported()
}

///|
fn render3d_camera_indirect_enabled(
  use_gpu_instance_buffer_builder : Bool,
  gpu_culling_supported : Bool,
  no_indirect_drawing : Bool,
) -> Bool {
  use_gpu_instance_buffer_builder &&
  gpu_culling_supported &&
  !no_indirect_drawing
}

///|
fn minf(a : Float, b : Float) -> Float {
  if a < b {
    a
  } else {
    b
  }
}

///|
fn maxf(a : Float, b : Float) -> Float {
  if a > b {
    a
  } else {
    b
  }
}

///|
fn clamp01(value : Float) -> Float {
  if value <= 0.0F {
    0.0F
  } else if value >= 1.0F {
    1.0F
  } else {
    value
  }
}

///|
fn absf(value : Float) -> Float {
  if value < 0.0F {
    -value
  } else {
    value
  }
}

///|
fn render3d_inverse_transform_point(
  transform : @transform.Transform,
  world_point : @math.Vec3,
) -> @math.Vec3? {
  if absf(transform.scale.x) <= 1.0e-9F ||
    absf(transform.scale.y) <= 1.0e-9F ||
    absf(transform.scale.z) <= 1.0e-9F {
    return None
  }
  let translated = world_point.sub(transform.translation)
  let rotated = render3d_rotate_by_quat(
    translated,
    render3d_quat_conjugate(transform.rotation),
  )
  Some(
    @math.Vec3::new(
      rotated.x / transform.scale.x,
      rotated.y / transform.scale.y,
      rotated.z / transform.scale.z,
    ),
  )
}

///|
fn render3d_inverse_transform_direction(
  transform : @transform.Transform,
  world_direction : @math.Vec3,
) -> @math.Vec3? {
  if absf(transform.scale.x) <= 1.0e-9F ||
    absf(transform.scale.y) <= 1.0e-9F ||
    absf(transform.scale.z) <= 1.0e-9F {
    return None
  }
  let rotated = render3d_rotate_by_quat(
    world_direction,
    render3d_quat_conjugate(transform.rotation),
  )
  Some(
    @math.Vec3::new(
      rotated.x / transform.scale.x,
      rotated.y / transform.scale.y,
      rotated.z / transform.scale.z,
    ),
  )
}

///|
fn render3d_transform_local_normal(
  transform : @transform.Transform,
  local_normal : @math.Vec3,
) -> @math.Vec3 {
  if absf(transform.scale.x) <= 1.0e-9F ||
    absf(transform.scale.y) <= 1.0e-9F ||
    absf(transform.scale.z) <= 1.0e-9F {
    return render3d_rotate_by_quat(local_normal, transform.rotation).normalize_or_zero()
  }
  let scaled = @math.Vec3::new(
    local_normal.x / transform.scale.x,
    local_normal.y / transform.scale.y,
    local_normal.z / transform.scale.z,
  )
  render3d_rotate_by_quat(scaled, transform.rotation).normalize_or_zero()
}

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
pub fn render3d_extract_system(world : @ecs.World) -> Unit {
  let source_world = @render.render_source_world(world)
  let phase_state_ref = render3d_phase_state_ref_or_abort(world)
  let world_transform_cache_ref = render3d_world_transform_cache_ref()
  render3d_world_transform_cache_begin_frame(world_transform_cache_ref)
  render3d_refresh_prepared_camera_order_if_needed(
    source_world, phase_state_ref,
  )
  render3d_extract_skin_bindings(
    source_world, phase_state_ref, world_transform_cache_ref,
  )
  render3d_diagnostic_prepared_camera_count_ref.val = phase_state_ref.val.prepared_camera_order.length()
  render3d_diagnostic_queued_visible_mesh_count_ref.val = 0
}

///|
pub fn render3d_prepare_system(world : @ecs.World) -> Unit {
  let source_world = @render.render_source_world(world)
  let phase_state_ref = render3d_phase_state_ref_or_abort(world)
  let world_transform_cache_ref = render3d_world_transform_cache_ref()
  render3d_prepare_skin_bindings_upload(
    source_world, phase_state_ref, world_transform_cache_ref,
  )
}

///|
pub fn render3d_queue_system(world : @ecs.World) -> Unit {
  let queue_start = @time.host_time_now()
  let queue_trace_start_us = @app.timeline_trace_begin_span(
    @app.TimelineTraceCategory::RenderQueue,
    "queue_3d",
  )
  fn finish_queue() -> Unit {
    render3d_diagnostic_queue_cpu_ms_ref.val = (
        @time.host_time_now() - queue_start
      ) *
      1000.0F
    @app.timeline_trace_end_span(
      @app.TimelineTraceCategory::RenderQueue,
      "queue_3d",
      queue_trace_start_us,
    )
  }
  let source_world = @render.render_source_world(world)
  let phase_state_ref = render3d_phase_state_ref_or_abort(world)
  if phase_state_ref.val.prepared_camera_order.length() == 0 {
    render3d_diagnostic_queued_visible_mesh_count_ref.val = 0
    finish_queue()
    return
  }
  source_world |> ignore
  finish_queue()
}

///|
pub fn render3d_execute_system(world : @ecs.World) -> Unit {
  let execute_start = @time.host_time_now()
  let execute_trace_start_us = @app.timeline_trace_begin_span(
    @app.TimelineTraceCategory::RenderQueue,
    "execute_3d",
  )
  fn finish_execute() -> Unit {
    render3d_diagnostic_execute_cpu_ms_ref.val = (
        @time.host_time_now() - execute_start
      ) *
      1000.0F
    @app.timeline_trace_end_span(
      @app.TimelineTraceCategory::RenderQueue,
      "execute_3d",
      execute_trace_start_us,
    )
  }
  let source_world = @render.render_source_world(world)
  let phase_state_ref = render3d_phase_state_ref_or_abort(world)
  let cameras : Array[ExtractedCamera3d] = []
  let meshes : Array[ExtractedMesh3d] = []
  let projection_updates : Array[
    (@core.Entity, Projection, ProjectionRuntime3d),
  ] = []
  let projection_runtime_removals : Array[@core.Entity] = []
  let world_transform_cache_ref = render3d_world_transform_cache_ref()
  let runtime_config = render3d_runtime_config_or_default(source_world)
  let gpu_instance_buffer_builder_requested = render3d_use_gpu_instance_buffer_builder(
    runtime_config,
  )
  let prepass_enabled = standard_material_prepass_enabled(source_world)
  let deferred_lighting_enabled = runtime_config.add_default_deferred_lighting_plugin &&
    deferred_pbr_lighting_enabled(source_world)
  let gpu_culling_supported = render3d_gpu_culling_supported()
  let gpu_instance_buffer_builder_enabled = gpu_instance_buffer_builder_requested &&
    gpu_culling_supported
  @render.host_gpu_set_mesh3d_gpu_instance_builder_enabled(
    gpu_instance_buffer_builder_enabled,
  )
  let delta_seconds = render3d_default_time_or_default(source_world).delta_seconds()
  let mut default_opaque_renderer_method = if (try! source_world.get_resource(
      ecs_key_default_opaque_renderer_method,
    ))
    is Some(default_method) {
    default_method.renderer_method()
  } else {
    OpaqueRendererMethod::Forward
  }
  if !deferred_lighting_enabled &&
    default_opaque_renderer_method is OpaqueRendererMethod::Deferred {
    default_opaque_renderer_method = OpaqueRendererMethod::Forward
  }
  let point_light_shadow_map_size = if (try! source_world.get_resource(
      ecs_key_point_light_shadow_map,
    ))
    is Some(shadow_map) {
    if shadow_map.size <= 0 {
      1
    } else {
      shadow_map.size
    }
  } else {
    PointLightShadowMap::default().size
  }
  let trace_collect_cameras_start_us = @app.timeline_trace_begin_span(
    @app.TimelineTraceCategory::RenderQueue,
    "execute_3d_collect_cameras",
  )
  let mut needs_mesh_previous_transform = false
  source_world.for_each_component(ecs_key_camera3d, fn(entity, camera3d) {
    let camera = match
      (try! source_world.get_by_key(entity, @sprite.ecs_key_camera)) {
      Some(v) => v
      None => @sprite.Camera::default()
    }
    let projection_component = try! source_world.get_by_key(
      entity, ecs_key_projection,
    )
    let projection = match projection_component {
      Some(v) => v
      None => Projection::default()
    }
    let projection_changed = true
    let sub_camera_view = try! source_world.get_by_key(
      entity, ecs_key_sub_camera_view3d,
    )
    let oit_settings = try! source_world.get_by_key(
      entity, ecs_key_order_independent_transparency_settings,
    )
    let screen_space_transmission = try! source_world.get_by_key(
      entity, ecs_key_screen_space_transmission,
    )
    let bloom = try! source_world.get_by_key(entity, ecs_key_bloom)
    let tonemapping = try! source_world.get_by_key(entity, ecs_key_tonemapping)
    let deband_dither = try! source_world.get_by_key(
      entity, ecs_key_deband_dither,
    )
    let chromatic_aberration = try! source_world.get_by_key(
      entity, ecs_key_chromatic_aberration,
    )
    let custom_post_process3d = try! source_world.get_by_key(
      entity, ecs_key_custom_post_process3d,
    )
    let vignette = try! source_world.get_by_key(entity, ecs_key_vignette)
    let motion_blur = try! source_world.get_by_key(entity, ecs_key_motion_blur)
    let exposure = try! source_world.get_by_key(entity, ecs_key_exposure)
    let color_grading = try! source_world.get_by_key(
      entity, ecs_key_color_grading,
    )
    let skybox = try! source_world.get_by_key(entity, ecs_key_skybox)
    let environment_map_light = try! source_world.get_by_key(
      entity, ecs_key_environment_map_light,
    )
    let generated_environment_map_light = try! source_world.get_by_key(
      entity, ecs_key_generated_environment_map_light,
    )
    let atmosphere_environment_map_light = try! source_world.get_by_key(
      entity, ecs_key_atmosphere_environment_map_light,
    )
    let hdr_enabled = (try! source_world.get_by_key(entity, ecs_key_hdr))
      is Some(_)
    let fxaa = try! source_world.get_by_key(entity, ecs_key_fxaa)
    let temporal_jitter = try! source_world.get_by_key(
      entity, ecs_key_temporal_jitter,
    )
    let depth_prepass_enabled = prepass_enabled &&
      (try! source_world.get_by_key(entity, ecs_key_depth_prepass)) is Some(_)
    let deferred_prepass_enabled = prepass_enabled &&
      (try! source_world.get_by_key(entity, ecs_key_deferred_prepass))
      is Some(_)
    let no_indirect_drawing = (try! source_world.get_by_key(
        entity, ecs_key_no_indirect_drawing,
      ))
      is Some(_)
    let camera_indirect_enabled = render3d_camera_indirect_enabled(
      gpu_instance_buffer_builder_requested, gpu_culling_supported, no_indirect_drawing,
    )
    let gpu_occlusion_culling_enabled = depth_prepass_enabled &&
      camera_indirect_enabled &&
      (try! source_world.get_by_key(entity, ecs_key_occlusion_culling))
      is Some(_)
    let motion_vector_prepass_enabled = prepass_enabled &&
      (
        (try! source_world.get_by_key(entity, ecs_key_motion_vector_prepass))
        is Some(_) ||
        gpu_occlusion_culling_enabled
      )
    if motion_vector_prepass_enabled {
      needs_mesh_previous_transform = true
    }
    let temporal_anti_aliasing = try! source_world.get_by_key(
      entity, ecs_key_temporal_anti_aliasing,
    )
    let msaa = try! source_world.get_by_key(entity, ecs_key_msaa)
    let target = match
      (try! source_world.get_by_key(entity, @sprite.ecs_key_render_target)) {
      Some(v) => v
      None => @sprite.RenderTarget::Screen
    }
    let layers = match
      (try! source_world.get_by_key(entity, @sprite.ecs_key_render_layers)) {
      Some(v) => v
      None => @sprite.RenderLayers::default()
    }
    let transform = render3d_entity_world_transform_cached(
      source_world, entity, world_transform_cache_ref,
    )
    let previous_camera_history = camera_motion_blur_history_get(entity)
    let previous_transform = match previous_camera_history {
      Some(v) => v.transform
      None => transform
    }
    match render3d_target_info(source_world, target) {
      Some(target_info) => {
        let mut camera_clamped = camera
        if camera.viewport is Some(viewport) {
          let clamped = render3d_clamp_viewport(
            viewport,
            target_info.target_size,
          )
          camera_clamped = camera.with_viewport(clamped)
        }
        let projection = match projection_component {
          Some(component_projection) => {
            let (runtime_projection, runtime_update) = render3d_projection_runtime_update(
              component_projection,
              try! source_world.get_by_key(entity, ecs_key_projection_runtime3d),
              projection_changed,
              camera_clamped,
              target_info.target_size,
              target_info.scale_factor,
            )
            if runtime_update is Some(runtime_state) {
              projection_updates.push(
                (entity, runtime_projection, runtime_state),
              )
            }
            runtime_projection
          }
          None =>
            render3d_projection_runtime_projection(
              projection,
              camera_clamped,
              target_info.target_size,
              target_info.scale_factor,
            )
        }
        cameras.push(ExtractedCamera3d::{
          entity: phase_entity_ref3d_for_main(entity),
          payload: Camera3dViewPayload::{
            camera3d,
            camera: camera_clamped,
            projection,
            sub_camera_view,
            oit_settings,
            screen_space_transmission,
            bloom,
            tonemapping,
            deband_dither,
            chromatic_aberration,
            custom_post_process3d,
            vignette,
            motion_blur,
            exposure,
            color_grading,
            skybox,
            environment_map_light,
            generated_environment_map_light,
            atmosphere_environment_map_light,
            depth_prepass_enabled,
            deferred_prepass_enabled,
            no_indirect_drawing,
            gpu_occlusion_culling_enabled,
            hdr_enabled,
            fxaa,
            temporal_jitter,
            temporal_anti_aliasing,
            motion_vector_prepass_enabled,
            msaa,
            transform,
            previous_transform,
            previous_clip_from_world: match previous_camera_history {
              Some(v) => Some(v.clip_from_world)
              None => None
            },
            target_id: target_info.target_id,
            target_size: target_info.target_size,
            scale_factor: target_info.scale_factor,
            layers,
          },
        })
      }
      None => ()
    }
    if projection_component is None &&
      (try! source_world.get_by_key(entity, ecs_key_projection_runtime3d))
      is Some(_) {
      projection_runtime_removals.push(entity)
    }
  })
  for update in projection_updates {
    try! source_world.set_by_key(update.0, ecs_key_projection, update.1)
    try! source_world.set_by_key(
      update.0,
      ecs_key_projection_runtime3d,
      update.2,
    )
  }
  for entity in projection_runtime_removals {
    try! (source_world.take(entity, ecs_key_projection_runtime3d) |> ignore)
  }
  @app.timeline_trace_end_span(
    @app.TimelineTraceCategory::RenderQueue,
    "execute_3d_collect_cameras",
    trace_collect_cameras_start_us,
  )
  if cameras.length() == 0 {
    phase_state_ref.val.prepared_camera_order.clear()
    phase_state_ref.val.last_camera3d_count = 0
    phase_state_ref.val.camera_order_needs_refresh = true
    finish_execute()
    return
  }
  let wireframe_config = if (try! source_world.get_resource(
      ecs_key_wireframe_config,
    ))
    is Some(config) {
    Some(config)
  } else {
    None
  }
  let motion_blur_frame_stamp = if needs_mesh_previous_transform {
    motion_blur_history_begin_frame()
  } else {
    0
  }
  let previous_motion_blur_frame_stamp = motion_blur_frame_stamp - 1
  let trace_collect_meshes_start_us = @app.timeline_trace_begin_span(
    @app.TimelineTraceCategory::RenderQueue,
    "execute_3d_collect_meshes",
  )
  let standard_material_frame_cache : Map[Int, StandardMaterial] = {}
  let has_render_layers_components = source_world.component_count(
      @sprite.ecs_key_render_layers,
    ) >
    0
  let has_visibility_range_components = source_world.component_count(
      @visibility.ecs_key_visibility_range,
    ) >
    0
  let has_lightmap_components = source_world.component_count(ecs_key_lightmap) >
    0
  let has_forward_decal_components = source_world.component_count(
      ecs_key_forward_decal,
    ) >
    0
  let has_forward_decal_material_ext_components = source_world.component_count(
      ecs_key_forward_decal_material_ext,
    ) >
    0
  let has_clustered_decal_components = source_world.component_count(
      ecs_key_clustered_decal,
    ) >
    0
  let has_not_shadow_caster_components = source_world.component_count(
      ecs_key_not_shadow_caster,
    ) >
    0
  let has_no_frustum_culling_components = source_world.component_count(
      @visibility.ecs_key_no_frustum_culling,
    ) >
    0
  let has_not_shadow_receiver_components = source_world.component_count(
      ecs_key_not_shadow_receiver,
    ) >
    0
  let has_transmitted_shadow_receiver_components = source_world.component_count(
      ecs_key_transmitted_shadow_receiver,
    ) >
    0
  let has_wireframe_components = source_world.component_count(ecs_key_wireframe) >
    0
  let has_no_wireframe_components = source_world.component_count(
      ecs_key_no_wireframe,
    ) >
    0
  let has_wireframe_color_components = source_world.component_count(
      ecs_key_wireframe_color,
    ) >
    0
  let mesh_extract_query : @ecs.Query[
    (
      @ecs.Comp[Mesh3d],
      @ecs.Comp[MeshMaterial3d],
      @ecs.Comp[@visibility.ViewVisibility],
      @ecs.Comp[@transform.Transform],
    ),
    @ecs.All,
  ] = @ecs.query(source_world)
  try! mesh_extract_query.view(fn(entity, data) {
    let (
      mesh3d_comp,
      material_handle_comp,
      view_visibility_comp,
      local_transform_comp,
    ) = data
    let mesh3d = mesh3d_comp.value()
    let view_visibility = view_visibility_comp.value()
    if !view_visibility.is_visible() {
      return
    }
    let material_handle = material_handle_comp.value()
    let material_handle_id = material_handle.material.id()
    let base_material = match
      standard_material_frame_cache.get(material_handle_id) {
      Some(cached_material) => cached_material
      None =>
        match standard_material_get(material_handle.material) {
          Some(loaded_material) => {
            standard_material_frame_cache.set(
              material_handle_id, loaded_material,
            )
            loaded_material
          }
          None => return
        }
    }
    let material = render3d_apply_extended_material_metadata(
      base_material,
      material_handle.extended_material,
    )
    let layers = if has_render_layers_components {
      match
        (try! source_world.get_by_key(entity, @sprite.ecs_key_render_layers)) {
        Some(v) => v
        None => @sprite.RenderLayers::default()
      }
    } else {
      @sprite.RenderLayers::default()
    }
    let transform = render3d_entity_world_transform_from_components(
      source_world,
      entity,
      local_transform_comp.value(),
      world_transform_cache_ref,
    )
    let previous_transform = if needs_mesh_previous_transform {
      match motion_blur_history_get(entity, previous_motion_blur_frame_stamp) {
        Some(v) => v
        None => transform
      }
    } else {
      transform
    }
    let visibility_range = if has_visibility_range_components {
      try! source_world.get_by_key(entity, @visibility.ecs_key_visibility_range)
    } else {
      None
    }
    let aabb_center_world = if visibility_range is Some(range) && range.use_aabb {
      match render3d_mesh_local_aabb_center(mesh3d) {
        Some(local_center) =>
          Some(render3d_transform_point(transform, local_center))
        None => None
      }
    } else {
      None
    }
    let (skinning_key_hi, skinning_key_lo) = render3d_prepared_skin_binding_keys(
      phase_state_ref, entity,
    )
    let mesh_id = render3d_upload_mesh_handle_cached(
      phase_state_ref,
      mesh3d.mesh,
    )
    let lightmap = if has_lightmap_components {
      try! source_world.get_by_key(entity, ecs_key_lightmap)
    } else {
      None
    }
    let is_forward_decal = if has_forward_decal_components {
      (try! source_world.get_by_key(entity, ecs_key_forward_decal)) is Some(_)
    } else {
      false
    }
    let forward_decal_material_ext = if has_forward_decal_material_ext_components {
      try! source_world.get_by_key(entity, ecs_key_forward_decal_material_ext)
    } else {
      None
    }
    let clustered_decal = if has_clustered_decal_components {
      try! source_world.get_by_key(entity, ecs_key_clustered_decal)
    } else {
      None
    }
    let has_not_shadow_caster = if has_not_shadow_caster_components {
      (try! source_world.get_by_key(entity, ecs_key_not_shadow_caster))
      is Some(_)
    } else {
      false
    }
    let has_no_frustum_culling = if has_no_frustum_culling_components {
      (try! source_world.get_by_key(
        entity, @visibility.ecs_key_no_frustum_culling,
      ))
      is Some(_)
    } else {
      false
    }
    let has_not_shadow_receiver = if has_not_shadow_receiver_components {
      (try! source_world.get_by_key(entity, ecs_key_not_shadow_receiver))
      is Some(_)
    } else {
      false
    }
    let has_transmitted_shadow_receiver = if has_transmitted_shadow_receiver_components {
      (try! source_world.get_by_key(entity, ecs_key_transmitted_shadow_receiver))
      is Some(_)
    } else {
      false
    }
    let has_wireframe = if has_wireframe_components {
      (try! source_world.get_by_key(entity, ecs_key_wireframe)) is Some(_)
    } else {
      false
    }
    let has_no_wireframe = if has_no_wireframe_components {
      (try! source_world.get_by_key(entity, ecs_key_no_wireframe)) is Some(_)
    } else {
      false
    }
    let wireframe_color = if has_wireframe_color_components {
      try! source_world.get_by_key(entity, ecs_key_wireframe_color)
    } else {
      None
    }
    meshes.push(ExtractedMesh3d::{
      entity: phase_entity_ref3d_for_main(entity),
      payload: Mesh3dExtractedPayload::{
        mesh_handle: mesh3d.mesh,
        mesh_id,
        mesh_is_indexed: render3d_mesh_handle_is_indexed_cached(
          mesh3d.mesh,
          phase_state_ref.val.mesh_preprocess_static_cache,
        ),
        transform,
        previous_transform,
        visibility_range,
        aabb_center_world,
        material,
        material_extension: material_handle.extended_material,
        lightmap,
        is_forward_decal,
        forward_decal_material_ext,
        clustered_decal,
        has_not_shadow_caster,
        has_not_shadow_receiver,
        has_transmitted_shadow_receiver,
        has_no_frustum_culling,
        layers,
        has_wireframe,
        has_no_wireframe,
        wireframe_color,
        skinning_key_hi,
        skinning_key_lo,
      },
    })
  })
  if needs_mesh_previous_transform {
    motion_blur_history_sync(meshes, motion_blur_frame_stamp)
  }
  render3d_diagnostic_queued_visible_mesh_count_ref.val = meshes.length()
  @app.timeline_trace_end_span(
    @app.TimelineTraceCategory::RenderQueue,
    "execute_3d_collect_meshes",
    trace_collect_meshes_start_us,
  )
  render3d_update_mesh_preprocess_static_cache(
    phase_state_ref.val.mesh_preprocess_static_cache,
    meshes,
  )
  let trace_render_cameras_start_us = @app.timeline_trace_begin_span(
    @app.TimelineTraceCategory::RenderQueue,
    "execute_3d_render_cameras",
  )
  let lighting = render3d_collect_lighting(source_world)
  let camera_phase_items = match
    render3d_prepared_camera_phase_items(world, cameras) {
    Some(items) => items
    None => render3d_queue_camera_phase_items(cameras)
  }
  let cleared_targets_this_frame : Array[Int] = []
  let next_camera_motion_blur_history : Array[CameraMotionBlurHistoryEntry] = []
  for camera_phase_item in camera_phase_items {
    let extracted_camera = cameras[camera_phase_item.extracted_index]
    let camera_entity = extracted_camera.entity.main_entity
    let camera = extracted_camera.payload
    @render.host_gpu_set_active_surface_target(camera.target_id)
    let target_width = camera.target_size.x
    let target_height = camera.target_size.y
    if target_width <= 0 || target_height <= 0 {
      continue
    }
    let mut viewport_x = 0
    let mut viewport_y = 0
    let mut viewport_width = target_width
    let mut viewport_height = target_height
    let mut viewport_depth_min = 0.0F
    let mut viewport_depth_max = 1.0F
    let mut view_width = target_width
    let mut view_height = target_height
    if camera.camera.viewport is Some(viewport) {
      viewport_x = viewport.physical_position.x
      viewport_y = viewport.physical_position.y
      viewport_width = viewport.physical_size.x
      viewport_height = viewport.physical_size.y
      if viewport_width <= 0 || viewport_height <= 0 {
        continue
      }
      viewport_depth_min = viewport.depth_min
      viewport_depth_max = viewport.depth_max
      view_width = viewport_width
      view_height = viewport_height
    }
    // Render target textures and viewport dimensions are in physical pixels.
    // Do not divide by window scale factor here; doing so halves render size on
    // high-DPI displays and breaks camera framing/post-process alignment.
    camera.scale_factor |> ignore
    let view_width_logical = view_width
    let view_height_logical = view_height
    if view_width_logical <= 0 || view_height_logical <= 0 {
      continue
    }
    fn pass_viewport(target_id : Int) -> (Int, Int, Int, Int) {
      render3d_pass_viewport_for_target(
        target_id,
        camera.target_id,
        viewport_x,
        viewport_y,
        viewport_width,
        viewport_height,
      )
    }
    let temporal_aa_enabled = camera.temporal_anti_aliasing is Some(_)
    let camera_pass_projection = render3d_camera_pass_projection(
      camera.projection,
      camera.sub_camera_view,
      camera.temporal_jitter,
      view_width,
      view_height,
    )
    let camera_frustum_planes = render3d_host_preprocess_view_frustum_planes(
      camera.projection,
      camera.transform,
    )
    let camera_near = camera_pass_projection.camera_near
    let camera_far = camera_pass_projection.camera_far
    let current_clip_from_world = render3d_pass_projection_clip_from_world(
      camera_pass_projection,
      camera.transform,
    )
    next_camera_motion_blur_history.push({
      entity: camera_entity,
      transform: camera.transform,
      clip_from_world: current_clip_from_world,
    })
    let pass_lighting = render3d_camera_apply_environment_map_lighting(
      lighting, extracted_camera,
    )
    let environment_map_state = render3d_camera_environment_map_state(
      extracted_camera,
    )
    let camera_deferred_mode = render3d_camera_deferred_mode(
      camera.camera3d.deferred_config,
      default_opaque_renderer_method,
      deferred_lighting_enabled,
    )
    let camera_deferred_enabled = deferred_lighting_enabled &&
      prepass_enabled &&
      (
        camera.deferred_prepass_enabled ||
        camera.camera3d.deferred_config.requires_deferred_prepass ||
        camera_deferred_mode is OpaqueRendererMethod::Deferred
      )
    let camera_msaa_allows_forward_decals = match camera.msaa {
      Some(msaa) => msaa is Msaa::Off
      None => true
    }
    let camera_forward_decal_enabled = render3d_decal_mode_allows_forward(
        camera.camera3d.decal_config.mode,
      ) &&
      camera_msaa_allows_forward_decals &&
      (
        !camera.camera3d.decal_config.requires_depth_prepass ||
        camera.depth_prepass_enabled
      )
    let camera_clustered_decal_enabled = render3d_decal_mode_allows_clustered(
        camera.camera3d.decal_config.mode,
      ) &&
      (
        !camera.camera3d.decal_config.clustered_requires_deferred_prepass ||
        camera_deferred_enabled
      )
    let effective_exposure = camera.exposure
    let camera_exposure_value = match effective_exposure {
      Some(value) => value.exposure()
      None => Exposure::default().exposure()
    }
    let camera_base_fog = match camera.camera3d.distance_fog {
      Some(value) => value
      None =>
        DistanceFog::new(
          @sprite.Color::new(0.0F, 0.0F, 0.0F, 0.0F),
          FogFalloff3d::linear(0.0F, 0.0F),
        )
    }
    let distance_fog = render3d_camera_distance_fog(
      camera_base_fog,
      camera.camera3d.volumetric_fog,
      camera.camera3d.atmosphere,
      camera.camera3d.atmosphere_settings,
    )
    let (clear_enabled, resolved_clear_color) = camera.camera.clear_color.resolve()
    let clear_color = resolved_clear_color
    let motion_blur_active = if camera.motion_blur is Some(motion_blur) {
      motion_blur.samples > 0 && motion_blur.shutter_angle > 0.0F
    } else {
      false
    }
    let transmission_blur_taps = if camera.screen_space_transmission
      is Some(transmission) &&
      transmission.steps > 0 {
      screen_space_transmission_blur_taps(transmission.quality)
    } else {
      0
    }
    let transmission_steps = if camera.screen_space_transmission
      is Some(transmission) {
      transmission.steps
    } else {
      0
    }
    let transmission_enabled = transmission_blur_taps > 0
    let bloom_enabled = camera.bloom is Some(_)
    let tonemapping_stage_enabled = render3d_tonemapping_stage_enabled(
      camera.tonemapping,
      camera.deband_dither,
      camera.hdr_enabled,
      camera.color_grading,
    )
    let effect_stack_postprocess_enabled = render3d_effect_stack_enabled(
      camera.chromatic_aberration,
      camera.vignette,
    )
    let custom_post_process_enabled = render3d_custom_post_process_enabled(
      camera.custom_post_process3d,
    )
    let fxaa_postprocess_enabled = render3d_fxaa_enabled(camera.fxaa)
    let tonemap_postprocess_enabled = tonemapping_stage_enabled ||
      effect_stack_postprocess_enabled ||
      custom_post_process_enabled ||
      fxaa_postprocess_enabled
    let auto_exposure_enabled = camera.camera3d.auto_exposure is Some(_)
    let motion_vector_prepass_enabled = prepass_enabled &&
      (
        motion_blur_active ||
        camera.motion_vector_prepass_enabled ||
        temporal_aa_enabled ||
        camera.gpu_occlusion_culling_enabled
      )
    let fog_enabled = render3d_distance_fog_enabled(distance_fog)
    let decal_enabled = camera_forward_decal_enabled ||
      camera_clustered_decal_enabled
    let postprocess_enabled = motion_blur_active ||
      bloom_enabled ||
      tonemap_postprocess_enabled ||
      auto_exposure_enabled
    let scene_pass_kind = render3d_pass_kind_encode(
      RENDER3D_PASS_KIND_BASE_SCENE,
      postprocess_enabled,
      fog_enabled,
      decal_enabled,
    )
    let motion_vector_pass_kind = render3d_pass_kind_encode(
      RENDER3D_PASS_KIND_BASE_MOTION_VECTOR,
      false,
      false,
      false,
    )
    let point_shadow_pass_kind = render3d_pass_kind_encode(
      RENDER3D_PASS_KIND_BASE_POINT_SHADOW,
      false,
      false,
      false,
    )
    let mut scene_target_id = camera.target_id
    let mut velocity_target_id = -1
    let mut point_shadow_texture_id = -1
    let mut point_shadow_enabled = 0.0F
    let mut point_shadow_depth_bias = 0.0F
    let point_shadow_near = if pass_lighting.point_shadow_map_near_z > 0.0001F {
      pass_lighting.point_shadow_map_near_z
    } else {
      0.0001F
    }
    let trace_camera_queue_build_start_us = @app.timeline_trace_begin_span(
      @app.TimelineTraceCategory::RenderQueue,
      "execute_3d_camera_queue_build",
    )
    let trace_camera_queue_entry_start_us = @app.timeline_trace_begin_span(
      @app.TimelineTraceCategory::RenderQueue,
      "execute_3d_camera_queue_entry",
    )
    let camera_indirect_enabled = render3d_camera_indirect_enabled(
      gpu_instance_buffer_builder_enabled,
      gpu_culling_supported,
      camera.no_indirect_drawing,
    )
    let draw_queue_entry = render3d_make_fallback_gpu_preprocess_queue_entry(
      render3d_queue_mesh_phase_items(
        meshes,
        camera.layers,
        camera.transform,
        camera_frustum_planes,
        phase_state_ref.val.mesh_preprocess_static_cache,
        camera_indirect_enabled,
      ),
      meshes,
      phase_state_ref.val.mesh_preprocess_static_cache,
      camera_indirect_enabled,
      camera_indirect_enabled && camera.gpu_occlusion_culling_enabled,
    )
    @app.timeline_trace_end_span(
      @app.TimelineTraceCategory::RenderQueue,
      "execute_3d_camera_queue_entry",
      trace_camera_queue_entry_start_us,
    )
    let draw_items = draw_queue_entry.draw_items
    let trace_camera_queue_indices_start_us = @app.timeline_trace_begin_span(
      @app.TimelineTraceCategory::RenderQueue,
      "execute_3d_camera_queue_indices",
    )
    let opaque_alpha_draw_item_indices = render3d_gpu_preprocess_opaque_alpha_draw_item_indices(
      draw_items,
      draw_queue_entry.phase_ranges,
      draw_queue_entry.work_item_buffers,
    )
    let (
      indexed_indirect_parameter_indices,
      non_indexed_indirect_parameter_indices,
    ) = render3d_gpu_preprocess_indirect_parameter_index_maps(
      draw_items,
      draw_queue_entry.work_item_buffers,
    )
    let needs_gpu_preprocess = match draw_queue_entry.work_item_buffers {
      Indirect(_, _, _) => true
      _ => false
    }
    @app.timeline_trace_end_span(
      @app.TimelineTraceCategory::RenderQueue,
      "execute_3d_camera_queue_indices",
      trace_camera_queue_indices_start_us,
    )
    if needs_gpu_preprocess {
      let trace_camera_queue_upload_start_us = @app.timeline_trace_begin_span(
        @app.TimelineTraceCategory::RenderQueue,
        "execute_3d_camera_queue_upload",
      )
      @render.host_gpu_upload_mesh3d_preprocess_camera_payload(
        camera_key_hi=camera_entity.id,
        camera_key_lo=camera_entity.generation,
        payload=render3d_host_preprocess_camera_payload(
          draw_queue_entry, camera, camera_pass_projection, viewport_x, viewport_y,
          viewport_width, viewport_height, camera_exposure_value,
        ),
      )
      @app.timeline_trace_end_span(
        @app.TimelineTraceCategory::RenderQueue,
        "execute_3d_camera_queue_upload",
        trace_camera_queue_upload_start_us,
      )
      let trace_camera_queue_preprocess_start_us = @app.timeline_trace_begin_span(
        @app.TimelineTraceCategory::RenderQueue,
        "execute_3d_camera_queue_preprocess",
      )
      if camera.gpu_occlusion_culling_enabled {
        let trace_camera_preprocess_dispatch_start_us = @app.timeline_trace_begin_span(
          @app.TimelineTraceCategory::RenderQueue,
          "execute_3d_camera_preprocess_dispatch",
        )
        @render.host_gpu_preprocess_mesh3d(
          camera_key_hi=camera_entity.id,
          camera_key_lo=camera_entity.generation,
          phase_kind=@render.MESH3D_PREPROCESS_PHASE_EARLY_OCCLUSION,
        )
        @app.timeline_trace_end_span(
          @app.TimelineTraceCategory::RenderQueue,
          "execute_3d_camera_preprocess_dispatch",
          trace_camera_preprocess_dispatch_start_us,
        )
        let trace_camera_build_indirect_start_us = @app.timeline_trace_begin_span(
          @app.TimelineTraceCategory::RenderQueue,
          "execute_3d_camera_build_indirect",
        )
        @render.host_gpu_build_mesh3d_indirect_parameters(
          camera_key_hi=camera_entity.id,
          camera_key_lo=camera_entity.generation,
          phase_kind=@render.MESH3D_BUILD_INDIRECT_PHASE_EARLY,
        )
        @app.timeline_trace_end_span(
          @app.TimelineTraceCategory::RenderQueue,
          "execute_3d_camera_build_indirect",
          trace_camera_build_indirect_start_us,
        )
      } else {
        let trace_camera_preprocess_dispatch_start_us = @app.timeline_trace_begin_span(
          @app.TimelineTraceCategory::RenderQueue,
          "execute_3d_camera_preprocess_dispatch",
        )
        @render.host_gpu_preprocess_mesh3d(
          camera_key_hi=camera_entity.id,
          camera_key_lo=camera_entity.generation,
        )
        @app.timeline_trace_end_span(
          @app.TimelineTraceCategory::RenderQueue,
          "execute_3d_camera_preprocess_dispatch",
          trace_camera_preprocess_dispatch_start_us,
        )
        let trace_camera_build_indirect_start_us = @app.timeline_trace_begin_span(
          @app.TimelineTraceCategory::RenderQueue,
          "execute_3d_camera_build_indirect",
        )
        @render.host_gpu_build_mesh3d_indirect_parameters(
          camera_key_hi=camera_entity.id,
          camera_key_lo=camera_entity.generation,
        )
        @app.timeline_trace_end_span(
          @app.TimelineTraceCategory::RenderQueue,
          "execute_3d_camera_build_indirect",
          trace_camera_build_indirect_start_us,
        )
      }
      @app.timeline_trace_end_span(
        @app.TimelineTraceCategory::RenderQueue,
        "execute_3d_camera_queue_preprocess",
        trace_camera_queue_preprocess_start_us,
      )
    }
    @app.timeline_trace_end_span(
      @app.TimelineTraceCategory::RenderQueue,
      "execute_3d_camera_queue_build",
      trace_camera_queue_build_start_us,
    )
    if motion_vector_prepass_enabled {
      let (shared_scene_id, shared_velocity_id) = render3d_motion_blur_targets_get_or_create(
        camera_entity, view_width, view_height,
      )
      if motion_blur_active {
        scene_target_id = shared_scene_id
      }
      velocity_target_id = shared_velocity_id
      let (
        motion_viewport_x,
        motion_viewport_y,
        motion_viewport_width,
        motion_viewport_height,
      ) = pass_viewport(shared_scene_id)
      render3d_begin_pass_3d(
        target_id=shared_scene_id,
        secondary_target_id=velocity_target_id,
        width=view_width_logical,
        height=view_height_logical,
        clear_r=0.0F,
        clear_g=0.0F,
        clear_b=0.0F,
        clear_a=0.0F,
        camera.transform,
        camera_pass_projection,
        viewport_x=motion_viewport_x,
        viewport_y=motion_viewport_y,
        viewport_width=motion_viewport_width,
        viewport_height=motion_viewport_height,
        pass_lighting,
        camera_exposure=camera_exposure_value,
        previous_clip_from_world=camera.previous_clip_from_world,
        point_shadow_near~,
        pass_kind=motion_vector_pass_kind,
        clear_enabled=1,
      )
      for draw_item_index in opaque_alpha_draw_item_indices {
        let draw_item = draw_items[draw_item_index]
        if draw_item.phase != RENDER3D_PHASE_OPAQUE &&
          draw_item.phase != RENDER3D_PHASE_ALPHA_MASK {
          continue
        }
        let extracted_mesh = meshes[draw_item.extracted_index]
        let mesh = extracted_mesh.payload
        guard render3d_mesh_draw_alpha(
            mesh.material.alpha_mode,
            mesh.material.base_color.a,
          )
          is Some(draw_alpha) else {
          continue
        }
        if draw_alpha < 0.999F {
          continue
        }
        let motion_vector_indexed = mesh.mesh_is_indexed
        let motion_vector_indirect_parameters_index = if motion_vector_indexed {
          indexed_indirect_parameter_indices[draw_item_index]
        } else {
          non_indexed_indirect_parameter_indices[draw_item_index]
        }
        render3d_draw_mesh_gpu_payload(
          render3d_build_mesh_gpu_draw_payload(
            mesh.mesh_id,
            camera_entity.id,
            camera_entity.generation,
            draw_item_index,
            if motion_vector_indirect_parameters_index >= 0 {
              if motion_vector_indexed {
                MESH3D_DRAW_INDIRECT_KIND_INDEXED
              } else {
                MESH3D_DRAW_INDIRECT_KIND_NON_INDEXED
              }
            } else {
              MESH3D_DRAW_INDIRECT_KIND_NONE
            },
            motion_vector_indirect_parameters_index,
            mesh.material,
            mesh.transform,
            mesh.previous_transform,
            1.0F,
            1.0F,
            1.0F,
            1.0F,
            -1,
            -1,
            -1,
            -1,
            -1,
            -1,
            -1,
            -1,
            0.5F,
            0.5F,
            0.0F,
            0.0F,
            0.0F,
            1.5F,
            -1,
            0.0F,
            0.0F,
            -1,
            0.0F,
            0.0F,
            -1,
            -1,
            0.0F,
            @math.Quat::identity(),
            @sprite.Color::white(),
            0.0F,
            0.0F,
            render3d_mesh_draw_flags(extracted_mesh),
          ),
        )
      }
      @render.host_gpu_end_pass()
      if camera.gpu_occlusion_culling_enabled {
        @render.host_gpu_downsample_mesh3d_depth_pyramid(
          camera_key_hi=camera_entity.id,
          camera_key_lo=camera_entity.generation,
        )
        @render.host_gpu_preprocess_mesh3d(
          camera_key_hi=camera_entity.id,
          camera_key_lo=camera_entity.generation,
          phase_kind=@render.MESH3D_PREPROCESS_PHASE_LATE_OCCLUSION,
        )
        @render.host_gpu_build_mesh3d_indirect_parameters(
          camera_key_hi=camera_entity.id,
          camera_key_lo=camera_entity.generation,
          phase_kind=@render.MESH3D_BUILD_INDIRECT_PHASE_MAIN,
        )
      }
    }
    if pass_lighting.point_shadow_maps_enabled &&
      !pass_lighting.point_entity.is_placeholder() &&
      pass_lighting.point_range > 0.0F &&
      point_light_shadow_map_size > 0 {
      let shadow_target_id = render3d_point_light_shadow_target_get_or_create(
        pass_lighting.point_entity,
        point_light_shadow_map_size,
      )
      point_shadow_texture_id = shadow_target_id
      point_shadow_enabled = 1.0F
      point_shadow_depth_bias = maxf(
        0.0F,
        pass_lighting.point_shadow_depth_bias,
      )
      let shadow_camera_near = if pass_lighting.point_shadow_map_near_z >
        0.0001F {
        pass_lighting.point_shadow_map_near_z
      } else {
        0.0001F
      }
      let shadow_view_size = point_light_shadow_map_size
      let point_shadow_pass_projection = render3d_point_shadow_pass_projection(
        shadow_camera_near,
        pass_lighting.point_range,
      )
      for face_index in 0..<6 {
        let shadow_camera_transform = render3d_point_shadow_face_transform(
          pass_lighting.point_pos,
          face_index,
        )
        render3d_begin_pass_3d(
          target_id=shadow_target_id,
          target_layer=face_index,
          width=shadow_view_size,
          height=shadow_view_size,
          clear_r=1.0F,
          clear_g=1.0F,
          clear_b=1.0F,
          clear_a=1.0F,
          shadow_camera_transform,
          point_shadow_pass_projection,
          viewport_x=0,
          viewport_y=0,
          viewport_width=shadow_view_size,
          viewport_height=shadow_view_size,
          pass_lighting,
          previous_clip_from_world=None,
          point_shadow_near=shadow_camera_near,
          pass_kind=point_shadow_pass_kind,
          clear_enabled=1,
        )
        for draw_item_index in opaque_alpha_draw_item_indices {
          let shadow_draw_item = draw_items[draw_item_index]
          if shadow_draw_item.phase != RENDER3D_PHASE_OPAQUE &&
            shadow_draw_item.phase != RENDER3D_PHASE_ALPHA_MASK {
            continue
          }
          let extracted_shadow_mesh = meshes[shadow_draw_item.extracted_index]
          let shadow_mesh = extracted_shadow_mesh.payload
          if shadow_mesh.has_not_shadow_caster {
            continue
          }
          if shadow_mesh.is_forward_decal ||
            shadow_mesh.clustered_decal is Some(_) {
            continue
          }
          guard render3d_mesh_draw_alpha(
              shadow_mesh.material.alpha_mode,
              shadow_mesh.material.base_color.a,
            )
            is Some(shadow_alpha) else {
            continue
          }
          if shadow_alpha < 0.999F {
            continue
          }
          let shadow_indexed = shadow_mesh.mesh_is_indexed
          let shadow_indirect_parameters_index = if shadow_indexed {
            indexed_indirect_parameter_indices[draw_item_index]
          } else {
            non_indexed_indirect_parameter_indices[draw_item_index]
          }
          render3d_draw_mesh_gpu_payload(
            render3d_build_mesh_gpu_draw_payload(
              shadow_mesh.mesh_id,
              camera_entity.id,
              camera_entity.generation,
              draw_item_index,
              if shadow_indirect_parameters_index >= 0 {
                if shadow_indexed {
                  MESH3D_DRAW_INDIRECT_KIND_INDEXED
                } else {
                  MESH3D_DRAW_INDIRECT_KIND_NON_INDEXED
                }
              } else {
                MESH3D_DRAW_INDIRECT_KIND_NONE
              },
              shadow_indirect_parameters_index,
              shadow_mesh.material,
              shadow_mesh.transform,
              shadow_mesh.transform,
              1.0F,
              1.0F,
              1.0F,
              1.0F,
              -1,
              -1,
              -1,
              -1,
              -1,
              -1,
              -1,
              -1,
              0.5F,
              0.5F,
              0.0F,
              0.0F,
              0.0F,
              1.5F,
              -1,
              0.0F,
              0.0F,
              -1,
              0.0F,
              0.0F,
              -1,
              -1,
              0.0F,
              @math.Quat::identity(),
              @sprite.Color::white(),
              0.0F,
              0.0F,
              0,
            ),
          )
        }
        @render.host_gpu_end_pass()
      }
    }
    if !motion_blur_active &&
      (
        transmission_enabled ||
        bloom_enabled ||
        tonemap_postprocess_enabled ||
        auto_exposure_enabled
      ) &&
      (
        camera.target_id < 0 ||
        bloom_enabled ||
        tonemap_postprocess_enabled ||
        auto_exposure_enabled
      ) {
      let (scene_id, _velocity_id) = render3d_motion_blur_targets_get_or_create(
        camera_entity, view_width, view_height,
      )
      scene_target_id = scene_id
    }
    let mut transmission_source_target_id = -1
    let trace_camera_main_pass_start_us = @app.timeline_trace_begin_span(
      @app.TimelineTraceCategory::RenderQueue,
      "execute_3d_camera_main_pass",
    )
    let (
      scene_viewport_x,
      scene_viewport_y,
      scene_viewport_width,
      scene_viewport_height,
    ) = pass_viewport(scene_target_id)
    render3d_begin_pass_3d(
      target_id=scene_target_id,
      width=view_width_logical,
      height=view_height_logical,
      clear_r=clear_color.r,
      clear_g=clear_color.g,
      clear_b=clear_color.b,
      clear_a=clear_color.a,
      camera.transform,
      camera_pass_projection,
      viewport_x=scene_viewport_x,
      viewport_y=scene_viewport_y,
      viewport_width=scene_viewport_width,
      viewport_height=scene_viewport_height,
      pass_lighting,
      camera_exposure=camera_exposure_value,
      previous_clip_from_world=camera.previous_clip_from_world,
      point_shadow_texture_id~,
      point_shadow_enabled~,
      point_shadow_depth_bias~,
      environment_diffuse_texture_id=environment_map_state.diffuse_texture_id,
      environment_specular_texture_id=environment_map_state.specular_texture_id,
      environment_map_intensity=environment_map_state.intensity,
      environment_map_rotation=environment_map_state.rotation,
      point_shadow_near~,
      pass_kind=scene_pass_kind,
      clear_enabled=render3d_pass_clear_enabled_for_target(
        cleared_targets_this_frame, scene_target_id, clear_enabled,
      ),
    )
    let main_pass_draws : Array[MeshGpuDrawPayload3d] = []
    let transmissive_phase_items : Array[TransmissivePhaseItem3d] = []
    let transparent_draws : Array[MeshGpuDrawPayload3d] = []
    for draw_item_index in 0..<draw_items.length() {
      let draw_item = draw_items[draw_item_index]
      let extracted_mesh = meshes[draw_item.extracted_index]
      let mesh = extracted_mesh.payload
      if mesh.is_forward_decal && !camera_forward_decal_enabled {
        continue
      }
      if mesh.clustered_decal is Some(_) && !camera_clustered_decal_enabled {
        continue
      }
      if mesh.material_extension is Some(extension) {
        if extension.requires_depth_prepass && !camera.depth_prepass_enabled {
          continue
        }
        if extension.requires_deferred_prepass && !camera_deferred_enabled {
          continue
        }
      }
      let mesh_opaque_mode = if mesh.material.opaque_render_method
        is OpaqueRendererMethod::Auto {
        camera_deferred_mode
      } else {
        mesh.material.opaque_render_method
      }
      if mesh_opaque_mode is OpaqueRendererMethod::Deferred &&
        !camera_deferred_enabled {
        continue
      }
      guard render3d_mesh_draw_alpha(
          mesh.material.alpha_mode,
          mesh.material.base_color.a,
        )
        is Some(base_draw_alpha) else {
        continue
      }
      let mut draw_material = mesh.material
      if mesh.lightmap is Some(lightmap) && lightmap.image.id() > 0 {
        draw_material = draw_material
          .with_base_color_texture(Some(lightmap.image))
          .with_uv_transform(render3d_lightmap_uv_transform(lightmap.uv_rect))
          .with_unlit(true)
      }
      let mut draw_alpha = base_draw_alpha
      let mut texture_id = match draw_material.base_color_texture {
        Some(texture) => texture.id()
        None => -1
      }
      let mut normal_texture_id = match
        (
          draw_material.normal_map_texture,
          draw_material.clearcoat_normal_texture,
        ) {
        (Some(texture), _) => texture.id()
        (None, Some(texture)) => texture.id()
        (None, None) => -1
      }
      let mut emissive_texture_id = match draw_material.emissive_texture {
        Some(texture) => texture.id()
        None => -1
      }
      let mut metallic_roughness_texture_id = match
        draw_material.metallic_roughness_texture {
        Some(texture) => texture.id()
        None => -1
      }
      let occlusion_texture_id = match draw_material.occlusion_texture {
        Some(texture) => texture.id()
        None => -1
      }
      let depth_texture_id = match draw_material.depth_map {
        Some(texture) => texture.id()
        None => -1
      }
      let anisotropy_texture_id = match draw_material.anisotropy_texture {
        Some(texture) => texture.id()
        None => -1
      }
      let specular_tint_texture_id = match draw_material.specular_tint_texture {
        Some(texture) => texture.id()
        None => -1
      }
      if mesh.clustered_decal is Some(clustered_decal) {
        if clustered_decal.base_color_texture is Some(texture) {
          texture_id = texture.id()
        }
        if clustered_decal.normal_map_texture is Some(texture) {
          normal_texture_id = texture.id()
        }
        if clustered_decal.metallic_roughness_texture is Some(texture) {
          metallic_roughness_texture_id = texture.id()
        }
        if clustered_decal.emissive_texture is Some(texture) {
          emissive_texture_id = texture.id()
        }
      }
      let anisotropy_strength = maxf(
        0.0F,
        minf(1.0F, draw_material.anisotropy_strength),
      )
      let max_relief_mapping_search_steps = Float::from_double(
        draw_material.parallax_mapping_method.max_steps().to_double(),
      )
      let mut clearcoat_reflectance = maxf(
        0.0F,
        draw_material.reflectance + draw_material.clearcoat * 0.5F,
      )
      let clearcoat_roughness = minf(
        draw_material.perceptual_roughness,
        draw_material.clearcoat_perceptual_roughness,
      )
      let mut draw_roughness = if draw_material.clearcoat > 0.0F {
        clearcoat_roughness
      } else {
        draw_material.perceptual_roughness
      }
      let needs_mesh_distance = fog_enabled || mesh.is_forward_decal
      let mesh_distance = if needs_mesh_distance {
        mesh.transform.translation.sub(camera.transform.translation).length()
      } else {
        0.0F
      }
      if mesh.is_forward_decal {
        let depth_fade_factor = if mesh.forward_decal_material_ext
          is Some(extension) {
          extension.depth_fade_factor
        } else {
          8.0F
        }
        let safe_depth_fade_factor = if depth_fade_factor < 0.001F {
          0.001F
        } else {
          depth_fade_factor
        }
        let decal_alpha = safe_depth_fade_factor /
          (safe_depth_fade_factor + maxf(0.0F, mesh_distance - camera_near))
        draw_alpha = draw_alpha * render3d_float_clamp(decal_alpha, 0.0F, 1.0F)
        clearcoat_reflectance = 0.0F
        draw_roughness = maxf(draw_roughness, 0.85F)
      }
      let (fogged_r, fogged_g, fogged_b) = if fog_enabled {
        render3d_apply_distance_fog(
          distance_fog,
          mesh_distance,
          draw_material.base_color.r,
          draw_material.base_color.g,
          draw_material.base_color.b,
          camera.transform.translation,
          mesh.transform.translation,
          pass_lighting,
        )
      } else {
        (
          draw_material.base_color.r,
          draw_material.base_color.g,
          draw_material.base_color.b,
        )
      }
      let draw_color_r = fogged_r
      let draw_color_g = fogged_g
      let draw_color_b = fogged_b
      let draw_surface_roughness = draw_roughness
      let draw_reflectance = clearcoat_reflectance
      let draw_diffuse_transmission = clamp01(
        draw_material.diffuse_transmission,
      )
      let draw_specular_transmission = clamp01(
        draw_material.specular_transmission,
      )
      let draw_thickness = maxf(0.0F, draw_material.thickness)
      let draw_ior = maxf(1.0F, draw_material.ior)
      if draw_item.phase == RENDER3D_PHASE_TRANSPARENT &&
        camera.oit_settings is Some(oit_settings) &&
        draw_alpha < oit_settings.alpha_threshold {
        continue
      }
      let mut draw_point_shadow_enabled = point_shadow_enabled
      if mesh.has_not_shadow_receiver {
        draw_point_shadow_enabled = 0.0F
      }
      if draw_point_shadow_enabled > 0.0F &&
        (draw_diffuse_transmission > 0.0F || draw_specular_transmission > 0.0F) &&
        !mesh.has_transmitted_shadow_receiver {
        draw_point_shadow_enabled = 0.0F
      }
      let draw_flags = render3d_mesh_draw_flags(extracted_mesh)
      let draw_indexed = mesh.mesh_is_indexed
      let draw_indirect_parameters_index = if draw_indexed {
        indexed_indirect_parameter_indices[draw_item_index]
      } else {
        non_indexed_indirect_parameter_indices[draw_item_index]
      }
      let draw_shader_path = match mesh.material_extension {
        Some(extension) => extension.shader_path
        None => None
      }
      let draw_payload = render3d_build_mesh_gpu_draw_payload(
        mesh.mesh_id,
        camera_entity.id,
        camera_entity.generation,
        draw_item_index,
        if draw_indirect_parameters_index >= 0 {
          if draw_indexed {
            MESH3D_DRAW_INDIRECT_KIND_INDEXED
          } else {
            MESH3D_DRAW_INDIRECT_KIND_NON_INDEXED
          }
        } else {
          MESH3D_DRAW_INDIRECT_KIND_NONE
        },
        draw_indirect_parameters_index,
        draw_material,
        mesh.transform,
        mesh.previous_transform,
        draw_color_r,
        draw_color_g,
        draw_color_b,
        draw_alpha,
        texture_id,
        normal_texture_id,
        emissive_texture_id,
        metallic_roughness_texture_id,
        occlusion_texture_id,
        depth_texture_id,
        anisotropy_texture_id,
        specular_tint_texture_id,
        draw_surface_roughness,
        draw_reflectance,
        draw_diffuse_transmission,
        draw_specular_transmission,
        draw_thickness,
        draw_ior,
        -1,
        0.0F,
        0.0F,
        point_shadow_texture_id,
        draw_point_shadow_enabled,
        point_shadow_depth_bias,
        environment_map_state.diffuse_texture_id,
        environment_map_state.specular_texture_id,
        environment_map_state.intensity,
        environment_map_state.rotation,
        draw_material.specular_tint,
        anisotropy_strength,
        max_relief_mapping_search_steps,
        draw_flags,
        shader_path=draw_shader_path,
        skinning_key_hi=mesh.skinning_key_hi,
        skinning_key_lo=mesh.skinning_key_lo,
      )
      if draw_item.phase == RENDER3D_PHASE_TRANSPARENT {
        transparent_draws.push(draw_payload)
        continue
      }
      if transmission_enabled && draw_specular_transmission > 0.0F {
        transmissive_phase_items.push(TransmissivePhaseItem3d::{
          entity: extracted_mesh.entity,
          distance: draw_item.distance,
          payload: draw_payload,
        })
        continue
      }
      main_pass_draws.push(draw_payload)
    }
    for draw_payload in main_pass_draws {
      render3d_draw_mesh_gpu_payload(draw_payload)
    }
    render3d_draw_gizmo_lines_3d(camera_entity, camera)
    render3d_draw_camera_skybox(
      world, extracted_camera, camera_far, camera_exposure_value, point_shadow_texture_id,
      point_shadow_enabled, point_shadow_depth_bias, environment_map_state,
    )
    @render.host_gpu_end_pass()
    let transmissive_draws = render3d_sort_transmissive_phase_items(
      transmissive_phase_items,
    )
    if transmissive_draws.length() > 0 {
      transmission_source_target_id = render3d_transmission_source_target_get_or_create(
        camera_entity, view_width, view_height,
      )
      let transmission_ranges = if transmission_steps > 0 {
        render3d_split_phase_ranges(
          transmissive_draws.length(),
          transmission_steps,
        )
      } else {
        [(0, transmissive_draws.length())]
      }
      for transmission_range in transmission_ranges {
        if transmission_steps > 0 {
          render3d_blit_texture_to_target(
            scene_target_id, transmission_source_target_id, view_width_logical, view_height_logical,
          )
        }
        let (
          transmission_viewport_x,
          transmission_viewport_y,
          transmission_viewport_width,
          transmission_viewport_height,
        ) = pass_viewport(scene_target_id)
        render3d_begin_pass_3d(
          target_id=scene_target_id,
          width=view_width_logical,
          height=view_height_logical,
          clear_r=clear_color.r,
          clear_g=clear_color.g,
          clear_b=clear_color.b,
          clear_a=clear_color.a,
          camera.transform,
          camera_pass_projection,
          viewport_x=transmission_viewport_x,
          viewport_y=transmission_viewport_y,
          viewport_width=transmission_viewport_width,
          viewport_height=transmission_viewport_height,
          pass_lighting,
          camera_exposure=camera_exposure_value,
          previous_clip_from_world=camera.previous_clip_from_world,
          transmission_blur_taps=Float::from_double(
            transmission_blur_taps.to_double(),
          ),
          transmission_steps=Float::from_double(transmission_steps.to_double()),
          point_shadow_texture_id~,
          point_shadow_enabled~,
          point_shadow_depth_bias~,
          transmission_source_texture_id=if transmission_steps > 0 {
            transmission_source_target_id
          } else {
            -1
          },
          environment_diffuse_texture_id=environment_map_state.diffuse_texture_id,
          environment_specular_texture_id=environment_map_state.specular_texture_id,
          environment_map_intensity=environment_map_state.intensity,
          environment_map_rotation=environment_map_state.rotation,
          point_shadow_near~,
          pass_kind=scene_pass_kind,
          clear_enabled=0,
        )
        for i in transmission_range.0..<transmission_range.1 {
          let transmissive_draw = transmissive_draws[i]
          transmissive_draw.entity |> ignore
          render3d_draw_mesh_gpu_payload(MeshGpuDrawPayload3d::{
            ..transmissive_draw.payload,
            transmission_source_texture_id: if transmission_steps > 0 {
              transmission_source_target_id
            } else {
              -1
            },
            transmission_blur_taps: Float::from_double(
              transmission_blur_taps.to_double(),
            ),
            transmission_steps: Float::from_double(
              transmission_steps.to_double(),
            ),
            point_shadow_texture_id: transmissive_draw.payload.point_shadow_texture_id,
            point_shadow_enabled: transmissive_draw.payload.point_shadow_enabled,
            point_shadow_depth_bias: transmissive_draw.payload.point_shadow_depth_bias,
          })
        }
        @render.host_gpu_end_pass()
      }
    }
    let wireframe_draws : Array[MeshGpuDrawPayload3d] = []
    for draw_item_index in 0..<draw_items.length() {
      let draw_item = draw_items[draw_item_index]
      let extracted_mesh = meshes[draw_item.extracted_index]
      let mesh = extracted_mesh.payload
      if !render3d_mesh_should_draw_wireframe(extracted_mesh, wireframe_config) {
        continue
      }
      guard render3d_wireframe_mesh_id(mesh.mesh_handle)
        is Some(wireframe_mesh_id) else {
        continue
      }
      let wireframe_color = render3d_mesh_wireframe_color(
        extracted_mesh, wireframe_config,
      )
      let wireframe_material = StandardMaterial::from_color(wireframe_color)
        .with_unlit(true)
        .with_cull_mode(mesh.material.cull_mode)
      guard render3d_mesh_draw_alpha(
          wireframe_material.alpha_mode,
          wireframe_material.base_color.a,
        )
        is Some(wireframe_draw_alpha) else {
        continue
      }
      wireframe_draws.push(
        render3d_build_mesh_gpu_draw_payload(
          wireframe_mesh_id,
          camera_entity.id,
          camera_entity.generation,
          draw_item_index,
          MESH3D_DRAW_INDIRECT_KIND_NONE,
          -1,
          wireframe_material,
          mesh.transform,
          mesh.previous_transform,
          wireframe_material.base_color.r,
          wireframe_material.base_color.g,
          wireframe_material.base_color.b,
          wireframe_draw_alpha,
          -1,
          -1,
          -1,
          -1,
          -1,
          -1,
          -1,
          -1,
          0.5F,
          0.5F,
          0.0F,
          0.0F,
          0.0F,
          1.5F,
          -1,
          0.0F,
          0.0F,
          -1,
          0.0F,
          0.0F,
          -1,
          -1,
          0.0F,
          @math.Quat::identity(),
          @sprite.Color::white(),
          0.0F,
          0.0F,
          render3d_mesh_draw_flags(extracted_mesh),
        ),
      )
    }
    if transparent_draws.length() > 0 || wireframe_draws.length() > 0 {
      let (
        transparent_viewport_x,
        transparent_viewport_y,
        transparent_viewport_width,
        transparent_viewport_height,
      ) = pass_viewport(scene_target_id)
      render3d_begin_pass_3d(
        target_id=scene_target_id,
        width=view_width_logical,
        height=view_height_logical,
        clear_r=clear_color.r,
        clear_g=clear_color.g,
        clear_b=clear_color.b,
        clear_a=clear_color.a,
        camera.transform,
        camera_pass_projection,
        viewport_x=transparent_viewport_x,
        viewport_y=transparent_viewport_y,
        viewport_width=transparent_viewport_width,
        viewport_height=transparent_viewport_height,
        pass_lighting,
        camera_exposure=camera_exposure_value,
        previous_clip_from_world=camera.previous_clip_from_world,
        point_shadow_texture_id~,
        point_shadow_enabled~,
        point_shadow_depth_bias~,
        environment_diffuse_texture_id=environment_map_state.diffuse_texture_id,
        environment_specular_texture_id=environment_map_state.specular_texture_id,
        environment_map_intensity=environment_map_state.intensity,
        environment_map_rotation=environment_map_state.rotation,
        point_shadow_near~,
        pass_kind=scene_pass_kind,
        clear_enabled=0,
      )
      for draw_payload in transparent_draws {
        render3d_draw_mesh_gpu_payload(draw_payload)
      }
      for wireframe_draw in wireframe_draws {
        render3d_draw_mesh_gpu_payload(wireframe_draw)
      }
      @render.host_gpu_end_pass()
    }
    @app.timeline_trace_end_span(
      @app.TimelineTraceCategory::RenderQueue,
      "execute_3d_camera_main_pass",
      trace_camera_main_pass_start_us,
    )
    let trace_camera_postprocess_start_us = @app.timeline_trace_begin_span(
      @app.TimelineTraceCategory::RenderQueue,
      "execute_3d_camera_postprocess",
    )
    let mut final_source_texture_id = -1
    if motion_blur_active &&
      camera.motion_blur is Some(motion_blur) &&
      velocity_target_id >= 0 {
      if bloom_enabled || tonemap_postprocess_enabled {
        let post_motion_blur_target_id = render3d_transmission_source_target_get_or_create(
          camera_entity, view_width, view_height,
        )
        let (
          post_motion_blur_viewport_x,
          post_motion_blur_viewport_y,
          post_motion_blur_viewport_width,
          post_motion_blur_viewport_height,
        ) = pass_viewport(post_motion_blur_target_id)
        @render.host_gpu_begin_pass(
          target_id=post_motion_blur_target_id,
          width=view_width_logical,
          height=view_height_logical,
          clear_r=clear_color.r,
          clear_g=clear_color.g,
          clear_b=clear_color.b,
          clear_a=clear_color.a,
          camera_x=0.0F,
          camera_y=0.0F,
          camera_rotation=0.0F,
          camera_scale=1.0F,
          viewport_x=post_motion_blur_viewport_x,
          viewport_y=post_motion_blur_viewport_y,
          viewport_width=post_motion_blur_viewport_width,
          viewport_height=post_motion_blur_viewport_height,
          viewport_depth_min~,
          viewport_depth_max~,
          clear_enabled=render3d_pass_clear_enabled_for_target(
            cleared_targets_this_frame, post_motion_blur_target_id, clear_enabled,
          ),
        )
        @render.host_gpu_draw_motion_blur(
          scene_texture_id=scene_target_id,
          velocity_texture_id=velocity_target_id,
          shutter_angle=motion_blur.shutter_angle,
          samples=motion_blur.samples,
        )
        @render.host_gpu_end_pass()
        final_source_texture_id = post_motion_blur_target_id
      } else {
        let (
          motion_blur_present_viewport_x,
          motion_blur_present_viewport_y,
          motion_blur_present_viewport_width,
          motion_blur_present_viewport_height,
        ) = pass_viewport(camera.target_id)
        @render.host_gpu_begin_pass(
          target_id=camera.target_id,
          width=view_width_logical,
          height=view_height_logical,
          clear_r=clear_color.r,
          clear_g=clear_color.g,
          clear_b=clear_color.b,
          clear_a=clear_color.a,
          camera_x=0.0F,
          camera_y=0.0F,
          camera_rotation=0.0F,
          camera_scale=1.0F,
          viewport_x=motion_blur_present_viewport_x,
          viewport_y=motion_blur_present_viewport_y,
          viewport_width=motion_blur_present_viewport_width,
          viewport_height=motion_blur_present_viewport_height,
          viewport_depth_min~,
          viewport_depth_max~,
          clear_enabled=render3d_pass_clear_enabled_for_target(
            cleared_targets_this_frame,
            camera.target_id,
            clear_enabled,
          ),
        )
        @render.host_gpu_draw_motion_blur(
          scene_texture_id=scene_target_id,
          velocity_texture_id=velocity_target_id,
          shutter_angle=motion_blur.shutter_angle,
          samples=motion_blur.samples,
        )
        @render.host_gpu_end_pass()
      }
    } else if scene_target_id != camera.target_id {
      final_source_texture_id = scene_target_id
    }
    if bloom_enabled || tonemap_postprocess_enabled || auto_exposure_enabled {
      let postprocess_source_texture_id = if final_source_texture_id >= 0 {
        final_source_texture_id
      } else {
        scene_target_id
      }
      if postprocess_source_texture_id >= 0 {
        if camera.camera3d.auto_exposure is Some(auto_exposure_settings) {
          let (
            auto_exposure_viewport_x,
            auto_exposure_viewport_y,
            auto_exposure_viewport_width,
            auto_exposure_viewport_height,
          ) = pass_viewport(camera.target_id)
          @render.host_gpu_begin_pass(
            target_id=camera.target_id,
            width=view_width_logical,
            height=view_height_logical,
            clear_r=clear_color.r,
            clear_g=clear_color.g,
            clear_b=clear_color.b,
            clear_a=clear_color.a,
            camera_x=0.0F,
            camera_y=0.0F,
            camera_rotation=0.0F,
            camera_scale=1.0F,
            viewport_x=auto_exposure_viewport_x,
            viewport_y=auto_exposure_viewport_y,
            viewport_width=auto_exposure_viewport_width,
            viewport_height=auto_exposure_viewport_height,
            viewport_depth_min~,
            viewport_depth_max~,
            clear_enabled=render3d_pass_clear_enabled_for_target(
              cleared_targets_this_frame,
              camera.target_id,
              clear_enabled,
            ),
          )
          render3d_apply_camera_auto_exposure(
            world,
            camera_entity,
            auto_exposure_settings,
            camera.color_grading,
            postprocess_source_texture_id,
            view_width_logical,
            view_height_logical,
            delta_seconds,
          )
          @render.host_gpu_end_pass()
        }
        if bloom_enabled && camera.bloom is Some(bloom) {
          let (
            bloom_viewport_x,
            bloom_viewport_y,
            bloom_viewport_width,
            bloom_viewport_height,
          ) = pass_viewport(camera.target_id)
          @render.host_gpu_begin_pass(
            target_id=camera.target_id,
            width=view_width_logical,
            height=view_height_logical,
            clear_r=clear_color.r,
            clear_g=clear_color.g,
            clear_b=clear_color.b,
            clear_a=clear_color.a,
            camera_x=0.0F,
            camera_y=0.0F,
            camera_rotation=0.0F,
            camera_scale=1.0F,
            viewport_x=bloom_viewport_x,
            viewport_y=bloom_viewport_y,
            viewport_width=bloom_viewport_width,
            viewport_height=bloom_viewport_height,
            viewport_depth_min~,
            viewport_depth_max~,
            clear_enabled=render3d_pass_clear_enabled_for_target(
              cleared_targets_this_frame,
              camera.target_id,
              clear_enabled,
            ),
          )
          render3d_draw_camera_bloom_stage(
            postprocess_source_texture_id, bloom, view_width_logical, view_height_logical,
          )
          @render.host_gpu_end_pass()
        }
        let postprocess_stage_count = (if effect_stack_postprocess_enabled {
            1
          } else {
            0
          }) +
          (if custom_post_process_enabled { 1 } else { 0 }) +
          (if tonemapping_stage_enabled { 1 } else { 0 }) +
          (if fxaa_postprocess_enabled { 1 } else { 0 })
        if postprocess_stage_count > 0 {
          let stage_ping_target_id = render3d_transmission_source_target_get_or_create(
            camera_entity, view_width, view_height,
          )
          let mut current_source_texture_id = postprocess_source_texture_id
          let mut stage_index = 0
          if effect_stack_postprocess_enabled {
            let stage_target_id = render3d_postprocess_stage_target(
              current_source_texture_id,
              scene_target_id,
              stage_ping_target_id,
              camera.target_id,
              stage_index,
              postprocess_stage_count,
            )
            let (
              effect_stack_viewport_x,
              effect_stack_viewport_y,
              effect_stack_viewport_width,
              effect_stack_viewport_height,
            ) = pass_viewport(stage_target_id)
            @render.host_gpu_begin_pass(
              target_id=stage_target_id,
              width=view_width_logical,
              height=view_height_logical,
              clear_r=clear_color.r,
              clear_g=clear_color.g,
              clear_b=clear_color.b,
              clear_a=clear_color.a,
              camera_x=0.0F,
              camera_y=0.0F,
              camera_rotation=0.0F,
              camera_scale=1.0F,
              viewport_x=effect_stack_viewport_x,
              viewport_y=effect_stack_viewport_y,
              viewport_width=effect_stack_viewport_width,
              viewport_height=effect_stack_viewport_height,
              viewport_depth_min~,
              viewport_depth_max~,
              clear_enabled=render3d_pass_clear_enabled_for_target(
                cleared_targets_this_frame, stage_target_id, clear_enabled,
              ),
            )
            render3d_draw_camera_effect_stack_stage(
              current_source_texture_id,
              camera.chromatic_aberration,
              camera.vignette,
              view_width_logical,
              view_height_logical,
            )
            @render.host_gpu_end_pass()
            current_source_texture_id = stage_target_id
            stage_index = stage_index + 1
          }
          if custom_post_process_enabled {
            let stage_target_id = render3d_postprocess_stage_target(
              current_source_texture_id,
              scene_target_id,
              stage_ping_target_id,
              camera.target_id,
              stage_index,
              postprocess_stage_count,
            )
            let (
              custom_postprocess_viewport_x,
              custom_postprocess_viewport_y,
              custom_postprocess_viewport_width,
              custom_postprocess_viewport_height,
            ) = pass_viewport(stage_target_id)
            @render.host_gpu_begin_pass(
              target_id=stage_target_id,
              width=view_width_logical,
              height=view_height_logical,
              clear_r=clear_color.r,
              clear_g=clear_color.g,
              clear_b=clear_color.b,
              clear_a=clear_color.a,
              camera_x=0.0F,
              camera_y=0.0F,
              camera_rotation=0.0F,
              camera_scale=1.0F,
              viewport_x=custom_postprocess_viewport_x,
              viewport_y=custom_postprocess_viewport_y,
              viewport_width=custom_postprocess_viewport_width,
              viewport_height=custom_postprocess_viewport_height,
              viewport_depth_min~,
              viewport_depth_max~,
              clear_enabled=render3d_pass_clear_enabled_for_target(
                cleared_targets_this_frame, stage_target_id, clear_enabled,
              ),
            )
            render3d_draw_camera_custom_post_process_stage(
              current_source_texture_id,
              camera.custom_post_process3d,
              view_width_logical,
              view_height_logical,
            )
            @render.host_gpu_end_pass()
            current_source_texture_id = stage_target_id
            stage_index = stage_index + 1
          }
          if tonemapping_stage_enabled {
            let stage_target_id = render3d_postprocess_stage_target(
              current_source_texture_id,
              scene_target_id,
              stage_ping_target_id,
              camera.target_id,
              stage_index,
              postprocess_stage_count,
            )
            let (
              tonemapping_viewport_x,
              tonemapping_viewport_y,
              tonemapping_viewport_width,
              tonemapping_viewport_height,
            ) = pass_viewport(stage_target_id)
            @render.host_gpu_begin_pass(
              target_id=stage_target_id,
              width=view_width_logical,
              height=view_height_logical,
              clear_r=clear_color.r,
              clear_g=clear_color.g,
              clear_b=clear_color.b,
              clear_a=clear_color.a,
              camera_x=0.0F,
              camera_y=0.0F,
              camera_rotation=0.0F,
              camera_scale=1.0F,
              viewport_x=tonemapping_viewport_x,
              viewport_y=tonemapping_viewport_y,
              viewport_width=tonemapping_viewport_width,
              viewport_height=tonemapping_viewport_height,
              viewport_depth_min~,
              viewport_depth_max~,
              clear_enabled=render3d_pass_clear_enabled_for_target(
                cleared_targets_this_frame, stage_target_id, clear_enabled,
              ),
            )
            if camera.camera3d.auto_exposure is Some(_) {
              @render.host_gpu_activate_auto_exposure_view_state(
                view_key_hi=camera_entity.id,
                view_key_lo=camera_entity.generation,
              )
            }
            render3d_draw_camera_tonemapping_stage(
              world,
              current_source_texture_id,
              effective_exposure,
              camera.tonemapping,
              camera.deband_dither,
              camera.color_grading,
              camera.hdr_enabled,
              view_width_logical,
              view_height_logical,
            )
            @render.host_gpu_end_pass()
            current_source_texture_id = stage_target_id
            stage_index = stage_index + 1
          }
          if fxaa_postprocess_enabled {
            let stage_target_id = render3d_postprocess_stage_target(
              current_source_texture_id,
              scene_target_id,
              stage_ping_target_id,
              camera.target_id,
              stage_index,
              postprocess_stage_count,
            )
            let (
              fxaa_viewport_x,
              fxaa_viewport_y,
              fxaa_viewport_width,
              fxaa_viewport_height,
            ) = pass_viewport(stage_target_id)
            @render.host_gpu_begin_pass(
              target_id=stage_target_id,
              width=view_width_logical,
              height=view_height_logical,
              clear_r=clear_color.r,
              clear_g=clear_color.g,
              clear_b=clear_color.b,
              clear_a=clear_color.a,
              camera_x=0.0F,
              camera_y=0.0F,
              camera_rotation=0.0F,
              camera_scale=1.0F,
              viewport_x=fxaa_viewport_x,
              viewport_y=fxaa_viewport_y,
              viewport_width=fxaa_viewport_width,
              viewport_height=fxaa_viewport_height,
              viewport_depth_min~,
              viewport_depth_max~,
              clear_enabled=render3d_pass_clear_enabled_for_target(
                cleared_targets_this_frame, stage_target_id, clear_enabled,
              ),
            )
            render3d_draw_camera_fxaa_stage(
              current_source_texture_id,
              camera.fxaa,
              view_width_logical,
              view_height_logical,
            )
            @render.host_gpu_end_pass()
          }
        } else if postprocess_source_texture_id != camera.target_id {
          let (
            postprocess_present_viewport_x,
            postprocess_present_viewport_y,
            postprocess_present_viewport_width,
            postprocess_present_viewport_height,
          ) = pass_viewport(camera.target_id)
          @render.host_gpu_begin_pass(
            target_id=camera.target_id,
            width=view_width_logical,
            height=view_height_logical,
            clear_r=clear_color.r,
            clear_g=clear_color.g,
            clear_b=clear_color.b,
            clear_a=clear_color.a,
            camera_x=0.0F,
            camera_y=0.0F,
            camera_rotation=0.0F,
            camera_scale=1.0F,
            viewport_x=postprocess_present_viewport_x,
            viewport_y=postprocess_present_viewport_y,
            viewport_width=postprocess_present_viewport_width,
            viewport_height=postprocess_present_viewport_height,
            viewport_depth_min~,
            viewport_depth_max~,
            clear_enabled=render3d_pass_clear_enabled_for_target(
              cleared_targets_this_frame,
              camera.target_id,
              clear_enabled,
            ),
          )
          if bloom_enabled {
            // Bloom can render through an fp16 intermediate even when camera
            // HDR is disabled. Resolve through the postprocess fullscreen
            // shader to avoid dark fp16->surface blits on this path.
            render3d_draw_camera_tonemapping_stage(
              world,
              postprocess_source_texture_id,
              Some(Exposure::new(0.0F)),
              None,
              None,
              None,
              true,
              view_width_logical,
              view_height_logical,
            )
          } else {
            @render.host_gpu_draw_sprite_uv(
              texture_id=postprocess_source_texture_id,
              x=0.0F,
              y=0.0F,
              rotation=0.0F,
              scale_x=Float::from_double(view_width_logical.to_double()) /
                128.0F,
              scale_y=Float::from_double(view_height_logical.to_double()) /
                128.0F,
              color_r=1.0F,
              color_g=1.0F,
              color_b=1.0F,
              color_a=1.0F,
              uv_min_x=0.0F,
              uv_min_y=0.0F,
              uv_max_x=1.0F,
              uv_max_y=1.0F,
            )
          }
          @render.host_gpu_end_pass()
        }
      }
    } else if final_source_texture_id >= 0 {
      let (
        final_present_viewport_x,
        final_present_viewport_y,
        final_present_viewport_width,
        final_present_viewport_height,
      ) = pass_viewport(camera.target_id)
      @render.host_gpu_begin_pass(
        target_id=camera.target_id,
        width=view_width_logical,
        height=view_height_logical,
        clear_r=clear_color.r,
        clear_g=clear_color.g,
        clear_b=clear_color.b,
        clear_a=clear_color.a,
        camera_x=0.0F,
        camera_y=0.0F,
        camera_rotation=0.0F,
        camera_scale=1.0F,
        viewport_x=final_present_viewport_x,
        viewport_y=final_present_viewport_y,
        viewport_width=final_present_viewport_width,
        viewport_height=final_present_viewport_height,
        viewport_depth_min~,
        viewport_depth_max~,
        clear_enabled=render3d_pass_clear_enabled_for_target(
          cleared_targets_this_frame,
          camera.target_id,
          clear_enabled,
        ),
      )
      @render.host_gpu_draw_sprite_uv(
        texture_id=final_source_texture_id,
        x=0.0F,
        y=0.0F,
        rotation=0.0F,
        scale_x=Float::from_double(view_width_logical.to_double()) / 128.0F,
        scale_y=Float::from_double(view_height_logical.to_double()) / 128.0F,
        color_r=1.0F,
        color_g=1.0F,
        color_b=1.0F,
        color_a=1.0F,
        uv_min_x=0.0F,
        uv_min_y=0.0F,
        uv_max_x=1.0F,
        uv_max_y=1.0F,
      )
      @render.host_gpu_end_pass()
    }
    @app.timeline_trace_end_span(
      @app.TimelineTraceCategory::RenderQueue,
      "execute_3d_camera_postprocess",
      trace_camera_postprocess_start_us,
    )
  }
  @app.timeline_trace_end_span(
    @app.TimelineTraceCategory::RenderQueue,
    "execute_3d_render_cameras",
    trace_render_cameras_start_us,
  )
  camera_motion_blur_history_sync(next_camera_motion_blur_history)
  let phase_state_ref = render3d_phase_state_ref_or_abort(world)
  phase_state_ref.val.prepared_camera_order.clear()
  finish_execute()
}
