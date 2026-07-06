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
// Bevy source: `bevy/crates/bevy_light/src/cluster/assign.rs`.

///|
const DEFAULT_FAR_DEPTH : Float = 1000.0F

///|
pub(all) enum ClusterableObjectType {
  PointLight(Bool, Bool)
  SpotLight(Bool, Bool, Float)
  ReflectionProbe
  IrradianceVolume
  Decal
} derive(Eq, Debug)

///|
pub fn ClusterableObjectType::ordering(
  self : ClusterableObjectType,
) -> (Int, Bool, Bool) {
  match self {
    PointLight(shadow_maps_enabled, volumetric) =>
      (0, !shadow_maps_enabled, !volumetric)
    SpotLight(shadow_maps_enabled, volumetric, _outer_angle) =>
      (1, !shadow_maps_enabled, !volumetric)
    ReflectionProbe => (2, false, false)
    IrradianceVolume => (3, false, false)
    Decal => (4, false, false)
  }
}

///|
pub fn calculate_cluster_factors(
  near : Float,
  far : Float,
  z_slices : Float,
  is_orthographic : Bool,
) -> @math.Vec2 {
  let safe_near = if near <= 0.0F { 0.0001F } else { near }
  let safe_far = if far <= safe_near { safe_near + 0.0001F } else { far }
  let safe_slices = if z_slices <= 1.0F { 1.0F } else { z_slices }
  if is_orthographic {
    let denominator = -safe_far - -safe_near
    let slope = if denominator.abs() <= 1.0e-6F {
      0.0F
    } else {
      safe_slices / denominator
    }
    @math.Vec2::new(-safe_near, slope)
  } else {
    let ln_far_over_near = Float::from_double(
      @math_core.ln((safe_far / safe_near).to_double()),
    )
    if ln_far_over_near.abs() <= 1.0e-6F {
      @math.Vec2::new(0.0F, 0.0F)
    } else {
      let z_slices_of_ln_zfar_over_znear = (safe_slices - 1.0F) /
        ln_far_over_near
      @math.Vec2::new(
        z_slices_of_ln_zfar_over_znear,
        Float::from_double(@math_core.ln(safe_near.to_double())) *
        z_slices_of_ln_zfar_over_znear,
      )
    }
  }
}

///|
pub fn cluster_assign_lights(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  app.add_post_update_system_config(
    @app.system(cluster_assign_lights_system)
    .named("mgstudio.light.cluster.assign_objects_to_clusters")
    .after(@transform.transform_set_propagate)
    .after(@visibility.visibility_set_check_visibility)
    .after("mgstudio.camera.update")
    .in_set(@light.simulation_light_set_assign_lights_to_clusters),
  )
}

///|
fn cluster_assign_tile_size(screen_size : Int, cluster_dimension : Int) -> Int {
  if screen_size <= 0 || cluster_dimension <= 0 {
    return 0
  }
  let raw = @math_core.ceil(
    screen_size.to_double() / cluster_dimension.to_double(),
  )
  let as_int = raw.to_int()
  if as_int <= 0 {
    1
  } else {
    as_int
  }
}

///|
fn cluster_assign_viewport_size(camera : @camera_camera.Camera) -> (Int, Int) {
  match camera.physical_viewport_size() {
    Some(viewport_size) =>
      if viewport_size.x <= 0 || viewport_size.y <= 0 {
        (0, 0)
      } else {
        (viewport_size.x, viewport_size.y)
      }
    None => (0, 0)
  }
}

///|
fn cluster_assign_clear_view(
  world : @ecs.World,
  entity : @core.Entity,
  previous_clusters : Clusters?,
) -> Unit {
  let cleared_clusters = match previous_clusters {
    Some(clusters) => {
      clusters.clear()
      clusters
    }
    None => Clusters::Clusters()
  }
  try! world.set_by_key(entity, Clusters::component(), cleared_clusters)
  try! world.set_by_key(
    entity,
    VisibleClusterableObjects::component(),
    VisibleClusterableObjects::new(),
  )
}

///|
fn cluster_assign_is_view_visible(
  world : @ecs.World,
  entity : @core.Entity,
) -> Bool {
  match (try! world.get_by_key(entity, @visibility.ecs_key_view_visibility)) {
    Some(view_visibility) => view_visibility.is_visible()
    None => true
  }
}

///|
fn cluster_assign_cluster_objects(
  cluster_count : Int,
) -> Array[ObjectsInCluster] {
  let objects : Array[ObjectsInCluster] = []
  if cluster_count <= 0 {
    return objects
  }
  for _ in 0..<cluster_count {
    objects.push(ObjectsInCluster::ObjectsInCluster())
  }
  objects
}

///|
priv struct ClusterableObjectAssignmentData {
  entity : @core.Entity
  transform : @transform.Transform
  range : Float
  object_type : ClusterableObjectType
  render_layers : @camera_render_layers.RenderLayers
}

///|
priv struct ClusterAssignSphere {
  center : @math.Vec3
  radius : Float
}

///|
fn cluster_assign_entity_transform(
  world : @ecs.World,
  entity : @core.Entity,
) -> @transform.Transform {
  match
    (try! world.get_by_key(entity, @transform.GlobalTransform::component())) {
    Some(global_transform) => global_transform.compute_transform()
    None =>
      match (try! world.get_by_key(entity, @transform.Transform::component())) {
        Some(transform) => transform
        None => @transform.Transform::identity()
      }
  }
}

///|
fn cluster_assign_entity_render_layers(
  world : @ecs.World,
  entity : @core.Entity,
) -> @camera_render_layers.RenderLayers {
  match
    (try! world.get_by_key(entity, @camera_render_layers.ecs_key_render_layers)) {
    Some(render_layers) => render_layers
    None => @camera_render_layers.RenderLayers::RenderLayers()
  }
}

///|
fn cluster_assign_light_probe_radius(transform : @transform.Transform) -> Float {
  transform.scale.length()
}

///|
fn cluster_assign_collect_objects(
  world : @ecs.World,
) -> Array[ClusterableObjectAssignmentData] {
  let objects : Array[ClusterableObjectAssignmentData] = []
  let global_cluster_settings = match
    world.get_resource(ecs_key_global_cluster_settings) {
    Some(settings) => settings
    None => GlobalClusterSettings::GlobalClusterSettings()
  }
  world.for_each_component(@light.ecs_key_point_light, fn(entity, light) {
    if !cluster_assign_is_view_visible(world, entity) {
      return
    }
    objects.push(ClusterableObjectAssignmentData::{
      entity,
      transform: cluster_assign_entity_transform(world, entity),
      range: light.range,
      object_type: ClusterableObjectType::PointLight(
        light.shadow_maps_enabled,
        false,
      ),
      render_layers: cluster_assign_entity_render_layers(world, entity),
    })
  })
  world.for_each_component(@light.ecs_key_spot_light, fn(entity, light) {
    if !cluster_assign_is_view_visible(world, entity) {
      return
    }
    objects.push(ClusterableObjectAssignmentData::{
      entity,
      transform: cluster_assign_entity_transform(world, entity),
      range: light.range,
      object_type: ClusterableObjectType::SpotLight(
        light.shadow_maps_enabled,
        false,
        light.outer_angle,
      ),
      render_layers: cluster_assign_entity_render_layers(world, entity),
    })
  })
  if global_cluster_settings.supports_storage_buffers {
    world.for_each_component(@light.ecs_key_environment_map_light, fn(
      entity,
      _probe,
    ) {
      if !(try! world.contains_by_key(entity, @light.ecs_key_light_probe)) {
        return
      }
      if !cluster_assign_is_view_visible(world, entity) {
        return
      }
      let transform = cluster_assign_entity_transform(world, entity)
      objects.push(ClusterableObjectAssignmentData::{
        entity,
        transform,
        range: cluster_assign_light_probe_radius(transform),
        object_type: ClusterableObjectType::ReflectionProbe,
        render_layers: @camera_render_layers.RenderLayers::RenderLayers(),
      })
    })
    world.for_each_component(@light.ecs_key_irradiance_volume, fn(
      entity,
      _probe,
    ) {
      if !(try! world.contains_by_key(entity, @light.ecs_key_light_probe)) {
        return
      }
      if !cluster_assign_is_view_visible(world, entity) {
        return
      }
      let transform = cluster_assign_entity_transform(world, entity)
      objects.push(ClusterableObjectAssignmentData::{
        entity,
        transform,
        range: cluster_assign_light_probe_radius(transform),
        object_type: ClusterableObjectType::IrradianceVolume,
        render_layers: @camera_render_layers.RenderLayers::RenderLayers(),
      })
    })
  }
  if global_cluster_settings.clustered_decals_are_usable {
    world.for_each_component(@light.ecs_key_clustered_decal, fn(
      entity,
      _decal,
    ) {
      if !cluster_assign_is_view_visible(world, entity) {
        return
      }
      let transform = cluster_assign_entity_transform(world, entity)
      objects.push(ClusterableObjectAssignmentData::{
        entity,
        transform,
        range: transform.scale.length(),
        object_type: ClusterableObjectType::Decal,
        render_layers: @camera_render_layers.RenderLayers::RenderLayers(),
      })
    })
  }
  objects
}

///|
fn cluster_assign_float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
}

///|
fn cluster_assign_vec3_abs(value : @math.Vec3) -> @math.Vec3 {
  @math.Vec3::new(value.x.abs(), value.y.abs(), value.z.abs())
}

///|
fn cluster_assign_vec4_xyz(value : @math.Vec4) -> @math.Vec3 {
  @math.Vec3::new(value.x, value.y, value.z)
}

///|
fn cluster_assign_vec3_xz_dot(a : @math.Vec3, b : @math.Vec3) -> Float {
  a.x * b.x + a.z * b.z
}

///|
fn cluster_assign_vec3_yz_dot(a : @math.Vec3, b : @math.Vec3) -> Float {
  a.y * b.y + a.z * b.z
}

///|
fn cluster_assign_default_clip_from_view(
  screen_width : Int,
  screen_height : Int,
) -> ClusterProjectionMatrix3d {
  let width = cluster_assign_float_from_int(
    if screen_width <= 0 {
      1
    } else {
      screen_width
    },
  )
  let height = cluster_assign_float_from_int(
    if screen_height <= 0 {
      1
    } else {
      screen_height
    },
  )
  let aspect = width / height
  let half_fov = @math.pi_half() * 0.25F
  let sin_half_fov = @math.sin(half_fov)
  let cos_half_fov = @math.cos(half_fov)
  let tan_half_fov = if cos_half_fov.abs() <= 1.0e-6F {
    1.0F
  } else {
    sin_half_fov / cos_half_fov
  }
  let y = 1.0F / tan_half_fov
  let x = y / aspect
  ClusterProjectionMatrix3d::from_cols(
    @math.Vec4::new(x, 0.0F, 0.0F, 0.0F),
    @math.Vec4::new(0.0F, y, 0.0F, 0.0F),
    @math.Vec4::new(0.0F, 0.0F, 0.0F, -1.0F),
    @math.Vec4::new(0.0F, 0.0F, 0.1F, 0.0F),
  )
}

///|
fn cluster_assign_camera_projection(
  world : @ecs.World,
  entity : @core.Entity,
  screen_width : Int,
  screen_height : Int,
) -> ClusterCameraProjection {
  match (try! world.get_by_key(entity, ClusterCameraProjection::component())) {
    Some(projection) => projection
    None =>
      ClusterCameraProjection::new(
        cluster_assign_default_clip_from_view(screen_width, screen_height),
        false,
        1000.0F,
        0.0F,
      )
  }
}

///|
fn cluster_assign_view_from_world_matrix(
  transform : @transform.Transform,
) -> ClusterProjectionMatrix3d {
  let inverse_rotation = transform.rotation.normalize().inverse()
  let x_axis = inverse_rotation.mul_vec3(@math.Vec3::new(1.0F, 0.0F, 0.0F))
  let y_axis = inverse_rotation.mul_vec3(@math.Vec3::new(0.0F, 1.0F, 0.0F))
  let z_axis = inverse_rotation.mul_vec3(@math.Vec3::new(0.0F, 0.0F, 1.0F))
  let translation = transform.translation
  let offset_x = -(x_axis.x * translation.x +
    y_axis.x * translation.y +
    z_axis.x * translation.z)
  let offset_y = -(x_axis.y * translation.x +
    y_axis.y * translation.y +
    z_axis.y * translation.z)
  let offset_z = -(x_axis.z * translation.x +
    y_axis.z * translation.y +
    z_axis.z * translation.z)
  ClusterProjectionMatrix3d::from_cols(
    @math.Vec4::new(x_axis.x, x_axis.y, x_axis.z, 0.0F),
    @math.Vec4::new(y_axis.x, y_axis.y, y_axis.z, 0.0F),
    @math.Vec4::new(z_axis.x, z_axis.y, z_axis.z, 0.0F),
    @math.Vec4::new(offset_x, offset_y, offset_z, 1.0F),
  )
}

///|
fn cluster_assign_clusterable_object_aabb(
  view_from_world : ClusterProjectionMatrix3d,
  view_from_world_scale : @math.Vec3,
  clip_from_view : ClusterProjectionMatrix3d,
  object : ClusterableObjectAssignmentData,
) -> (@math.Vec3, @math.Vec3)? {
  let center_view4 = view_from_world.mul_vec4(
    @math.Vec4::new(
      object.transform.translation.x,
      object.transform.translation.y,
      object.transform.translation.z,
      1.0F,
    ),
  )
  let center_view = cluster_assign_vec4_xyz(center_view4)
  let half_extents = cluster_assign_vec3_abs(view_from_world_scale).mul_scalar(
    object.range,
  )
  let mut view_min = center_view.sub(half_extents)
  let mut view_max = center_view.add(half_extents)
  if view_min.z >= -1.0e-6F {
    view_min = @math.Vec3::new(view_min.x, view_min.y, -1.0e-6F)
  }
  if view_max.z >= -1.0e-6F {
    view_max = @math.Vec3::new(view_max.x, view_max.y, -1.0e-6F)
  }
  let xymin_near = view_min
  let xymin_far = @math.Vec3::new(view_min.x, view_min.y, view_max.z)
  let xymax_near = @math.Vec3::new(view_max.x, view_max.y, view_min.z)
  let xymax_far = view_max
  let clip_xymin_near = clip_from_view.mul_vec4(
    @math.Vec4::new(xymin_near.x, xymin_near.y, xymin_near.z, 1.0F),
  )
  let clip_xymin_far = clip_from_view.mul_vec4(
    @math.Vec4::new(xymin_far.x, xymin_far.y, xymin_far.z, 1.0F),
  )
  let clip_xymax_near = clip_from_view.mul_vec4(
    @math.Vec4::new(xymax_near.x, xymax_near.y, xymax_near.z, 1.0F),
  )
  let clip_xymax_far = clip_from_view.mul_vec4(
    @math.Vec4::new(xymax_far.x, xymax_far.y, xymax_far.z, 1.0F),
  )
  if clip_xymin_near.w == 0.0F ||
    clip_xymin_far.w == 0.0F ||
    clip_xymax_near.w == 0.0F ||
    clip_xymax_far.w == 0.0F {
    return None
  }
  let ndc_xymin_near = cluster_assign_vec4_xyz(clip_xymin_near).mul_scalar(
    1.0F / clip_xymin_near.w,
  )
  let ndc_xymin_far = cluster_assign_vec4_xyz(clip_xymin_far).mul_scalar(
    1.0F / clip_xymin_far.w,
  )
  let ndc_xymax_near = cluster_assign_vec4_xyz(clip_xymax_near).mul_scalar(
    1.0F / clip_xymax_near.w,
  )
  let ndc_xymax_far = cluster_assign_vec4_xyz(clip_xymax_far).mul_scalar(
    1.0F / clip_xymax_far.w,
  )
  let ndc_min = ndc_xymin_near
    .min(ndc_xymin_far)
    .min(ndc_xymax_near)
    .min(ndc_xymax_far)
  let ndc_max = ndc_xymin_near
    .max(ndc_xymin_far)
    .max(ndc_xymax_near)
    .max(ndc_xymax_far)
  Some(
    (
      @math.Vec3::new(
        ndc_min.x.clamp(min=-1.0F, max=1.0F),
        ndc_min.y.clamp(min=-1.0F, max=1.0F),
        view_min.z,
      ),
      @math.Vec3::new(
        ndc_max.x.clamp(min=-1.0F, max=1.0F),
        ndc_max.y.clamp(min=-1.0F, max=1.0F),
        view_max.z,
      ),
    ),
  )
}

///|
fn cluster_assign_clip_to_view(
  view_from_clip : ClusterProjectionMatrix3d,
  clip : @math.Vec4,
) -> @math.Vec4 {
  let view = view_from_clip.mul_vec4(clip)
  view.mul_scalar(1.0F / view.w)
}

///|
fn cluster_assign_screen_to_view(
  screen_width : Int,
  screen_height : Int,
  view_from_clip : ClusterProjectionMatrix3d,
  screen_x : Float,
  screen_y : Float,
  ndc_z : Float,
) -> @math.Vec4 {
  let tex_x = screen_x / cluster_assign_float_from_int(screen_width)
  let tex_y = screen_y / cluster_assign_float_from_int(screen_height)
  cluster_assign_clip_to_view(
    view_from_clip,
    @math.Vec4::new(
      tex_x * 2.0F - 1.0F,
      (1.0F - tex_y) * 2.0F - 1.0F,
      ndc_z,
      1.0F,
    ),
  )
}

///|
fn cluster_assign_line_intersection_to_z_plane(
  origin : @math.Vec3,
  point : @math.Vec3,
  z : Float,
) -> @math.Vec3 {
  let v = point.sub(origin)
  let t = (z - origin.z) / v.z
  origin.add(v.mul_scalar(t))
}

///|
fn cluster_assign_z_slice_to_view_z(
  near : Float,
  far : Float,
  z_slices : Int,
  z_slice : Int,
  is_orthographic : Bool,
) -> Float {
  if is_orthographic {
    return -near -
      (far - near) *
      cluster_assign_float_from_int(z_slice) /
      cluster_assign_float_from_int(z_slices)
  }
  if z_slice == 0 {
    0.0F
  } else {
    -near *
    Float::from_double(
      @math_core.pow(
        (far / near).to_double(),
        cluster_assign_float_from_int(z_slice - 1).to_double() /
        cluster_assign_float_from_int(z_slices - 1).to_double(),
      ),
    )
  }
}

///|
fn cluster_assign_compute_cluster_aabb_sphere(
  near : Float,
  far : Float,
  tile_size_x : Int,
  tile_size_y : Int,
  screen_width : Int,
  screen_height : Int,
  view_from_clip : ClusterProjectionMatrix3d,
  is_orthographic : Bool,
  dimensions_z : Int,
  x : Int,
  y : Int,
  z : Int,
) -> ClusterAssignSphere {
  let p_min_x = cluster_assign_float_from_int(x * tile_size_x)
  let p_min_y = cluster_assign_float_from_int(y * tile_size_y)
  let p_max_x = p_min_x + cluster_assign_float_from_int(tile_size_x)
  let p_max_y = p_min_y + cluster_assign_float_from_int(tile_size_y)
  let (cluster_min, cluster_max) = if is_orthographic {
    let mut p_min = cluster_assign_vec4_xyz(
      cluster_assign_screen_to_view(
        screen_width, screen_height, view_from_clip, p_min_x, p_min_y, 0.0F,
      ),
    )
    let mut p_max = cluster_assign_vec4_xyz(
      cluster_assign_screen_to_view(
        screen_width, screen_height, view_from_clip, p_max_x, p_max_y, 0.0F,
      ),
    )
    p_min = @math.Vec3::new(
      p_min.x,
      p_min.y,
      -near +
      (near - far) *
      cluster_assign_float_from_int(z) /
      cluster_assign_float_from_int(dimensions_z),
    )
    p_max = @math.Vec3::new(
      p_max.x,
      p_max.y,
      -near +
      (near - far) *
      cluster_assign_float_from_int(z + 1) /
      cluster_assign_float_from_int(dimensions_z),
    )
    (p_min.min(p_max), p_min.max(p_max))
  } else {
    let p_min = cluster_assign_screen_to_view(
      screen_width, screen_height, view_from_clip, p_min_x, p_min_y, 1.0F,
    )
    let p_max = cluster_assign_screen_to_view(
      screen_width, screen_height, view_from_clip, p_max_x, p_max_y, 1.0F,
    )
    let z_far_over_z_near = -far / -near
    let cluster_near = if z == 0 {
      0.0F
    } else {
      -near *
      Float::from_double(
        @math_core.pow(
          z_far_over_z_near.to_double(),
          cluster_assign_float_from_int(z - 1).to_double() /
          cluster_assign_float_from_int(dimensions_z - 1).to_double(),
        ),
      )
    }
    let cluster_far = if dimensions_z == 1 {
      -far
    } else {
      -near *
      Float::from_double(
        @math_core.pow(
          z_far_over_z_near.to_double(),
          cluster_assign_float_from_int(z).to_double() /
          cluster_assign_float_from_int(dimensions_z - 1).to_double(),
        ),
      )
    }
    let origin = @math.Vec3::zero()
    let p_min_xyz = cluster_assign_vec4_xyz(p_min)
    let p_max_xyz = cluster_assign_vec4_xyz(p_max)
    let p_min_near = cluster_assign_line_intersection_to_z_plane(
      origin, p_min_xyz, cluster_near,
    )
    let p_min_far = cluster_assign_line_intersection_to_z_plane(
      origin, p_min_xyz, cluster_far,
    )
    let p_max_near = cluster_assign_line_intersection_to_z_plane(
      origin, p_max_xyz, cluster_near,
    )
    let p_max_far = cluster_assign_line_intersection_to_z_plane(
      origin, p_max_xyz, cluster_far,
    )
    (
      p_min_near.min(p_min_far).min(p_max_near.min(p_max_far)),
      p_min_near.max(p_min_far).max(p_max_near.max(p_max_far)),
    )
  }
  let center = cluster_min.add(cluster_max).mul_scalar(0.5F)
  let half_extents = cluster_max.sub(cluster_min).mul_scalar(0.5F)
  ClusterAssignSphere::{ center, radius: half_extents.length() }
}

///|
fn cluster_assign_get_distance_x(
  plane : @math.HalfSpace,
  point : @math.Vec3,
  is_orthographic : Bool,
) -> Float {
  if is_orthographic {
    point.x - plane.d()
  } else {
    cluster_assign_vec3_xz_dot(plane.normal(), point)
  }
}

///|
fn cluster_assign_project_to_plane_z(
  sphere : ClusterAssignSphere,
  z_plane : @math.HalfSpace,
) -> ClusterAssignSphere? {
  let z = z_plane.d() / z_plane.normal_d().z
  let distance_to_plane = z - sphere.center.z
  if distance_to_plane.abs() > sphere.radius {
    return None
  }
  Some(ClusterAssignSphere::{
    center: @math.Vec3::new(sphere.center.x, sphere.center.y, z),
    radius: @math.sqrt(
      sphere.radius * sphere.radius - distance_to_plane * distance_to_plane,
    ),
  })
}

///|
fn cluster_assign_project_to_plane_y(
  sphere : ClusterAssignSphere,
  y_plane : @math.HalfSpace,
  is_orthographic : Bool,
) -> ClusterAssignSphere? {
  let distance_to_plane = if is_orthographic {
    y_plane.d() - sphere.center.y
  } else {
    -cluster_assign_vec3_yz_dot(sphere.center, y_plane.normal())
  }
  if distance_to_plane.abs() > sphere.radius {
    return None
  }
  Some(ClusterAssignSphere::{
    center: sphere.center.add(y_plane.normal().mul_scalar(distance_to_plane)),
    radius: @math.sqrt(
      sphere.radius * sphere.radius - distance_to_plane * distance_to_plane,
    ),
  })
}

///|
fn cluster_assign_view_z_to_z_slice(
  cluster_factors : @math.Vec2,
  z_slices : Int,
  view_z : Float,
  is_orthographic : Bool,
) -> Int {
  let safe_z_slices = if z_slices <= 0 { 1 } else { z_slices }
  let z_slice = if is_orthographic {
    ((view_z - cluster_factors.x) * cluster_factors.y).floor().to_int()
  } else {
    let positive_z = if -view_z <= 1.0e-6F { 1.0e-6F } else { -view_z }
    (Float::from_double(@math_core.ln(positive_z.to_double())) *
    cluster_factors.x -
    cluster_factors.y +
    1.0F).to_int()
  }
  if z_slice < 0 {
    0
  } else if z_slice >= safe_z_slices {
    safe_z_slices - 1
  } else {
    z_slice
  }
}

///|
fn cluster_assign_ndc_to_cluster(
  dimensions_x : Int,
  dimensions_y : Int,
  dimensions_z : Int,
  cluster_factors : @math.Vec2,
  is_orthographic : Bool,
  ndc : @math.Vec3,
) -> (Int, Int, Int) {
  let safe_x = if dimensions_x <= 0 { 1 } else { dimensions_x }
  let safe_y = if dimensions_y <= 0 { 1 } else { dimensions_y }
  let safe_z = if dimensions_z <= 0 { 1 } else { dimensions_z }
  let frag_x = (ndc.x * 0.5F + 0.5F).clamp(min=0.0F, max=1.0F)
  let frag_y = (ndc.y * -0.5F + 0.5F).clamp(min=0.0F, max=1.0F)
  let mut x = (frag_x * cluster_assign_float_from_int(safe_x)).floor().to_int()
  let mut y = (frag_y * cluster_assign_float_from_int(safe_y)).floor().to_int()
  let z = cluster_assign_view_z_to_z_slice(
    cluster_factors,
    safe_z,
    ndc.z,
    is_orthographic,
  )
  if x >= safe_x {
    x = safe_x - 1
  }
  if y >= safe_y {
    y = safe_y - 1
  }
  (x, y, z)
}

///|
fn cluster_assign_fill_object_clusters(
  clusters : Clusters,
  visible : VisibleClusterableObjects,
  object : ClusterableObjectAssignmentData,
  view_layers : @camera_render_layers.RenderLayers,
  clip_from_view : ClusterProjectionMatrix3d,
  view_from_clip : ClusterProjectionMatrix3d,
  view_from_world : ClusterProjectionMatrix3d,
  view_from_world_scale : @math.Vec3,
  view_from_world_scale_max : Float,
  screen_width : Int,
  screen_height : Int,
  cluster_factors : @math.Vec2,
  is_orthographic : Bool,
) -> Unit {
  if !view_layers.intersects(object.render_layers) {
    return
  }
  let view_clusterable_object_sphere = ClusterAssignSphere::{
    center: cluster_assign_vec4_xyz(
      view_from_world.mul_vec4(
        @math.Vec4::new(
          object.transform.translation.x,
          object.transform.translation.y,
          object.transform.translation.z,
          1.0F,
        ),
      ),
    ),
    radius: object.range * view_from_world_scale_max,
  }
  let center_view4 = view_from_world.mul_vec4(
    @math.Vec4::new(
      object.transform.translation.x,
      object.transform.translation.y,
      object.transform.translation.z,
      1.0F,
    ),
  )
  let center_view = @math.Vec3::new(
    center_view4.x,
    center_view4.y,
    center_view4.z,
  )
  guard cluster_assign_clusterable_object_aabb(
      view_from_world, view_from_world_scale, clip_from_view, object,
    )
    is Some((aabb_min, aabb_max)) else {
    return
  }
  visible.add(object.entity, object.object_type)
  let min_cluster = cluster_assign_ndc_to_cluster(
    clusters.dimensions_x,
    clusters.dimensions_y,
    clusters.dimensions_z,
    cluster_factors,
    is_orthographic,
    aabb_min,
  )
  let max_cluster = cluster_assign_ndc_to_cluster(
    clusters.dimensions_x,
    clusters.dimensions_y,
    clusters.dimensions_z,
    cluster_factors,
    is_orthographic,
    aabb_max,
  )
  let min_x = if min_cluster.0 < max_cluster.0 {
    min_cluster.0
  } else {
    max_cluster.0
  }
  let max_x = if min_cluster.0 > max_cluster.0 {
    min_cluster.0
  } else {
    max_cluster.0
  }
  let min_y = if min_cluster.1 < max_cluster.1 {
    min_cluster.1
  } else {
    max_cluster.1
  }
  let max_y = if min_cluster.1 > max_cluster.1 {
    min_cluster.1
  } else {
    max_cluster.1
  }
  let min_z = if min_cluster.2 < max_cluster.2 {
    min_cluster.2
  } else {
    max_cluster.2
  }
  let max_z = if min_cluster.2 > max_cluster.2 {
    min_cluster.2
  } else {
    max_cluster.2
  }
  let x_planes : Array[@math.HalfSpace] = []
  let y_planes : Array[@math.HalfSpace] = []
  let z_planes : Array[@math.HalfSpace] = []
  if is_orthographic {
    let x_slices = cluster_assign_float_from_int(clusters.dimensions_x)
    for x in 0..<=clusters.dimensions_x {
      let x_proportion = cluster_assign_float_from_int(x) / x_slices
      let x_pos = x_proportion * 2.0F - 1.0F
      let view_x = cluster_assign_clip_to_view(
          view_from_clip,
          @math.Vec4::new(x_pos, 0.0F, 1.0F, 1.0F),
        ).x
      x_planes.push(
        @math.HalfSpace::new(@math.Vec4::new(1.0F, 0.0F, 0.0F, view_x)),
      )
    }
    let y_slices = cluster_assign_float_from_int(clusters.dimensions_y)
    for y in 0..<=clusters.dimensions_y {
      let y_proportion = 1.0F - cluster_assign_float_from_int(y) / y_slices
      let y_pos = y_proportion * 2.0F - 1.0F
      let view_y = cluster_assign_clip_to_view(
          view_from_clip,
          @math.Vec4::new(0.0F, y_pos, 1.0F, 1.0F),
        ).y
      y_planes.push(
        @math.HalfSpace::new(@math.Vec4::new(0.0F, 1.0F, 0.0F, view_y)),
      )
    }
  } else {
    let x_slices = cluster_assign_float_from_int(clusters.dimensions_x)
    for x in 0..<=clusters.dimensions_x {
      let x_proportion = cluster_assign_float_from_int(x) / x_slices
      let x_pos = x_proportion * 2.0F - 1.0F
      let nb = cluster_assign_vec4_xyz(
        cluster_assign_clip_to_view(
          view_from_clip,
          @math.Vec4::new(x_pos, -1.0F, 1.0F, 1.0F),
        ),
      )
      let nt = cluster_assign_vec4_xyz(
        cluster_assign_clip_to_view(
          view_from_clip,
          @math.Vec4::new(x_pos, 1.0F, 1.0F, 1.0F),
        ),
      )
      let normal = nb.cross(nt)
      x_planes.push(
        @math.HalfSpace::new(
          @math.Vec4::new(normal.x, normal.y, normal.z, nb.dot(normal)),
        ),
      )
    }
    let y_slices = cluster_assign_float_from_int(clusters.dimensions_y)
    for y in 0..<=clusters.dimensions_y {
      let y_proportion = 1.0F - cluster_assign_float_from_int(y) / y_slices
      let y_pos = y_proportion * 2.0F - 1.0F
      let nl = cluster_assign_vec4_xyz(
        cluster_assign_clip_to_view(
          view_from_clip,
          @math.Vec4::new(-1.0F, y_pos, 1.0F, 1.0F),
        ),
      )
      let nr = cluster_assign_vec4_xyz(
        cluster_assign_clip_to_view(
          view_from_clip,
          @math.Vec4::new(1.0F, y_pos, 1.0F, 1.0F),
        ),
      )
      let normal = nr.cross(nl)
      y_planes.push(
        @math.HalfSpace::new(
          @math.Vec4::new(normal.x, normal.y, normal.z, nr.dot(normal)),
        ),
      )
    }
  }
  for z in 0..<=clusters.dimensions_z {
    let view_z = cluster_assign_z_slice_to_view_z(
      clusters.near,
      clusters.far,
      clusters.dimensions_z,
      z,
      is_orthographic,
    )
    z_planes.push(
      @math.HalfSpace::new(@math.Vec4::new(0.0F, 0.0F, -1.0F, -view_z)),
    )
  }
  let object_center_clip = clip_from_view.mul_vec4(
    @math.Vec4::new(center_view.x, center_view.y, center_view.z, 1.0F),
  )
  let object_center_ndc = if object_center_clip.w == 0.0F {
    @math.Vec3::zero()
  } else {
    cluster_assign_vec4_xyz(object_center_clip).mul_scalar(
      1.0F / object_center_clip.w,
    )
  }
  let cluster_coordinates = cluster_assign_ndc_to_cluster(
    clusters.dimensions_x,
    clusters.dimensions_y,
    clusters.dimensions_z,
    cluster_factors,
    is_orthographic,
    @math.Vec3::new(
      object_center_ndc.x,
      object_center_ndc.y,
      view_clusterable_object_sphere.center.z,
    ),
  )
  let z_center : Int? = if object_center_ndc.z <= 1.0F {
    Some(cluster_coordinates.2)
  } else {
    None
  }
  let y_center : Int? = if object_center_ndc.y > 1.0F {
    None
  } else if object_center_ndc.y < -1.0F {
    Some(clusters.dimensions_y + 1)
  } else {
    Some(cluster_coordinates.1)
  }
  let cluster_aabb_spheres : Array[ClusterAssignSphere?] = []
  for _ in 0..<clusters.clusterable_objects.length() {
    cluster_aabb_spheres.push(None)
  }
  for z in min_z..<=max_z {
    let mut z_object = view_clusterable_object_sphere
    let z_matches_center = match z_center {
      Some(center_z) => z == center_z
      None => false
    }
    if !z_matches_center {
      let z_plane = match z_center {
        Some(center_z) if z < center_z => z_planes[z + 1]
        _ => z_planes[z]
      }
      guard cluster_assign_project_to_plane_z(z_object, z_plane)
        is Some(projected_z_object) else {
        continue
      }
      z_object = projected_z_object
    }
    for y in min_y..<=max_y {
      let mut y_object = z_object
      let y_matches_center = match y_center {
        Some(center_y) => y == center_y
        None => false
      }
      if !y_matches_center {
        let y_plane = match y_center {
          Some(center_y) if y < center_y => y_planes[y + 1]
          _ => y_planes[y]
        }
        guard cluster_assign_project_to_plane_y(
            y_object, y_plane, is_orthographic,
          )
          is Some(projected_y_object) else {
          continue
        }
        y_object = projected_y_object
      }
      let mut refined_min_x = min_x
      while true {
        if refined_min_x >= max_x ||
          -cluster_assign_get_distance_x(
            x_planes[refined_min_x + 1],
            y_object.center,
            is_orthographic,
          ) +
          y_object.radius >
          0.0F {
          break
        }
        refined_min_x += 1
      }
      let mut refined_max_x = max_x
      while true {
        if refined_max_x <= refined_min_x ||
          cluster_assign_get_distance_x(
            x_planes[refined_max_x],
            y_object.center,
            is_orthographic,
          ) +
          y_object.radius >
          0.0F {
          break
        }
        refined_max_x -= 1
      }
      let mut cluster_index = (y * clusters.dimensions_x + refined_min_x) *
        clusters.dimensions_z +
        z
      match object.object_type {
        SpotLight(_, _, outer_angle) => {
          let sin_outer = @math.sin(outer_angle)
          let cos_outer = @math.cos(outer_angle)
          let view_light_direction = cluster_assign_vec4_xyz(
            view_from_world.mul_vec4(
              @math.Vec4::new(
                object.transform.back().x,
                object.transform.back().y,
                object.transform.back().z,
                0.0F,
              ),
            ),
          ).normalize_or_zero()
          for x in refined_min_x..<=refined_max_x {
            let cluster_sphere = match cluster_aabb_spheres[cluster_index] {
              Some(sphere) => sphere
              None => {
                let sphere = cluster_assign_compute_cluster_aabb_sphere(
                  clusters.near,
                  clusters.far,
                  clusters.tile_size_x,
                  clusters.tile_size_y,
                  screen_width,
                  screen_height,
                  view_from_clip,
                  is_orthographic,
                  clusters.dimensions_z,
                  x,
                  y,
                  z,
                )
                cluster_aabb_spheres[cluster_index] = Some(sphere)
                sphere
              }
            }
            let spot_light_offset = view_clusterable_object_sphere.center.sub(
              cluster_sphere.center,
            )
            let spot_light_dist_sq = spot_light_offset.length_squared()
            let v1_len = spot_light_offset.dot(view_light_direction)
            let closest_radial_sq = spot_light_dist_sq - v1_len * v1_len
            let closest_radial = if closest_radial_sq <= 0.0F {
              0.0F
            } else {
              @math.sqrt(closest_radial_sq)
            }
            let distance_closest_point = cos_outer * closest_radial -
              v1_len * sin_outer
            let angle_cull = distance_closest_point > cluster_sphere.radius
            let front_cull = v1_len >
              cluster_sphere.radius + object.range * view_from_world_scale_max
            let back_cull = v1_len < -cluster_sphere.radius
            if !angle_cull && !front_cull && !back_cull {
              clusters.clusterable_objects[cluster_index].add_spot_light(
                object.entity,
              )
            }
            cluster_index += clusters.dimensions_z
          }
        }
        PointLight(_, _) =>
          for _ in refined_min_x..<=refined_max_x {
            clusters.clusterable_objects[cluster_index].add_point_light(
              object.entity,
            )
            cluster_index += clusters.dimensions_z
          }
        ReflectionProbe =>
          for _ in refined_min_x..<=refined_max_x {
            clusters.clusterable_objects[cluster_index].add_reflection_probe(
              object.entity,
            )
            cluster_index += clusters.dimensions_z
          }
        IrradianceVolume =>
          for _ in refined_min_x..<=refined_max_x {
            clusters.clusterable_objects[cluster_index].add_irradiance_volume(
              object.entity,
            )
            cluster_index += clusters.dimensions_z
          }
        Decal =>
          for _ in refined_min_x..<=refined_max_x {
            clusters.clusterable_objects[cluster_index].add_decal(object.entity)
            cluster_index += clusters.dimensions_z
          }
      }
    }
  }
}

///|
pub fn cluster_assign_lights_system(world : @ecs.World) -> Unit {
  let clusterable_objects = cluster_assign_collect_objects(world)
  let global_cluster_settings = match
    world.get_resource(ecs_key_global_cluster_settings) {
    Some(settings) => settings
    None => GlobalClusterSettings::GlobalClusterSettings()
  }
  let camera_entities = []
  world.for_each_component(@camera_components3d.ecs_key_camera3d, fn(
    entity,
    _camera3d,
  ) {
    camera_entities.push(entity)
  })
  for entity in camera_entities {
    let config = match
      (try! world.get_by_key(entity, ClusterConfig::component())) {
      Some(cluster_config) => cluster_config
      None => ClusterConfig::default()
    }
    let previous_clusters = try! world.get_by_key(entity, Clusters::component())
    if config is ClusterConfig::None {
      cluster_assign_clear_view(world, entity, previous_clusters)
      continue
    }
    let camera = match
      (try! world.get_by_key(entity, @camera_camera.ecs_key_camera)) {
      Some(camera_component) => camera_component
      None => continue
    }
    let (screen_width, screen_height) = cluster_assign_viewport_size(camera)
    if screen_width == 0 || screen_height == 0 {
      cluster_assign_clear_view(world, entity, previous_clusters)
      continue
    }
    let projection = cluster_assign_camera_projection(
      world, entity, screen_width, screen_height,
    )
    let camera_transform = cluster_assign_entity_transform(world, entity)
    let view_from_world = cluster_assign_view_from_world_matrix(
      camera_transform,
    )
    let clip_from_view = projection.clip_from_view()
    let view_from_clip = match clip_from_view.inverse() {
      Some(value) => value
      None => {
        cluster_assign_clear_view(world, entity, previous_clusters)
        continue
      }
    }
    let view_from_world_scale = @math.Vec3::new(
      1.0F / camera_transform.scale.x,
      1.0F / camera_transform.scale.y,
      1.0F / camera_transform.scale.z,
    )
    let view_from_world_scale_max = cluster_assign_vec3_abs(
      view_from_world_scale,
    ).max_element()
    let is_orthographic = projection.is_orthographic()
    let view_layers = cluster_assign_entity_render_layers(world, entity)
    let requested_dimensions = cluster_config_dimensions_for_screen_size(
      config, screen_width, screen_height,
    )
    let mut dimensions_x = requested_dimensions.0
    let mut dimensions_y = requested_dimensions.1
    let dimensions_z = requested_dimensions.2
    if cluster_config_dynamic_resizing(config) {
      match previous_clusters {
        Some(previous) =>
          match previous.last_frame_total_cluster_index_count {
            Some(previous_index_count) =>
              if previous_index_count >
                global_cluster_settings.view_cluster_bindings_max_indices {
                let index_ratio = Float::from_double(
                    global_cluster_settings.view_cluster_bindings_max_indices.to_double(),
                  ) /
                  Float::from_double(previous_index_count.to_double())
                let xy_ratio = @math.sqrt(index_ratio)
                let resized_x = @math_core.floor(
                  (Float::from_double(dimensions_x.to_double()) * xy_ratio).to_double(),
                ).to_int()
                let resized_y = @math_core.floor(
                  (Float::from_double(dimensions_y.to_double()) * xy_ratio).to_double(),
                ).to_int()
                dimensions_x = if resized_x < 1 { 1 } else { resized_x }
                dimensions_y = if resized_y < 1 { 1 } else { resized_y }
              }
            _ => ()
          }
        None => ()
      }
    }
    let tile_size_x = cluster_assign_tile_size(screen_width, dimensions_x)
    let tile_size_y = cluster_assign_tile_size(screen_height, dimensions_y)
    let cluster_count = dimensions_x * dimensions_y * dimensions_z
    let mut far = match cluster_config_far_z_mode(config) {
      ClusterFarZMode::MaxClusterableObjectRange =>
        match previous_clusters {
          Some(previous) =>
            match previous.last_frame_farthest_z {
              Some(value) => value
              None => DEFAULT_FAR_DEPTH
            }
          None => DEFAULT_FAR_DEPTH
        }
      ClusterFarZMode::Constant(value) => value
    }
    let mut near = cluster_config_first_slice_depth(config)
    if is_orthographic {
      near = projection.orthographic_first_slice_depth()
    } else if dimensions_z == 1 && far > near {
      near = far
    }
    if far < near {
      far = near
    }
    let clusters = Clusters::{
      tile_size_x,
      tile_size_y,
      dimensions_x,
      dimensions_y,
      dimensions_z,
      near,
      far,
      last_frame_farthest_z: None,
      last_frame_total_cluster_index_count: None,
      clusterable_objects: cluster_assign_cluster_objects(cluster_count),
    }
    let visible = VisibleClusterableObjects::new()
    let cluster_factors = calculate_cluster_factors(
      near,
      far,
      cluster_assign_float_from_int(dimensions_z),
      is_orthographic,
    )
    let mut current_frame_farthest_z = 0.0F
    for object in clusterable_objects {
      if !view_layers.intersects(object.render_layers) {
        continue
      }
      let view_position = view_from_world.mul_vec4(
        @math.Vec4::new(
          object.transform.translation.x,
          object.transform.translation.y,
          object.transform.translation.z,
          1.0F,
        ),
      )
      let object_far = -view_position.z + object.range * view_from_world_scale.z
      if object_far > current_frame_farthest_z {
        current_frame_farthest_z = object_far
      }
      cluster_assign_fill_object_clusters(
        clusters, visible, object, view_layers, clip_from_view, view_from_clip, view_from_world,
        view_from_world_scale, view_from_world_scale_max, screen_width, screen_height,
        cluster_factors, is_orthographic,
      )
    }
    let mut total_cluster_index_count = 0
    for cluster in clusters.clusterable_objects {
      total_cluster_index_count += cluster.clusterables.length()
    }
    clusters.last_frame_total_cluster_index_count = Some(
      total_cluster_index_count,
    )
    clusters.last_frame_farthest_z = Some(current_frame_farthest_z)
    try! world.set_by_key(entity, Clusters::component(), clusters)
    try! world.set_by_key(
      entity,
      VisibleClusterableObjects::component(),
      visible,
    )
  }
}
