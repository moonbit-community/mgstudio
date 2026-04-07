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
fn render3d_point_shadow_face_transform(
  light_position : @math.Vec3,
  face_index : Int,
) -> @transform.Transform {
  let (forward, up) = match face_index {
    // Match Bevy's `CUBE_MAP_FACES` exactly:
    // [+X, -X, +Y, -Y, +Z, -Z] face order with left-handed cubemap conventions.
    0 => (@math.Vec3::new(1.0F, 0.0F, 0.0F), @math.Vec3::new(0.0F, 1.0F, 0.0F))
    1 => (@math.Vec3::new(-1.0F, 0.0F, 0.0F), @math.Vec3::new(0.0F, 1.0F, 0.0F))
    2 => (@math.Vec3::new(0.0F, 1.0F, 0.0F), @math.Vec3::new(0.0F, 0.0F, 1.0F))
    3 =>
      (@math.Vec3::new(0.0F, -1.0F, 0.0F), @math.Vec3::new(0.0F, 0.0F, -1.0F))
    4 => (@math.Vec3::new(0.0F, 0.0F, -1.0F), @math.Vec3::new(0.0F, 1.0F, 0.0F))
    _ => (@math.Vec3::new(0.0F, 0.0F, 1.0F), @math.Vec3::new(0.0F, 1.0F, 0.0F))
  }
  @transform.Transform::from_xyz(
    light_position.x,
    light_position.y,
    light_position.z,
  ).looking_at(light_position.add(forward), up)
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
fn render3d_wireframe_mesh_cache_get(source_mesh_handle_id : Int) -> Int? {
  for item in wireframe_mesh_cache.val {
    if item.source_mesh_handle_id == source_mesh_handle_id {
      return Some(item.wireframe_mesh_id)
    }
  }
  None
}

///|
fn render3d_wireframe_mesh_cache_set(
  source_mesh_handle_id : Int,
  wireframe_mesh_id : Int,
) -> Unit {
  let next : Array[WireframeMeshCacheEntry] = []
  let mut replaced = false
  for item in wireframe_mesh_cache.val {
    if item.source_mesh_handle_id == source_mesh_handle_id {
      if !replaced {
        next.push({ source_mesh_handle_id, wireframe_mesh_id })
        replaced = true
      }
    } else {
      next.push(item)
    }
  }
  if !replaced {
    next.push({ source_mesh_handle_id, wireframe_mesh_id })
  }
  wireframe_mesh_cache.val = next
}

///|
fn render3d_wireframe_mesh_id(mesh_handle : @asset.Handle[@mesh.Mesh]) -> Int? {
  let source_mesh_handle_id = mesh_handle.id()
  if render3d_wireframe_mesh_cache_get(source_mesh_handle_id) is Some(mesh_id) {
    return Some(mesh_id)
  }
  let source_mesh = match @sprite.render_mesh_asset_get(mesh_handle) {
    Some(mesh_asset) => mesh_asset
    None => return None
  }
  match source_mesh.geometry {
    @mesh.MeshGeometry::Geometry3d(geometry3d) =>
      match geometry3d.primitive_topology() {
        @mesh.Mesh3dPrimitiveTopology::TriangleList =>
          match geometry3d.to_wireframe_line_list() {
            Some(wireframe_geometry) => {
              let wireframe_handle = @sprite.render_mesh_asset_add(
                @mesh.Mesh::from_3d_geometry(wireframe_geometry),
              )
              let wireframe_mesh_id = @sprite_render.render2d_upload_mesh_handle(
                wireframe_handle,
              )
              render3d_wireframe_mesh_cache_set(
                source_mesh_handle_id, wireframe_mesh_id,
              )
              Some(wireframe_mesh_id)
            }
            None => return None
          }
        @mesh.Mesh3dPrimitiveTopology::LineList => {
          let mesh_id = @sprite_render.render2d_upload_mesh_handle(mesh_handle)
          render3d_wireframe_mesh_cache_set(source_mesh_handle_id, mesh_id)
          Some(mesh_id)
        }
        @mesh.Mesh3dPrimitiveTopology::LineStrip => {
          let mesh_id = @sprite_render.render2d_upload_mesh_handle(mesh_handle)
          render3d_wireframe_mesh_cache_set(source_mesh_handle_id, mesh_id)
          Some(mesh_id)
        }
      }
    _ => return None
  }
}

///|
fn render3d_mesh_should_draw_wireframe(
  mesh : ExtractedMesh3d,
  wireframe_config : WireframeConfig?,
) -> Bool {
  guard wireframe_config is Some(config) else { return false }
  if mesh.payload.has_no_wireframe {
    false
  } else if mesh.payload.has_wireframe {
    true
  } else {
    config.global
  }
}

///|
fn render3d_mesh_wireframe_color(
  mesh : ExtractedMesh3d,
  wireframe_config : WireframeConfig?,
) -> @sprite.Color {
  if mesh.payload.wireframe_color is Some(color_component) {
    color_component.color
  } else if wireframe_config is Some(config) {
    config.default_color
  } else {
    @sprite.Color::white()
  }
}

///|
fn render3d_collect_lighting(world : @ecs.World) -> Render3dLightingState {
  let mut lighting = render3d_default_lighting_state()
  let point_luminous_power_to_intensity = 4.0F * @math.pi()
  if (try! world.get_resource(ecs_key_global_ambient_light)) is Some(ambient) {
    lighting = Render3dLightingState::{
      ..lighting,
      ambient_color: ambient.color,
      ambient_brightness: ambient.brightness,
    }
  }
  let mut directional_found = false
  world.for_each_component(ecs_key_directional_light, fn(entity, light) {
    if directional_found {
      return
    }
    let transform = match
      (try! world.get_by_key(entity, @transform.ecs_key_transform)) {
      Some(value) => value
      None => @transform.Transform::identity()
    }
    directional_found = true
    lighting = Render3dLightingState::{
      ..lighting,
      directional_dir: render3d_transform_forward(transform),
      directional_color: light.color,
      directional_illuminance: light.illuminance,
    }
  })
  let mut point_found = false
  world.for_each_component(ecs_key_point_light, fn(entity, light) {
    if point_found {
      return
    }
    let transform = match
      (try! world.get_by_key(entity, @transform.ecs_key_transform)) {
      Some(value) => value
      None => @transform.Transform::identity()
    }
    point_found = true
    lighting = Render3dLightingState::{
      ..lighting,
      point_entity: entity,
      point_pos: transform.translation,
      point_color: light.color,
      point_intensity: if point_luminous_power_to_intensity <= 0.0F {
        light.intensity
      } else {
        light.intensity / point_luminous_power_to_intensity
      },
      point_range: if light.range > 0.0F {
        light.range
      } else {
        1.0F
      },
      point_shadow_maps_enabled: light.shadow_maps_enabled,
      point_shadow_depth_bias: light.shadow_depth_bias,
      point_shadow_map_near_z: if light.shadow_map_near_z > 0.0001F {
        light.shadow_map_near_z
      } else {
        0.0001F
      },
    }
  })
  let mut spot_found = false
  world.for_each_component(ecs_key_spot_light, fn(entity, light) {
    if spot_found {
      return
    }
    let transform = match
      (try! world.get_by_key(entity, @transform.ecs_key_transform)) {
      Some(value) => value
      None => @transform.Transform::identity()
    }
    let inner = light.inner_angle
    let mut outer = light.outer_angle
    if outer < inner {
      outer = inner
    }
    spot_found = true
    lighting = Render3dLightingState::{
      ..lighting,
      spot_pos: transform.translation,
      spot_dir: render3d_transform_forward(transform),
      spot_color: light.color,
      spot_intensity: if point_luminous_power_to_intensity <= 0.0F {
        light.intensity
      } else {
        light.intensity / point_luminous_power_to_intensity
      },
      spot_range: if light.range > 0.0F {
        light.range
      } else {
        1.0F
      },
      spot_inner_angle: inner,
      spot_outer_angle: outer,
    }
  })
  lighting
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
    maxf(0.0F, atmosphere_environment_map_light.intensity)
  } else {
    0.0F
  }
  if atmosphere_environment_intensity <= 0.0F {
    return lighting
  }
  Render3dLightingState::{
    ..lighting,
    ambient_brightness: maxf(
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
  let brightness = maxf(0.0F, skybox.brightness * camera_exposure_value)
  let skybox_extent = maxf(5.0F, minf(camera_far * 0.45F, 20_000.0F))
  let skybox_rotation_inverse = render3d_quat_inverse(skybox.rotation)
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
    material_flags=STANDARD_MATERIAL_FLAGS_BASE_COLOR_TEXTURE_BIT |
      STANDARD_MATERIAL_FLAGS_UNLIT_BIT |
      STANDARD_MATERIAL_FLAGS_ALPHA_MODE_OPAQUE,
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
