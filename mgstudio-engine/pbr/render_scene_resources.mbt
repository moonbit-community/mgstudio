// Copyright 2025 International Digital Economy Academy
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
priv struct MotionBlurTargetsEntry {
  entity : @core.Entity
  width : Int
  height : Int
  sample_count : Int
  depth_usage_bits : Int
  scene_target_id : Int
  velocity_target_id : Int
  depth_target_id : Int
  normal_target_id : Int
  deferred_target_id : Int
  deferred_lighting_pass_id_target_id : Int
}

///|
priv struct PrepassTargetsEntry {
  entity : @core.Entity
  width : Int
  height : Int
  sample_count : Int
  depth_usage_bits : Int
  depth_target_id : Int
  normal_target_id : Int
  deferred_target_id : Int
  deferred_lighting_pass_id_target_id : Int
}

///|
priv struct Render3dPrepassTargetIds {
  depth_texture_id : Int
  normal_texture_id : Int
  deferred_texture_id : Int
  deferred_lighting_pass_id_texture_id : Int
}

///|
priv struct TransmissionSourceTargetsEntry {
  entity : @core.Entity
  width : Int
  height : Int
  source_target_id : Int
}

///|
priv struct PostProcessPingTargetsEntry {
  entity : @core.Entity
  width : Int
  height : Int
  target_id : Int
}

///|
priv struct Render3dSceneTargetsState {
  mut motion_blur_targets : Array[MotionBlurTargetsEntry]
  mut prepass_targets : Array[PrepassTargetsEntry]
  mut transmission_source_targets : Array[TransmissionSourceTargetsEntry]
  mut postprocess_ping_targets : Array[PostProcessPingTargetsEntry]
}

///|
let render3d_scene_targets_state_key : @ecs.ResourceKey[
  Render3dSceneTargetsState,
] = @ecs.register_resource(debug_name="mgstudio.render3d.scene_targets_state")

///|
impl @app.Resource for Render3dSceneTargetsState with fn resource() {
  render3d_scene_targets_state_key
}

///|
fn render3d_scene_targets_state_mut_or_init(
  world : @ecs.World,
) -> @ecs.ResourceMut[Render3dSceneTargetsState] {
  if world.get_resource(Render3dSceneTargetsState::resource()) is None {
    world.insert_resource(Render3dSceneTargetsState::resource(), {
      motion_blur_targets: [],
      prepass_targets: [],
      transmission_source_targets: [],
      postprocess_ping_targets: [],
    })
  }
  match world.get_resource_mut(Render3dSceneTargetsState::resource()) {
    Some(state) => state
    None => abort("Missing Render3dSceneTargetsState resource")
  }
}

///|
fn render3d_prepass_targets_get_or_create(
  world : @ecs.World,
  entity : @core.Entity,
  width : Int,
  height : Int,
  sample_count : Int,
  depth_texture_usages : Camera3dDepthTextureUsage,
  normal_prepass_enabled : Bool,
  deferred_prepass_enabled : Bool,
) -> Render3dPrepassTargetIds {
  let scene_targets_state = render3d_scene_targets_state_mut_or_init(world)
  let prepass_targets = scene_targets_state.peek().prepass_targets
  let safe_sample_count = if sample_count <= 1 { 1 } else { sample_count }
  let depth_usage_bits = depth_texture_usages.to_image_usage_bits()
  for item in prepass_targets {
    if item.entity.id == entity.id &&
      item.entity.generation == entity.generation &&
      item.width == width &&
      item.height == height &&
      item.sample_count == safe_sample_count &&
      item.depth_usage_bits == depth_usage_bits {
      if (!normal_prepass_enabled || item.normal_target_id >= 0) &&
        (
          !deferred_prepass_enabled ||
          (
            item.deferred_target_id >= 0 &&
            item.deferred_lighting_pass_id_target_id >= 0
          )
        ) {
        return Render3dPrepassTargetIds::{
          depth_texture_id: item.depth_target_id,
          normal_texture_id: if normal_prepass_enabled {
            item.normal_target_id
          } else {
            -1
          },
          deferred_texture_id: if deferred_prepass_enabled {
            item.deferred_target_id
          } else {
            -1
          },
          deferred_lighting_pass_id_texture_id: if deferred_prepass_enabled {
            item.deferred_lighting_pass_id_target_id
          } else {
            -1
          },
        }
      }
    }
  }
  let depth_target_id = @render.host_gpu_create_depth_prepass_target(
    width~,
    height~,
    sample_count=safe_sample_count,
    usage_bits=depth_usage_bits,
  )
  let normal_target_id = if normal_prepass_enabled {
    @render.host_gpu_create_normal_prepass_target_rgb10a2unorm(
      width~,
      height~,
      sample_count=safe_sample_count,
    )
  } else {
    -1
  }
  let deferred_target_id = if deferred_prepass_enabled {
    @render.host_gpu_create_deferred_prepass_target_rgba32uint(
      width~,
      height~,
      sample_count=safe_sample_count,
    )
  } else {
    -1
  }
  let deferred_lighting_pass_id_target_id = if deferred_prepass_enabled {
    @render.host_gpu_create_deferred_lighting_pass_id_target_r8uint(
      width~,
      height~,
      sample_count=safe_sample_count,
    )
  } else {
    -1
  }
  let next : Array[PrepassTargetsEntry] = []
  let mut replaced = false
  for item in prepass_targets {
    if item.entity.id == entity.id &&
      item.entity.generation == entity.generation {
      if !replaced {
        next.push({
          entity,
          width,
          height,
          sample_count: safe_sample_count,
          depth_usage_bits,
          depth_target_id,
          normal_target_id,
          deferred_target_id,
          deferred_lighting_pass_id_target_id,
        })
        replaced = true
      }
    } else {
      next.push(item)
    }
  }
  if !replaced {
    next.push({
      entity,
      width,
      height,
      sample_count: safe_sample_count,
      depth_usage_bits,
      depth_target_id,
      normal_target_id,
      deferred_target_id,
      deferred_lighting_pass_id_target_id,
    })
  }
  scene_targets_state.modify(fn(state) { state.prepass_targets = next })
  Render3dPrepassTargetIds::{
    depth_texture_id: depth_target_id,
    normal_texture_id: normal_target_id,
    deferred_texture_id: deferred_target_id,
    deferred_lighting_pass_id_texture_id: deferred_lighting_pass_id_target_id,
  }
}

///|
fn render3d_motion_blur_targets_get_or_create(
  world : @ecs.World,
  entity : @core.Entity,
  width : Int,
  height : Int,
  sample_count : Int,
  depth_texture_usages : Camera3dDepthTextureUsage,
  normal_prepass_enabled? : Bool = false,
  deferred_prepass_enabled? : Bool = false,
) -> (Int, Int, Int, Int, Int, Int) {
  let scene_targets_state = render3d_scene_targets_state_mut_or_init(world)
  let motion_blur_targets = scene_targets_state.peek().motion_blur_targets
  let safe_sample_count = if sample_count <= 1 { 1 } else { sample_count }
  let depth_usage_bits = depth_texture_usages.to_image_usage_bits()
  for item in motion_blur_targets {
    if item.entity.id == entity.id &&
      item.entity.generation == entity.generation &&
      item.width == width &&
      item.height == height &&
      item.sample_count == safe_sample_count &&
      item.depth_usage_bits == depth_usage_bits {
      if (!normal_prepass_enabled || item.normal_target_id >= 0) &&
        (
          !deferred_prepass_enabled ||
          (
            item.deferred_target_id >= 0 &&
            item.deferred_lighting_pass_id_target_id >= 0
          )
        ) {
        return (
          item.scene_target_id,
          item.velocity_target_id,
          item.depth_target_id,
          if normal_prepass_enabled {
            item.normal_target_id
          } else {
            -1
          },
          if deferred_prepass_enabled {
            item.deferred_target_id
          } else {
            -1
          },
          if deferred_prepass_enabled {
            item.deferred_lighting_pass_id_target_id
          } else {
            -1
          },
        )
      }
    }
  }
  let scene_target_id = @render.host_gpu_create_render_target_rgba16f(
    width~,
    height~,
    nearest=false,
    sample_count=safe_sample_count,
  )
  let velocity_target_id = @render.host_gpu_create_motion_vector_prepass_target_rg16f(
    width~,
    height~,
    nearest=false,
    sample_count=safe_sample_count,
  )
  let depth_target_id = @render.host_gpu_create_depth_prepass_target(
    width~,
    height~,
    sample_count=safe_sample_count,
    usage_bits=depth_usage_bits,
  )
  let normal_target_id = if normal_prepass_enabled {
    @render.host_gpu_create_normal_prepass_target_rgb10a2unorm(
      width~,
      height~,
      sample_count=safe_sample_count,
    )
  } else {
    -1
  }
  let deferred_target_id = if deferred_prepass_enabled {
    @render.host_gpu_create_deferred_prepass_target_rgba32uint(
      width~,
      height~,
      sample_count=safe_sample_count,
    )
  } else {
    -1
  }
  let deferred_lighting_pass_id_target_id = if deferred_prepass_enabled {
    @render.host_gpu_create_deferred_lighting_pass_id_target_r8uint(
      width~,
      height~,
      sample_count=safe_sample_count,
    )
  } else {
    -1
  }
  let next : Array[MotionBlurTargetsEntry] = []
  let mut replaced = false
  for item in motion_blur_targets {
    if item.entity.id == entity.id &&
      item.entity.generation == entity.generation {
      if !replaced {
        next.push({
          entity,
          width,
          height,
          sample_count: safe_sample_count,
          depth_usage_bits,
          scene_target_id,
          velocity_target_id,
          depth_target_id,
          normal_target_id,
          deferred_target_id,
          deferred_lighting_pass_id_target_id,
        })
        replaced = true
      }
    } else {
      next.push(item)
    }
  }
  if !replaced {
    next.push({
      entity,
      width,
      height,
      sample_count: safe_sample_count,
      depth_usage_bits,
      scene_target_id,
      velocity_target_id,
      depth_target_id,
      normal_target_id,
      deferred_target_id,
      deferred_lighting_pass_id_target_id,
    })
  }
  scene_targets_state.modify(fn(state) { state.motion_blur_targets = next })
  (
    scene_target_id, velocity_target_id, depth_target_id, normal_target_id, deferred_target_id,
    deferred_lighting_pass_id_target_id,
  )
}

///|
fn render3d_transmission_source_target_get_or_create(
  world : @ecs.World,
  entity : @core.Entity,
  width : Int,
  height : Int,
) -> Int {
  let scene_targets_state = render3d_scene_targets_state_mut_or_init(world)
  let transmission_source_targets = scene_targets_state.peek().transmission_source_targets
  for item in transmission_source_targets {
    if item.entity.id == entity.id &&
      item.entity.generation == entity.generation &&
      item.width == width &&
      item.height == height {
      return item.source_target_id
    }
  }
  let source_target_id = @render.host_gpu_create_transmission_source_texture_rgba16f(
    width~,
    height~,
  )
  let next : Array[TransmissionSourceTargetsEntry] = []
  let mut replaced = false
  for item in transmission_source_targets {
    if item.entity.id == entity.id &&
      item.entity.generation == entity.generation {
      if !replaced {
        next.push({ entity, width, height, source_target_id })
        replaced = true
      }
    } else {
      next.push(item)
    }
  }
  if !replaced {
    next.push({ entity, width, height, source_target_id })
  }
  scene_targets_state.modify(fn(state) {
    state.transmission_source_targets = next
  })
  source_target_id
}

///|
fn render3d_postprocess_ping_target_get_or_create(
  world : @ecs.World,
  entity : @core.Entity,
  width : Int,
  height : Int,
) -> Int {
  let scene_targets_state = render3d_scene_targets_state_mut_or_init(world)
  let postprocess_ping_targets = scene_targets_state.peek().postprocess_ping_targets
  for item in postprocess_ping_targets {
    if item.entity.id == entity.id &&
      item.entity.generation == entity.generation &&
      item.width == width &&
      item.height == height {
      return item.target_id
    }
  }
  let target_id = @render.host_gpu_create_render_target_rgba16f(
    width~,
    height~,
    nearest=false,
  )
  let next : Array[PostProcessPingTargetsEntry] = []
  let mut replaced = false
  for item in postprocess_ping_targets {
    if item.entity.id == entity.id &&
      item.entity.generation == entity.generation {
      if !replaced {
        next.push({ entity, width, height, target_id })
        replaced = true
      }
    } else {
      next.push(item)
    }
  }
  if !replaced {
    next.push({ entity, width, height, target_id })
  }
  scene_targets_state.modify(fn(state) { state.postprocess_ping_targets = next })
  target_id
}

///|
fn render3d_copy_texture_to_texture(
  source_texture_id : Int,
  target_texture_id : Int,
) -> Unit {
  if source_texture_id < 0 || target_texture_id < 0 {
    return
  }
  @render.host_gpu_copy_texture_to_texture(
    dst_texture_id=target_texture_id,
    dst_x=0,
    dst_y=0,
    src_texture_id=source_texture_id,
  )
}

///|
priv struct Render3dEnvironmentMapState {
  diffuse_texture_id : Int
  specular_texture_id : Int
  smallest_specular_mip_level : Int
  intensity : Float
  rotation : @math.Quat
  affects_lightmapped_mesh_diffuse : Bool
}

///|
priv struct Render3dLightProbeEntry {
  entity : @core.Entity
  distance_squared : Float
  light_from_world : @math.Affine3
  falloff : @math.Vec3
  bounding_sphere_radius : Float
  parallax_correction_bounds : @math.Vec3
  intensity : Float
  world_position : @math.Vec3
  flags : Int
  diffuse_texture_id : Int
  specular_texture_id : Int
}

///|
priv struct Render3dLightProbeState {
  uniform_bytes : Bytes
  uniform_offset : UInt
  diffuse_texture_ids : Array[Int]
  specular_texture_ids : Array[Int]
  irradiance_volume_texture_ids : Array[Int]
  reflection_probe_entities : Array[@core.Entity]
  irradiance_volume_entities : Array[@core.Entity]
}

///|
pub fn render3d_light_probes_buffer_clear(world : @ecs.World) -> Unit {
  if world.get_resource(@pbr_light_probe.LightProbesBuffer::resource())
    is Some(buffer) {
    buffer.clear()
  }
}

///|
fn render3d_push_view_light_probes_uniform(
  world : @ecs.World,
  camera_entity : @core.Entity,
  uniform_bytes : Bytes,
) -> UInt {
  let buffer = match
    world.get_resource(@pbr_light_probe.LightProbesBuffer::resource()) {
    Some(value) => value
    None => {
      let value = @pbr_light_probe.LightProbesBuffer::LightProbesBuffer()
      world.insert_resource(
        @pbr_light_probe.LightProbesBuffer::resource(),
        value,
      )
      value
    }
  }
  let uniform_offset = buffer.push_uniform_bytes(uniform_bytes)
  try! world.set_by_key(
    camera_entity,
    @pbr_light_probe.ecs_key_view_light_probes_uniform_offset,
    @pbr_light_probe.ViewLightProbesUniformOffset::new(uniform_offset),
  )
  uniform_offset
}

///|
fn render3d_light_probe_binding_arrays_are_usable() -> Bool {
  @render.host_gpu_mesh3d_binding_arrays_are_usable(
    required_storage_textures_per_shader_stage=(@pbr_light_probe.STANDARD_MATERIAL_FRAGMENT_SHADER_MIN_TEXTURE_BINDINGS +
    @pbr_light_probe.MAX_VIEW_LIGHT_PROBES).reinterpret_as_uint(),
    required_binding_array_sampler_elements_per_shader_stage=@pbr_render.RENDER3D_LIGHTMAPS_PER_SLAB.reinterpret_as_uint(),
  )
}

///|
fn render3d_loaded_image_texture_id(
  image_handle : @asset.Handle[@asset.Image]?,
) -> Int? {
  match image_handle {
    Some(handle) => {
      let texture_id = handle.id()
      if texture_id >= 0 && @render.asset_is_texture_loaded(texture_id~) {
        Some(texture_id)
      } else {
        None
      }
    }
    None => None
  }
}

///|
fn render3d_texture_smallest_specular_mip_level(texture_id : Int) -> Int {
  if texture_id < 0 {
    return 0
  }
  match @render_texture.GpuImage::from_texture_id(texture_id) {
    Some(gpu_image) => {
      let mip_count = gpu_image.mip_level_count()
      if mip_count <= 0 {
        0
      } else {
        mip_count - 1
      }
    }
    None => 0
  }
}

///|
fn render3d_camera_environment_map_state(
  camera : ExtractedCamera3d,
) -> Render3dEnvironmentMapState {
  let mut state = Render3dEnvironmentMapState::{
    diffuse_texture_id: -1,
    specular_texture_id: -1,
    smallest_specular_mip_level: 0,
    intensity: 0.0F,
    rotation: @math.Quat::identity(),
    affects_lightmapped_mesh_diffuse: true,
  }
  if camera.payload.environment_map_light is Some(environment_map_light) {
    if render3d_loaded_image_texture_id(environment_map_light.diffuse_map)
      is Some(diffuse_texture_id) &&
      render3d_loaded_image_texture_id(environment_map_light.specular_map)
      is Some(specular_texture_id) {
      state = Render3dEnvironmentMapState::{
        diffuse_texture_id,
        specular_texture_id,
        smallest_specular_mip_level: render3d_texture_smallest_specular_mip_level(
          specular_texture_id,
        ),
        intensity: environment_map_light.intensity,
        rotation: environment_map_light.rotation,
        affects_lightmapped_mesh_diffuse: environment_map_light.affects_lightmapped_mesh_diffuse,
      }
    }
  }
  let mut diffuse_texture_id = state.diffuse_texture_id
  let mut specular_texture_id = state.specular_texture_id
  if diffuse_texture_id < 0 && specular_texture_id >= 0 {
    diffuse_texture_id = specular_texture_id
  }
  if specular_texture_id < 0 && diffuse_texture_id >= 0 {
    specular_texture_id = diffuse_texture_id
  }
  if diffuse_texture_id < 0 || specular_texture_id < 0 {
    Render3dEnvironmentMapState::{
      diffuse_texture_id: -1,
      specular_texture_id: -1,
      smallest_specular_mip_level: 0,
      intensity: 0.0F,
      rotation: @math.Quat::identity(),
      affects_lightmapped_mesh_diffuse: true,
    }
  } else {
    Render3dEnvironmentMapState::{
      ..state,
      diffuse_texture_id,
      specular_texture_id,
      smallest_specular_mip_level: render3d_texture_smallest_specular_mip_level(
        specular_texture_id,
      ),
    }
  }
}

///|
fn render3d_light_probe_u32le_pack(words : Array[UInt]) -> Bytes {
  Bytes::makei(words.length() * 4, index => {
    let word = words[index / 4]
    ((word >> (index % 4 * 8)) & 0xFF).to_byte()
  })
}

///|
fn render3d_light_probe_push_f32(words : Array[UInt], value : Float) -> Unit {
  words.push(value.reinterpret_as_uint())
}

///|
fn render3d_light_probe_push_i32(words : Array[UInt], value : Int) -> Unit {
  words.push(value.reinterpret_as_uint())
}

///|
fn render3d_light_probe_entity_cmp(
  left : @core.Entity,
  right : @core.Entity,
) -> Int {
  let id_cmp = @pbr_render.cmp_int(left.id, right.id)
  if id_cmp != 0 {
    return id_cmp
  }
  @pbr_render.cmp_int(left.generation, right.generation)
}

///|
fn render3d_light_probe_sort(
  probes : Array[Render3dLightProbeEntry],
) -> Array[Render3dLightProbeEntry] {
  probes.sort_by(fn(left, right) {
    let distance_cmp = @pbr_render.cmp_float(
      left.distance_squared,
      right.distance_squared,
    )
    if distance_cmp != 0 {
      return distance_cmp
    }
    render3d_light_probe_entity_cmp(left.entity, right.entity)
  })
  probes
}

///|
fn render3d_light_probe_texture_binding_index(
  diffuse_texture_ids : Array[Int],
  specular_texture_ids : Array[Int],
  diffuse_texture_id : Int,
  specular_texture_id : Int,
) -> Int {
  for index in 0..<diffuse_texture_ids.length() {
    if diffuse_texture_ids[index] == diffuse_texture_id &&
      specular_texture_ids[index] == specular_texture_id {
      return index
    }
  }
  if diffuse_texture_ids.length() >= @pbr_light_probe.MAX_VIEW_LIGHT_PROBES {
    return @pbr_light_probe.MAX_VIEW_LIGHT_PROBES - 1
  }
  let index = diffuse_texture_ids.length()
  diffuse_texture_ids.push(diffuse_texture_id)
  specular_texture_ids.push(specular_texture_id)
  index
}

///|
fn render3d_light_probe_3d_texture_binding_index(
  texture_ids : Array[Int],
  texture_id : Int,
) -> Int {
  for index in 0..<texture_ids.length() {
    if texture_ids[index] == texture_id {
      return index
    }
  }
  if texture_ids.length() >= @pbr_light_probe.MAX_VIEW_LIGHT_PROBES {
    return @pbr_light_probe.MAX_VIEW_LIGHT_PROBES - 1
  }
  let index = texture_ids.length()
  texture_ids.push(texture_id)
  index
}

///|
fn render3d_light_probe_entity_affine(
  world : @ecs.World,
  entity : @core.Entity,
) -> @math.Affine3 {
  match (try! world.get_by_key(entity, @transform.ecs_key_global_transform)) {
    Some(global_transform) => return global_transform.affine()
    None => ()
  }
  match (try! world.get_by_key(entity, @transform.ecs_key_transform)) {
    Some(transform) =>
      @math.Affine3::from_scale_rotation_translation(
        transform.scale,
        transform.rotation,
        transform.translation,
      )
    None => @math.Affine3::identity()
  }
}

///|
fn render3d_light_probe_parallax_bounds(
  parallax_correction : @light.ParallaxCorrection?,
) -> @math.Vec3 {
  match parallax_correction {
    Some(@light.ParallaxCorrection::Auto) => @math.Vec3::splat(0.5F)
    Some(@light.ParallaxCorrection::Custom(bounds)) => bounds
    Some(@light.ParallaxCorrection::None) => @math.Vec3::zero()
    None => @math.Vec3::zero()
  }
}

///|
fn render3d_light_probe_flags(
  environment_map_light : @light.EnvironmentMapLight,
  parallax_correction : @light.ParallaxCorrection?,
) -> Int {
  let mut flags = 0
  if environment_map_light.affects_lightmapped_mesh_diffuse {
    flags = @pbr_light_probe.render_light_probe_flags_insert(
      flags,
      @pbr_light_probe.RENDER_LIGHT_PROBE_FLAG_AFFECTS_LIGHTMAPPED_MESH_DIFFUSE,
    )
  }
  match parallax_correction {
    Some(@light.ParallaxCorrection::Auto)
    | Some(@light.ParallaxCorrection::Custom(_)) =>
      flags = @pbr_light_probe.render_light_probe_flags_insert(
        flags,
        @pbr_light_probe.RENDER_LIGHT_PROBE_FLAG_ENABLE_PARALLAX_CORRECTION,
      )
    Some(@light.ParallaxCorrection::None) | None => ()
  }
  flags
}

///|
fn render3d_camera_visible_reflection_probe_entities(
  world : @ecs.World,
  camera_entity : @core.Entity,
) -> Array[@core.Entity] {
  match
    (try! world.get_by_key(
      camera_entity,
      @light_cluster.VisibleClusterableObjects::component(),
    )) {
    Some(visible) => visible.reflection_probe_entities()
    None => []
  }
}

///|
fn render3d_camera_visible_irradiance_volume_entities(
  world : @ecs.World,
  camera_entity : @core.Entity,
) -> Array[@core.Entity] {
  match
    (try! world.get_by_key(
      camera_entity,
      @light_cluster.VisibleClusterableObjects::component(),
    )) {
    Some(visible) => visible.irradiance_volume_entities()
    None => []
  }
}

///|
fn render3d_light_probe_entry(
  world : @ecs.World,
  camera_transform : @transform.Transform,
  entity : @core.Entity,
  light_probe : @light.LightProbe,
  environment_map_light : @light.EnvironmentMapLight,
) -> Render3dLightProbeEntry? {
  guard render3d_loaded_image_texture_id(environment_map_light.diffuse_map)
    is Some(diffuse_texture_id) else {
    return None
  }
  guard render3d_loaded_image_texture_id(environment_map_light.specular_map)
    is Some(specular_texture_id) else {
    return None
  }
  let world_from_light = render3d_light_probe_entity_affine(world, entity).mul_rotation_translation(
    environment_map_light.rotation,
    @math.Vec3::zero(),
  )
  let light_from_world = world_from_light.inverse()
  let parallax_correction = try! world.get_by_key(
    entity, @light.ecs_key_parallax_correction,
  )
  Some(Render3dLightProbeEntry::{
    entity,
    distance_squared: world_from_light.translation
    .sub(camera_transform.translation)
    .length_squared(),
    light_from_world,
    falloff: light_probe.falloff,
    bounding_sphere_radius: world_from_light.matrix3
    .mul_vec3(@math.Vec3::splat(1.0F))
    .length(),
    parallax_correction_bounds: render3d_light_probe_parallax_bounds(
      parallax_correction,
    ),
    intensity: environment_map_light.intensity,
    world_position: world_from_light.translation,
    flags: render3d_light_probe_flags(
      environment_map_light, parallax_correction,
    ),
    diffuse_texture_id,
    specular_texture_id,
  })
}

///|
fn render3d_irradiance_volume_flags(
  irradiance_volume : @light.IrradianceVolume,
) -> Int {
  if irradiance_volume.affects_lightmapped_meshes {
    @pbr_light_probe.render_light_probe_flags_insert(
      0,
      @pbr_light_probe.RENDER_LIGHT_PROBE_FLAG_AFFECTS_LIGHTMAPPED_MESH_DIFFUSE,
    )
  } else {
    0
  }
}

///|
fn render3d_irradiance_volume_entry(
  world : @ecs.World,
  camera_transform : @transform.Transform,
  entity : @core.Entity,
  light_probe : @light.LightProbe,
  irradiance_volume : @light.IrradianceVolume,
) -> Render3dLightProbeEntry? {
  guard render3d_loaded_image_texture_id(irradiance_volume.voxels)
    is Some(texture_id) else {
    return None
  }
  let world_from_light = render3d_light_probe_entity_affine(world, entity)
  let light_from_world = world_from_light.inverse()
  Some(Render3dLightProbeEntry::{
    entity,
    distance_squared: world_from_light.translation
    .sub(camera_transform.translation)
    .length_squared(),
    light_from_world,
    falloff: light_probe.falloff,
    bounding_sphere_radius: world_from_light.matrix3
    .mul_vec3(@math.Vec3::splat(1.0F))
    .length(),
    parallax_correction_bounds: @math.Vec3::zero(),
    intensity: irradiance_volume.intensity,
    world_position: world_from_light.translation,
    flags: render3d_irradiance_volume_flags(irradiance_volume),
    diffuse_texture_id: texture_id,
    specular_texture_id: texture_id,
  })
}

///|
fn render3d_light_probe_push_entry(
  words : Array[UInt],
  entry : Render3dLightProbeEntry?,
  cubemap_index : Int,
) -> Unit {
  guard entry is Some(entry0) else {
    for _ in 0..<28 {
      words.push(0U)
    }
    return
  }
  let matrix = entry0.light_from_world.matrix3
  let translation = entry0.light_from_world.translation
  render3d_light_probe_push_f32(words, matrix.x_axis.x)
  render3d_light_probe_push_f32(words, matrix.y_axis.x)
  render3d_light_probe_push_f32(words, matrix.z_axis.x)
  render3d_light_probe_push_f32(words, translation.x)
  render3d_light_probe_push_f32(words, matrix.x_axis.y)
  render3d_light_probe_push_f32(words, matrix.y_axis.y)
  render3d_light_probe_push_f32(words, matrix.z_axis.y)
  render3d_light_probe_push_f32(words, translation.y)
  render3d_light_probe_push_f32(words, matrix.x_axis.z)
  render3d_light_probe_push_f32(words, matrix.y_axis.z)
  render3d_light_probe_push_f32(words, matrix.z_axis.z)
  render3d_light_probe_push_f32(words, translation.z)
  render3d_light_probe_push_f32(words, entry0.falloff.x)
  render3d_light_probe_push_f32(words, entry0.falloff.y)
  render3d_light_probe_push_f32(words, entry0.falloff.z)
  render3d_light_probe_push_f32(words, entry0.bounding_sphere_radius)
  render3d_light_probe_push_f32(words, entry0.parallax_correction_bounds.x)
  render3d_light_probe_push_f32(words, entry0.parallax_correction_bounds.y)
  render3d_light_probe_push_f32(words, entry0.parallax_correction_bounds.z)
  render3d_light_probe_push_f32(words, entry0.intensity)
  render3d_light_probe_push_f32(words, entry0.world_position.x)
  render3d_light_probe_push_f32(words, entry0.world_position.y)
  render3d_light_probe_push_f32(words, entry0.world_position.z)
  render3d_light_probe_push_i32(words, cubemap_index)
  words.push(entry0.flags.reinterpret_as_uint())
  words.push(0U)
  words.push(0U)
  words.push(0U)
}

///|
fn render3d_camera_light_probe_state(
  world : @ecs.World,
  camera : ExtractedCamera3d,
  environment_map_state : Render3dEnvironmentMapState,
) -> Render3dLightProbeState {
  let diffuse_texture_ids : Array[Int] = []
  let specular_texture_ids : Array[Int] = []
  let irradiance_volume_texture_ids : Array[Int] = []
  let view_cubemap_index = if environment_map_state.diffuse_texture_id >= 0 &&
    environment_map_state.specular_texture_id >= 0 &&
    environment_map_state.intensity > 0.0F {
    render3d_light_probe_texture_binding_index(
      diffuse_texture_ids,
      specular_texture_ids,
      environment_map_state.diffuse_texture_id,
      environment_map_state.specular_texture_id,
    )
  } else {
    -1
  }
  let probes : Array[Render3dLightProbeEntry] = []
  for
    entity in render3d_camera_visible_reflection_probe_entities(
      world,
      camera.entity.main_entity,
    ) {
    guard (try! world.get_by_key(entity, @light.ecs_key_environment_map_light))
      is Some(environment_map_light) else {
      continue
    }
    guard (try! world.get_by_key(entity, @light.ecs_key_light_probe))
      is Some(light_probe) else {
      continue
    }
    match
      render3d_light_probe_entry(
        world,
        camera.payload.transform,
        entity,
        light_probe,
        environment_map_light,
      ) {
      Some(entry) => probes.push(entry)
      None => ()
    }
  }
  let sorted_probes = render3d_light_probe_sort(probes)
  let irradiance_volumes : Array[Render3dLightProbeEntry] = []
  for
    entity in render3d_camera_visible_irradiance_volume_entities(
      world,
      camera.entity.main_entity,
    ) {
    guard (try! world.get_by_key(entity, @light.ecs_key_irradiance_volume))
      is Some(irradiance_volume) else {
      continue
    }
    guard (try! world.get_by_key(entity, @light.ecs_key_light_probe))
      is Some(light_probe) else {
      continue
    }
    match
      render3d_irradiance_volume_entry(
        world,
        camera.payload.transform,
        entity,
        light_probe,
        irradiance_volume,
      ) {
      Some(entry) => irradiance_volumes.push(entry)
      None => ()
    }
  }
  let sorted_irradiance_volumes = render3d_light_probe_sort(irradiance_volumes)
  let words : Array[UInt] = []
  let probe_cubemap_indices : Array[Int] = []
  let reflection_probe_entities : Array[@core.Entity] = []
  for probe in sorted_probes {
    if probe_cubemap_indices.length() >= @pbr_light_probe.MAX_VIEW_LIGHT_PROBES {
      break
    }
    reflection_probe_entities.push(probe.entity)
    probe_cubemap_indices.push(
      render3d_light_probe_texture_binding_index(
        diffuse_texture_ids,
        specular_texture_ids,
        probe.diffuse_texture_id,
        probe.specular_texture_id,
      ),
    )
  }
  let irradiance_volume_indices : Array[Int] = []
  let irradiance_volume_entities : Array[@core.Entity] = []
  for volume in sorted_irradiance_volumes {
    if irradiance_volume_indices.length() >=
      @pbr_light_probe.MAX_VIEW_LIGHT_PROBES {
      break
    }
    irradiance_volume_entities.push(volume.entity)
    irradiance_volume_indices.push(
      render3d_light_probe_3d_texture_binding_index(
        irradiance_volume_texture_ids,
        volume.diffuse_texture_id,
      ),
    )
  }
  for index in 0..<@pbr_light_probe.MAX_VIEW_LIGHT_PROBES {
    if index < sorted_probes.length() && index < probe_cubemap_indices.length() {
      render3d_light_probe_push_entry(
        words,
        Some(sorted_probes[index]),
        probe_cubemap_indices[index],
      )
    } else {
      render3d_light_probe_push_entry(words, None, -1)
    }
  }
  for index in 0..<@pbr_light_probe.MAX_VIEW_LIGHT_PROBES {
    if index < sorted_irradiance_volumes.length() &&
      index < irradiance_volume_indices.length() {
      render3d_light_probe_push_entry(
        words,
        Some(sorted_irradiance_volumes[index]),
        irradiance_volume_indices[index],
      )
    } else {
      render3d_light_probe_push_entry(words, None, -1)
    }
  }
  words.push(probe_cubemap_indices.length().reinterpret_as_uint())
  words.push(irradiance_volume_indices.length().reinterpret_as_uint())
  render3d_light_probe_push_i32(words, view_cubemap_index)
  words.push(
    environment_map_state.smallest_specular_mip_level.reinterpret_as_uint(),
  )
  let view_rotation = if view_cubemap_index >= 0 {
    environment_map_state.rotation
  } else {
    @math.Quat::identity()
  }
  render3d_light_probe_push_f32(words, -view_rotation.x)
  render3d_light_probe_push_f32(words, -view_rotation.y)
  render3d_light_probe_push_f32(words, -view_rotation.z)
  render3d_light_probe_push_f32(words, view_rotation.w)
  render3d_light_probe_push_f32(
    words,
    if view_cubemap_index >= 0 {
      environment_map_state.intensity
    } else {
      1.0F
    },
  )
  let view_affects_lightmapped_mesh_diffuse = if view_cubemap_index >= 0 {
    environment_map_state.affects_lightmapped_mesh_diffuse
  } else {
    true
  }
  words.push(if view_affects_lightmapped_mesh_diffuse { 1U } else { 0U })
  while words.length() < 512 {
    words.push(0U)
  }
  if @sys.get_env_var("MGSTUDIO_ATMOSPHERE_PARITY_DEBUG") is Some(_) {
    println(
      "[DEBUG-atmosphere-parity] light-probe view_cubemap_index=\{view_cubemap_index} smallest_mip=\{environment_map_state.smallest_specular_mip_level} intensity=\{environment_map_state.intensity} binding_arrays=\{render3d_light_probe_binding_arrays_are_usable()} diffuse_count=\{diffuse_texture_ids.length()} specular_count=\{specular_texture_ids.length()}",
    )
    if diffuse_texture_ids.length() > 0 && specular_texture_ids.length() > 0 {
      println(
        "[DEBUG-atmosphere-parity] light-probe first diffuse=\{diffuse_texture_ids[0]} specular=\{specular_texture_ids[0]}",
      )
    }
  }
  let uniform_bytes = render3d_light_probe_u32le_pack(words)
  let uniform_offset = render3d_push_view_light_probes_uniform(
    world,
    camera.entity.main_entity,
    uniform_bytes,
  )
  let binding_arrays_are_usable = render3d_light_probe_binding_arrays_are_usable()
  let environment_map_entries = @pbr_light_probe.pbr_environment_map_texture_id_entries(
    diffuse_texture_ids,
    specular_texture_ids,
    binding_arrays_are_usable,
    @pbr_light_probe.MAX_VIEW_LIGHT_PROBES,
  )
  let (environment_diffuse_texture_ids, environment_specular_texture_ids) = @pbr_light_probe.pbr_environment_map_texture_id_entries_ids(
    environment_map_entries,
  )
  let irradiance_volume_entries = @pbr_light_probe.pbr_irradiance_volume_texture_id_entries(
    irradiance_volume_texture_ids,
    binding_arrays_are_usable,
    @pbr_light_probe.MAX_VIEW_LIGHT_PROBES,
  )
  Render3dLightProbeState::{
    uniform_bytes,
    uniform_offset,
    diffuse_texture_ids: environment_diffuse_texture_ids,
    specular_texture_ids: environment_specular_texture_ids,
    irradiance_volume_texture_ids: @pbr_light_probe.pbr_irradiance_volume_texture_id_entries_ids(
      irradiance_volume_entries,
    ),
    reflection_probe_entities,
    irradiance_volume_entities,
  }
}

///|
