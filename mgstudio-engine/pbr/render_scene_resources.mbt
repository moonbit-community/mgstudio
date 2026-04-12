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
priv struct MotionBlurHistoryDenseCache {
  mut frame_stamp : Int
  transforms : Array[@transform.Transform?]
  generations : Array[Int]
  stamps : Array[Int]
}

///|
priv struct CameraMotionBlurHistoryEntry {
  entity : @core.Entity
  transform : @transform.Transform
  clip_from_world : ProjectionMatrix3d
}

///|
priv struct MotionBlurTargetsEntry {
  entity : @core.Entity
  width : Int
  height : Int
  scene_target_id : Int
  velocity_target_id : Int
}

///|
priv struct TransmissionSourceTargetsEntry {
  entity : @core.Entity
  width : Int
  height : Int
  source_target_id : Int
}

///|
priv struct PointLightShadowTargetsEntry {
  entity : @core.Entity
  size : Int
  target_id : Int
}

///|
let motion_blur_history : Ref[MotionBlurHistoryDenseCache] = Ref::new({
  frame_stamp: 0,
  transforms: [],
  generations: [],
  stamps: [],
})

///|
let camera_motion_blur_history : Ref[Array[CameraMotionBlurHistoryEntry]] = Ref::new([],
)

///|
let motion_blur_targets : Ref[Array[MotionBlurTargetsEntry]] = Ref::new([])

///|
let transmission_source_targets : Ref[Array[TransmissionSourceTargetsEntry]] = Ref::new([],
)

///|
let point_light_shadow_targets : Ref[Array[PointLightShadowTargetsEntry]] = Ref::new([],
)

///|
fn motion_blur_history_ensure_slot(entity_id : Int) -> Unit {
  if entity_id < 0 {
    return
  }
  while motion_blur_history.val.transforms.length() <= entity_id {
    motion_blur_history.val.transforms.push(None)
    motion_blur_history.val.generations.push(0)
    motion_blur_history.val.stamps.push(0)
  }
}

///|
fn motion_blur_history_begin_frame() -> Int {
  motion_blur_history.val.frame_stamp = motion_blur_history.val.frame_stamp + 1
  if motion_blur_history.val.frame_stamp <= 0 {
    motion_blur_history.val.frame_stamp = 1
    for i in 0..<motion_blur_history.val.stamps.length() {
      motion_blur_history.val.stamps[i] = 0
    }
  }
  motion_blur_history.val.frame_stamp
}

///|
fn motion_blur_history_get(
  entity : @core.Entity,
  previous_frame_stamp : Int,
) -> @transform.Transform? {
  if entity.id < 0 || entity.id >= motion_blur_history.val.transforms.length() {
    return None
  }
  if motion_blur_history.val.stamps[entity.id] != previous_frame_stamp {
    return None
  }
  if motion_blur_history.val.generations[entity.id] != entity.generation {
    return None
  }
  motion_blur_history.val.transforms[entity.id]
}

///|
fn motion_blur_history_sync(
  meshes : Array[ExtractedMesh3d],
  frame_stamp : Int,
) -> Unit {
  for mesh in meshes {
    let entity = mesh.entity.main_entity
    if entity.id < 0 {
      continue
    }
    motion_blur_history_ensure_slot(entity.id)
    motion_blur_history.val.transforms[entity.id] = Some(mesh.payload.transform)
    motion_blur_history.val.generations[entity.id] = entity.generation
    motion_blur_history.val.stamps[entity.id] = frame_stamp
  }
}

///|
fn camera_motion_blur_history_get(
  entity : @core.Entity,
) -> CameraMotionBlurHistoryEntry? {
  for item in camera_motion_blur_history.val {
    if item.entity.id == entity.id &&
      item.entity.generation == entity.generation {
      return Some(item)
    }
  }
  None
}

///|
fn camera_motion_blur_history_sync(
  history : Array[CameraMotionBlurHistoryEntry],
) -> Unit {
  camera_motion_blur_history.val = history
}

///|
fn render3d_motion_blur_targets_get_or_create(
  entity : @core.Entity,
  width : Int,
  height : Int,
) -> (Int, Int) {
  for item in motion_blur_targets.val {
    if item.entity.id == entity.id &&
      item.entity.generation == entity.generation &&
      item.width == width &&
      item.height == height {
      return (item.scene_target_id, item.velocity_target_id)
    }
  }
  let scene_target_id = @render.host_gpu_create_render_target_rgba16f(
    width~,
    height~,
    nearest=false,
  )
  let velocity_target_id = @render.host_gpu_create_render_target_rg16f(
    width~,
    height~,
    nearest=false,
  )
  let next : Array[MotionBlurTargetsEntry] = []
  let mut replaced = false
  for item in motion_blur_targets.val {
    if item.entity.id == entity.id &&
      item.entity.generation == entity.generation {
      if !replaced {
        next.push({ entity, width, height, scene_target_id, velocity_target_id })
        replaced = true
      }
    } else {
      next.push(item)
    }
  }
  if !replaced {
    next.push({ entity, width, height, scene_target_id, velocity_target_id })
  }
  motion_blur_targets.val = next
  (scene_target_id, velocity_target_id)
}

///|
fn render3d_transmission_source_target_get_or_create(
  entity : @core.Entity,
  width : Int,
  height : Int,
) -> Int {
  for item in transmission_source_targets.val {
    if item.entity.id == entity.id &&
      item.entity.generation == entity.generation &&
      item.width == width &&
      item.height == height {
      return item.source_target_id
    }
  }
  let source_target_id = @render.host_gpu_create_render_target_rgba16f(
    width~,
    height~,
    nearest=false,
  )
  let next : Array[TransmissionSourceTargetsEntry] = []
  let mut replaced = false
  for item in transmission_source_targets.val {
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
  transmission_source_targets.val = next
  source_target_id
}

///|
fn render3d_point_light_shadow_target_get_or_create(
  entity : @core.Entity,
  size : Int,
) -> Int {
  let safe_size = if size <= 0 { 1 } else { size }
  for item in point_light_shadow_targets.val {
    if item.entity.id == entity.id &&
      item.entity.generation == entity.generation &&
      item.size == safe_size {
      return item.target_id
    }
  }
  let target_id = @render.host_gpu_create_point_light_shadow_target(
    size=safe_size,
  )
  let next : Array[PointLightShadowTargetsEntry] = []
  let mut replaced = false
  for item in point_light_shadow_targets.val {
    if item.entity.id == entity.id &&
      item.entity.generation == entity.generation {
      if !replaced {
        next.push({ entity, size: safe_size, target_id })
        replaced = true
      }
    } else {
      next.push(item)
    }
  }
  if !replaced {
    next.push({ entity, size: safe_size, target_id })
  }
  point_light_shadow_targets.val = next
  target_id
}

///|
fn render3d_blit_texture_to_target(
  source_texture_id : Int,
  target_id : Int,
  width_logical : Int,
  height_logical : Int,
) -> Unit {
  if source_texture_id < 0 ||
    target_id < 0 ||
    width_logical <= 0 ||
    height_logical <= 0 {
    return
  }
  let sx = Float::from_double(width_logical.to_double()) / 128.0F
  let sy = Float::from_double(height_logical.to_double()) / 128.0F
  @render.host_gpu_begin_pass(
    target_id~,
    width=width_logical,
    height=height_logical,
    clear_r=0.0F,
    clear_g=0.0F,
    clear_b=0.0F,
    clear_a=0.0F,
    camera_x=0.0F,
    camera_y=0.0F,
    camera_rotation=0.0F,
    camera_scale=1.0F,
    viewport_x=0,
    viewport_y=0,
    viewport_width=width_logical,
    viewport_height=height_logical,
    viewport_depth_min=0.0F,
    viewport_depth_max=1.0F,
    clear_enabled=1,
  )
  @render.host_gpu_draw_sprite_uv(
    texture_id=source_texture_id,
    x=0.0F,
    y=0.0F,
    rotation=0.0F,
    scale_x=sx,
    scale_y=sy,
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

///|
priv struct Render3dEnvironmentMapState {
  diffuse_texture_id : Int
  specular_texture_id : Int
  intensity : Float
  rotation : @math.Quat
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
fn render3d_camera_environment_map_state(
  camera : ExtractedCamera3d,
) -> Render3dEnvironmentMapState {
  let mut state = Render3dEnvironmentMapState::{
    diffuse_texture_id: -1,
    specular_texture_id: -1,
    intensity: 0.0F,
    rotation: @math.Quat::identity(),
  }
  if camera.payload.environment_map_light is Some(environment_map_light) {
    if render3d_loaded_image_texture_id(environment_map_light.diffuse_map)
      is Some(diffuse_texture_id) &&
      render3d_loaded_image_texture_id(environment_map_light.specular_map)
      is Some(specular_texture_id) {
      state = Render3dEnvironmentMapState::{
        diffuse_texture_id,
        specular_texture_id,
        intensity: environment_map_light.intensity,
        rotation: environment_map_light.rotation,
      }
    }
  }
  if state.diffuse_texture_id < 0 &&
    state.specular_texture_id < 0 &&
    camera.payload.generated_environment_map_light
    is Some(generated_environment_map_light) {
    if render3d_loaded_image_texture_id(
        generated_environment_map_light.environment_map,
      )
      is Some(generated_texture_id) {
      state = Render3dEnvironmentMapState::{
        diffuse_texture_id: generated_texture_id,
        specular_texture_id: generated_texture_id,
        intensity: generated_environment_map_light.intensity,
        rotation: generated_environment_map_light.rotation,
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
      intensity: 0.0F,
      rotation: @math.Quat::identity(),
    }
  } else {
    Render3dEnvironmentMapState::{
      ..state,
      diffuse_texture_id,
      specular_texture_id,
    }
  }
}

///|
fn render3d_camera_apply_environment_map_lighting(
  lighting : Render3dLightingState,
  camera : ExtractedCamera3d,
) -> Render3dLightingState {
  let atmosphere_environment_intensity = if camera.payload.atmosphere_environment_map_light
    is Some(atmosphere_environment_map_light) {
    @pbr_render.maxf(0.0F, atmosphere_environment_map_light.intensity)
  } else {
    0.0F
  }
  if atmosphere_environment_intensity <= 0.0F {
    return lighting
  }
  Render3dLightingState::{
    ..lighting,
    ambient_brightness: @pbr_render.maxf(
      lighting.ambient_brightness,
      atmosphere_environment_intensity,
    ),
  }
}

///|
fn render3d_draw_camera_skybox(
  world : @ecs.World,
  camera : ExtractedCamera3d,
  camera_far : Float,
  camera_exposure_value : Float,
  point_shadow_texture_id : Int,
  point_shadow_enabled : Float,
  point_shadow_depth_bias : Float,
  environment_map_state : Render3dEnvironmentMapState,
) -> Unit {
  guard camera.payload.skybox is Some(skybox) else { return }
  guard skybox.image is Some(image) else { return }
  let skybox_texture_id = image.id()
  if skybox_texture_id < 0 ||
    !@render.asset_is_texture_loaded(texture_id=skybox_texture_id) {
    return
  }
  let mesh_id = render3d_skybox_proxy_mesh_id(world)
  if mesh_id <= 0 {
    return
  }
  let brightness = @pbr_render.maxf(
    0.0F,
    skybox.brightness * camera_exposure_value,
  )
  let skybox_extent = @pbr_render.maxf(
    5.0F,
    @pbr_render.minf(camera_far * 0.45F, 20_000.0F),
  )
  let skybox_rotation_inverse = @pbr_render.render3d_quat_inverse(
    skybox.rotation,
  )
  // Negative d marks stacked-vertical cubemap sampling in mesh3d.wgsl.
  @render.host_gpu_draw_mesh3d(
    mesh_id~,
    x=camera.payload.transform.translation.x,
    y=camera.payload.transform.translation.y,
    z=camera.payload.transform.translation.z,
    rotation_x=skybox_rotation_inverse.x,
    rotation_y=skybox_rotation_inverse.y,
    rotation_z=skybox_rotation_inverse.z,
    rotation_w=skybox_rotation_inverse.w,
    scale_x=skybox_extent,
    scale_y=skybox_extent,
    scale_z=skybox_extent,
    previous_x=camera.payload.previous_transform.translation.x,
    previous_y=camera.payload.previous_transform.translation.y,
    previous_z=camera.payload.previous_transform.translation.z,
    previous_rotation_x=camera.payload.previous_transform.rotation.x,
    previous_rotation_y=camera.payload.previous_transform.rotation.y,
    previous_rotation_z=camera.payload.previous_transform.rotation.z,
    previous_rotation_w=camera.payload.previous_transform.rotation.w,
    previous_scale_x=camera.payload.previous_transform.scale.x,
    previous_scale_y=camera.payload.previous_transform.scale.y,
    previous_scale_z=camera.payload.previous_transform.scale.z,
    color_r=brightness,
    color_g=brightness,
    color_b=brightness,
    color_a=1.0F,
    texture_id=skybox_texture_id,
    uv_transform_a=1.0F,
    uv_transform_b=0.0F,
    uv_transform_c=0.0F,
    uv_transform_d=-1.0F,
    uv_transform_tx=0.0F,
    uv_transform_ty=0.0F,
    uv_transform_mode=-1.0F,
    normal_texture_id=-1,
    emissive_texture_id=-1,
    metallic_roughness_texture_id=-1,
    occlusion_texture_id=-1,
    depth_texture_id=-1,
    emissive_r=0.0F,
    emissive_g=0.0F,
    emissive_b=0.0F,
    metallic=0.0F,
    roughness=1.0F,
    reflectance=0.0F,
    parallax_depth_scale=0.0F,
    max_parallax_layer_count=0.0F,
    max_relief_mapping_search_steps=0.0F,
    anisotropy_texture_id=-1,
    anisotropy_strength=0.0F,
    anisotropy_rotation=0.0F,
    specular_tint_texture_id=-1,
    specular_tint_r=1.0F,
    specular_tint_g=1.0F,
    specular_tint_b=1.0F,
    diffuse_transmission=0.0F,
    specular_transmission=0.0F,
    thickness=0.0F,
    ior=1.5F,
    alpha_cutoff=0.5F,
    material_flags=@pbr_render.STANDARD_MATERIAL_FLAGS_BASE_COLOR_TEXTURE_BIT |
      @pbr_render.STANDARD_MATERIAL_FLAGS_UNLIT_BIT |
      @pbr_render.STANDARD_MATERIAL_FLAGS_ALPHA_MODE_OPAQUE,
    transmission_source_texture_id=-1,
    transmission_blur_taps=0.0F,
    transmission_steps=0.0F,
    point_shadow_texture_id~,
    point_shadow_enabled~,
    point_shadow_depth_bias~,
    environment_diffuse_texture_id=environment_map_state.diffuse_texture_id,
    environment_specular_texture_id=environment_map_state.specular_texture_id,
    environment_map_intensity=environment_map_state.intensity,
    environment_map_rotation_x=environment_map_state.rotation.x,
    environment_map_rotation_y=environment_map_state.rotation.y,
    environment_map_rotation_z=environment_map_state.rotation.z,
    environment_map_rotation_w=environment_map_state.rotation.w,
    cull_mode=1,
  )
}
