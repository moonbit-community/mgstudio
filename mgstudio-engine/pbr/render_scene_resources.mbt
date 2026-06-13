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
  scene_target_id : Int
  velocity_target_id : Int
  depth_target_id : Int
  normal_target_id : Int
}

///|
priv struct PrepassTargetsEntry {
  entity : @core.Entity
  width : Int
  height : Int
  sample_count : Int
  depth_target_id : Int
  normal_target_id : Int
}

///|
priv struct Render3dPrepassTargetIds {
  depth_texture_id : Int
  normal_texture_id : Int
}

///|
priv struct TransmissionSourceTargetsEntry {
  entity : @core.Entity
  width : Int
  height : Int
  source_target_id : Int
}

///|
priv struct Render3dSceneTargetsState {
  mut motion_blur_targets : Array[MotionBlurTargetsEntry]
  mut prepass_targets : Array[PrepassTargetsEntry]
  mut transmission_source_targets : Array[TransmissionSourceTargetsEntry]
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
  normal_prepass_enabled : Bool,
) -> Render3dPrepassTargetIds {
  let scene_targets_state = render3d_scene_targets_state_mut_or_init(world)
  let prepass_targets = scene_targets_state.peek().prepass_targets
  let safe_sample_count = if sample_count <= 1 { 1 } else { sample_count }
  for item in prepass_targets {
    if item.entity.id == entity.id &&
      item.entity.generation == entity.generation &&
      item.width == width &&
      item.height == height &&
      item.sample_count == safe_sample_count {
      if !normal_prepass_enabled || item.normal_target_id >= 0 {
        return Render3dPrepassTargetIds::{
          depth_texture_id: item.depth_target_id,
          normal_texture_id: if normal_prepass_enabled {
            item.normal_target_id
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
          depth_target_id,
          normal_target_id,
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
      depth_target_id,
      normal_target_id,
    })
  }
  scene_targets_state.modify(fn(state) { state.prepass_targets = next })
  Render3dPrepassTargetIds::{
    depth_texture_id: depth_target_id,
    normal_texture_id: normal_target_id,
  }
}

///|
fn render3d_motion_blur_targets_get_or_create(
  world : @ecs.World,
  entity : @core.Entity,
  width : Int,
  height : Int,
  sample_count : Int,
  normal_prepass_enabled? : Bool = false,
) -> (Int, Int, Int, Int) {
  let scene_targets_state = render3d_scene_targets_state_mut_or_init(world)
  let motion_blur_targets = scene_targets_state.peek().motion_blur_targets
  let safe_sample_count = if sample_count <= 1 { 1 } else { sample_count }
  for item in motion_blur_targets {
    if item.entity.id == entity.id &&
      item.entity.generation == entity.generation &&
      item.width == width &&
      item.height == height &&
      item.sample_count == safe_sample_count {
      if !normal_prepass_enabled || item.normal_target_id >= 0 {
        return (
          item.scene_target_id,
          item.velocity_target_id,
          item.depth_target_id,
          if normal_prepass_enabled {
            item.normal_target_id
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
          scene_target_id,
          velocity_target_id,
          depth_target_id,
          normal_target_id,
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
      scene_target_id,
      velocity_target_id,
      depth_target_id,
      normal_target_id,
    })
  }
  scene_targets_state.modify(fn(state) { state.motion_blur_targets = next })
  (scene_target_id, velocity_target_id, depth_target_id, normal_target_id)
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
  let source_target_id = @render.host_gpu_create_render_target_rgba16f(
    width~,
    height~,
    nearest=false,
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
  camera : ExtractedCamera3d,
  camera_exposure_value : Float,
) -> Unit {
  guard camera.payload.skybox is Some(skybox) else { return }
  guard skybox.image is Some(image) else { return }
  let skybox_texture_id = image.id()
  if skybox_texture_id < 0 ||
    !@render.asset_is_texture_loaded(texture_id=skybox_texture_id) {
    return
  }
  let brightness = @pbr_render.maxf(
    0.0F,
    skybox.brightness * camera_exposure_value,
  )
  let skybox_rotation_inverse = @pbr_render.render3d_quat_inverse(
    skybox.rotation,
  )
  @render.host_gpu_draw_skybox(
    texture_id=skybox_texture_id,
    brightness~,
    rotation_x=skybox_rotation_inverse.x,
    rotation_y=skybox_rotation_inverse.y,
    rotation_z=skybox_rotation_inverse.z,
    rotation_w=skybox_rotation_inverse.w,
  )
}
