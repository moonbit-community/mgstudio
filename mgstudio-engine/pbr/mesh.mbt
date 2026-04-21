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
  let assets_ref = @asset.asset_assets_ref_mut_or_abort()
  Ref::new(assets_ref.peek())
}

///|
pub fn mesh_assets_mut_or_abort() -> Ref[@asset.Assets[@mesh.Mesh]] {
  let assets_ref = @sprite.mesh_assets_mut_or_abort()
  Ref::new(assets_ref.peek())
}

///|
struct Render3dInternalAssetsState {
  mut skybox_proxy_mesh : @asset.Handle[@mesh.Mesh]?
}

///|
fn Render3dInternalAssetsState::new() -> Render3dInternalAssetsState {
  Render3dInternalAssetsState::{ skybox_proxy_mesh: None }
}

///|
fn render3d_internal_assets_ref(
  world : @ecs.World,
) -> Ref[Render3dInternalAssetsState]? {
  match (try! world.get_resource_mut(ecs_key_internal_assets)) {
    Some(state) => Some(Ref::new(state.peek()))
    None => None
  }
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
      internal_assets.val.skybox_proxy_mesh = Some(mesh.mesh())
      mesh.mesh()
    }
  }
  @sprite_render.render2d_upload_mesh_handle(handle)
}

///|
pub type ForwardDecal = @pbr_decal.ForwardDecal

///|
pub type ClusteredDecal = @pbr_decal.ClusteredDecal

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
pub type SunDisk = @light.SunDisk

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
  guard @sprite.render_mesh_asset_get(mesh3d.mesh()) is Some(mesh_asset) else {
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
  let mesh_position = if visibility_range.use_aabb() {
    match mesh_aabb_center_world {
      Some(center) => center
      None => mesh_transform.translation
    }
  } else {
    mesh_transform.translation
  }
  let to_mesh = mesh_position.sub(camera_transform.translation)
  let distance = to_mesh.length()
  visibility_range.is_visible_at_all(distance)
}

///|
const RENDER3D_MORPH_UNIFORM_STRIDE_WEIGHTS : Int = 64

///|
fn render3d_morph_entity_key(entity : @core.Entity) -> UInt64 {
  let hi = entity.id.reinterpret_as_uint().to_uint64()
  let lo = entity.generation.reinterpret_as_uint().to_uint64() & 0xFFFF_FFFFUL
  (hi << 32) | lo
}

///|
fn render3d_morph_is_visible(
  source_world : @ecs.World,
  entity : @core.Entity,
) -> Bool {
  if (try! source_world.get_by_key(entity, @visibility.ecs_key_view_visibility))
    is Some(view_visibility) {
    view_visibility.is_visible()
  } else {
    true
  }
}

///|
fn render3d_resolved_morph_weights(
  source_world : @ecs.World,
  entity : @core.Entity,
) -> Array[Float] {
  let animation_weights : @animation.AnimationWeights? = try! source_world
    .entity(entity)
    .get()
  let morph_weights_component : @mesh.MorphWeights? = try! source_world
    .entity(entity)
    .get()
  match animation_weights {
    Some(weights) => {
      let values = weights.values()
      try! source_world.set_by_key(
        entity,
        @mesh.MorphWeights::component(),
        @mesh.MorphWeights::new(values),
      )
      values
    }
    None =>
      match morph_weights_component {
        Some(weights) => weights.values()
        None => []
      }
  }
}

///|
fn render3d_push_morph_weights_to_uniform_buffer(
  uniform_weights : Array[Float],
  weights : Array[Float],
) -> UInt {
  let start = uniform_weights.length()
  let normalized = @pbr_render.render3d_normalize_morph_weights(weights)
  let limit = if normalized.length() < RENDER3D_MORPH_UNIFORM_STRIDE_WEIGHTS {
    normalized.length()
  } else {
    RENDER3D_MORPH_UNIFORM_STRIDE_WEIGHTS
  }
  for index in 0..<limit {
    uniform_weights.push(normalized[index])
  }
  let target_len = start + RENDER3D_MORPH_UNIFORM_STRIDE_WEIGHTS
  while uniform_weights.length() < target_len {
    uniform_weights.push(0.0F)
  }
  start.reinterpret_as_uint() * 4U
}

///|
fn render3d_read_morph_weights_from_uniform_buffer(
  uniform_weights : Array[Float],
  byte_offset : UInt,
) -> Array[Float] {
  let start = (byte_offset / 4U).reinterpret_as_int()
  let end = start + RENDER3D_MORPH_UNIFORM_STRIDE_WEIGHTS
  let clamped_end = if end < uniform_weights.length() {
    end
  } else {
    uniform_weights.length()
  }
  let values : Array[Float] = []
  if start >= clamped_end {
    return values
  }
  for index in start..<clamped_end {
    values.push(uniform_weights[index])
  }
  values
}

///|
fn render3d_clone_mesh3d_geometry(
  geometry : @mesh.Mesh3dGeometry,
) -> @mesh.Mesh3dGeometry {
  let positions : Array[@math.Vec3] = []
  for position in geometry.positions {
    positions.push(position)
  }
  let uvs : Array[@math.Vec2] = []
  for uv in geometry.uvs {
    uvs.push(uv)
  }
  let indices = match geometry.indices {
    Some(existing) => {
      let next : Array[Int] = []
      for index in existing {
        next.push(index)
      }
      Some(next)
    }
    None => None
  }
  let colors = match geometry.colors {
    Some(existing) => {
      let next : Array[@math.Vec4] = []
      for color in existing {
        next.push(color)
      }
      Some(next)
    }
    None => None
  }
  let mut cloned = @mesh.Mesh3dGeometry::new_with_topology(
    positions,
    uvs,
    indices,
    geometry.topology,
  ).with_colors(colors)
  if geometry.joint_indices is Some(joint_indices) {
    let copied_indices : Array[@mesh.MeshJointIndices] = []
    for joint_index in joint_indices {
      copied_indices.push(joint_index)
    }
    let copied_weights = match geometry.joint_weights {
      Some(existing) => {
        let next : Array[@math.Vec4] = []
        for weight in existing {
          next.push(weight)
        }
        Some(next)
      }
      None => None
    }
    cloned = cloned.with_joint_data(Some(copied_indices), copied_weights)
  } else if geometry.joint_weights is Some(existing) {
    let next : Array[@math.Vec4] = []
    for weight in existing {
      next.push(weight)
    }
    cloned = cloned.with_joint_data(None, Some(next))
  }
  if geometry.morph_target_positions is Some(morph_targets) {
    let copied_targets : Array[Array[@math.Vec3]] = []
    for morph_target in morph_targets {
      let copied_positions : Array[@math.Vec3] = []
      for position in morph_target {
        copied_positions.push(position)
      }
      copied_targets.push(copied_positions)
    }
    let copied_names = match geometry.morph_target_names {
      Some(existing) => {
        let next : Array[String] = []
        for name in existing {
          next.push(name)
        }
        Some(next)
      }
      None => None
    }
    cloned = cloned.with_morph_targets(
      Some(copied_targets),
      morph_target_names=copied_names,
    )
  }
  for attribute in geometry.custom_attributes_vec3 {
    let values : Array[@math.Vec3] = []
    for value in attribute.values() {
      values.push(value)
    }
    cloned = cloned.with_custom_attribute_vec3(attribute.name(), values)
  }
  if geometry.tangents is Some(existing) {
    let copied : Array[@math.Vec4] = []
    for tangent in existing {
      copied.push(tangent)
    }
    ignore(cloned.replace_tangents(Some(copied)))
  }
  cloned
}

///|
fn render3d_apply_morph_targets(
  base_positions : Array[@math.Vec3],
  morph_targets : Array[Array[@math.Vec3]],
  weights : Array[Float],
) -> Array[@math.Vec3] {
  let positions : Array[@math.Vec3] = []
  for position in base_positions {
    positions.push(position)
  }
  let limit = if morph_targets.length() < weights.length() {
    morph_targets.length()
  } else {
    weights.length()
  }
  for morph_index in 0..<limit {
    let weight = weights[morph_index]
    if weight == 0.0F {
      continue
    }
    let morph_target = morph_targets[morph_index]
    let vertex_limit = if morph_target.length() < positions.length() {
      morph_target.length()
    } else {
      positions.length()
    }
    for vertex_index in 0..<vertex_limit {
      positions[vertex_index] = @math.Vec3::add(
        positions[vertex_index],
        @math.Vec3::mul_scalar(morph_target[vertex_index], weight),
      )
    }
  }
  positions
}

///|
pub fn render3d_extract_morphs(
  source_world : @ecs.World,
  morph_indices_ref : Ref[@pbr_render.MorphIndices],
  morph_uniforms_ref : Ref[@pbr_render.MorphUniforms],
) -> Unit {
  @pbr_render.morph_indices_swap_and_reset(morph_indices_ref)
  @pbr_render.morph_uniforms_swap_and_reset(morph_uniforms_ref)
  let mesh_query : @ecs.Query[
    (@core.Entity, @ecs.Comp[Mesh3d], @ecs.Comp[@mesh.MorphTargetMesh]),
    @ecs.All,
  ] = @ecs.query(source_world)
  try! mesh_query.view(fn(_entity, data) {
    let (entity, _mesh_component, _morph_target_mesh_component) = data
    if !render3d_morph_is_visible(source_world, entity) {
      return
    }
    let active_morph_weights = render3d_resolved_morph_weights(
      source_world, entity,
    )
    let uniform_offset = render3d_push_morph_weights_to_uniform_buffer(
      morph_uniforms_ref.val.current_buffer,
      active_morph_weights,
    )
    morph_indices_ref.val.current.set(
      render3d_morph_entity_key(entity),
      uniform_offset,
    )
  })
}

///|
pub fn render3d_prepare_morphs(
  source_world : @ecs.World,
  morph_indices_ref : Ref[@pbr_render.MorphIndices],
  morph_uniforms_ref : Ref[@pbr_render.MorphUniforms],
) -> Unit {
  let mesh_query : @ecs.Query[
    (@core.Entity, @ecs.Comp[Mesh3d], @ecs.Comp[@mesh.MorphTargetMesh]),
    @ecs.All,
  ] = @ecs.query(source_world)
  let mesh_assets_ref = mesh_assets_mut_or_abort()

  try! mesh_query.view(fn(_entity, data) {
    let (entity, mesh_component, morph_target_mesh_component) = data
    let entity_key = render3d_morph_entity_key(entity)
    let morph_weights_offset = match
      morph_indices_ref.val.current.get(entity_key) {
      Some(offset) => offset
      None => return
    }
    let source_mesh_handle = morph_target_mesh_component.value().source_mesh()
    let instance_mesh_handle = mesh_component.value().mesh()
    let source_mesh = match mesh_assets_ref.val.get(source_mesh_handle) {
      Some(value) => value
      None => return
    }
    let source_geometry = match source_mesh.as_3d_geometry() {
      Some(value) => value
      None => return
    }

    let active_morph_weights = render3d_read_morph_weights_from_uniform_buffer(
      morph_uniforms_ref.val.current_buffer,
      morph_weights_offset,
    )

    let mut positions = source_geometry.positions
    if source_geometry.morph_target_positions() is Some(morph_targets) &&
      active_morph_weights.length() > 0 {
      positions = render3d_apply_morph_targets(
        positions, morph_targets, active_morph_weights,
      )
    }

    let updated_geometry = render3d_clone_mesh3d_geometry(source_geometry)
    guard updated_geometry.replace_positions(positions) else { return }
    guard source_mesh.with_3d_geometry(updated_geometry) is Some(updated_mesh) else {
      return
    }
    ignore(mesh_assets_ref.val.set(instance_mesh_handle, updated_mesh))
  })
}

///|
pub fn render3d_sync_and_apply_deformed_meshes(world : @ecs.World) -> Unit {
  let morph_indices_ref = @pbr_render.morph_indices_ref_or_abort(world)
  let morph_uniforms_ref = @pbr_render.morph_uniforms_ref_or_abort(world)
  render3d_extract_morphs(world, morph_indices_ref, morph_uniforms_ref)
  render3d_prepare_morphs(world, morph_indices_ref, morph_uniforms_ref)
}
