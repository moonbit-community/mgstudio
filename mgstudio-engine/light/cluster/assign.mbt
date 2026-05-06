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
  app.add_system(cluster_assign_lights_system)
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
fn cluster_assign_viewport_size(camera : @sprite.Camera) -> (Int, Int) {
  match camera.physical_viewport_size() {
    Some(viewport_size) => {
      let width = if viewport_size.x <= 0 { 1 } else { viewport_size.x }
      let height = if viewport_size.y <= 0 { 1 } else { viewport_size.y }
      (width, height)
    }
    None => (1280, 720)
  }
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
    objects.push(ObjectsInCluster::default())
  }
  objects
}

///|
priv struct ClusterableObjectAssignmentData {
  entity : @core.Entity
  transform : @transform.Transform
  range : Float
  object_type : ClusterableObjectType
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
fn cluster_assign_collect_objects(
  world : @ecs.World,
) -> Array[ClusterableObjectAssignmentData] {
  let objects : Array[ClusterableObjectAssignmentData] = []
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
    })
  })
  world.for_each_component(@light.ecs_key_environment_map_light, fn(
    entity,
    _probe,
  ) {
    if !cluster_assign_is_view_visible(world, entity) {
      return
    }
    objects.push(ClusterableObjectAssignmentData::{
      entity,
      transform: cluster_assign_entity_transform(world, entity),
      range: 1.0F,
      object_type: ClusterableObjectType::ReflectionProbe,
    })
  })
  world.for_each_component(@light.ecs_key_irradiance_volume, fn(
    entity,
    _probe,
  ) {
    if !cluster_assign_is_view_visible(world, entity) {
      return
    }
    objects.push(ClusterableObjectAssignmentData::{
      entity,
      transform: cluster_assign_entity_transform(world, entity),
      range: 1.0F,
      object_type: ClusterableObjectType::IrradianceVolume,
    })
  })
  objects
}

///|
fn cluster_assign_float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
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
fn cluster_assign_project_aabb_corners(
  clip_from_view : ClusterProjectionMatrix3d,
  center_view : @math.Vec3,
  radius : Float,
) -> (@math.Vec3, @math.Vec3)? {
  let mut min_x = 1.0F
  let mut min_y = 1.0F
  let mut min_z = center_view.z - radius
  let mut max_x = -1.0F
  let mut max_y = -1.0F
  let mut max_z = center_view.z + radius
  let mut projected_any = false
  for xi in 0..<2 {
    for yi in 0..<2 {
      for zi in 0..<2 {
        let x_offset = if xi == 0 { -radius } else { radius }
        let y_offset = if yi == 0 { -radius } else { radius }
        let z_offset = if zi == 0 { -radius } else { radius }
        let x = center_view.x + x_offset
        let y = center_view.y + y_offset
        let z = center_view.z + z_offset
        let view_z = if z >= 0.0F { -1.0e-6F } else { z }
        let view_point = @math.Vec3::new(x, y, view_z)
        match clip_from_view.project_point3(view_point) {
          Some(ndc) => {
            projected_any = true
            if ndc.x < min_x {
              min_x = ndc.x
            }
            if ndc.y < min_y {
              min_y = ndc.y
            }
            if ndc.x > max_x {
              max_x = ndc.x
            }
            if ndc.y > max_y {
              max_y = ndc.y
            }
          }
          None => ()
        }
      }
    }
  }
  if !projected_any {
    return None
  }
  if min_x < -1.0F {
    min_x = -1.0F
  }
  if min_y < -1.0F {
    min_y = -1.0F
  }
  if max_x > 1.0F {
    max_x = 1.0F
  }
  if max_y > 1.0F {
    max_y = 1.0F
  }
  if max_x < -1.0F || min_x > 1.0F || max_y < -1.0F || min_y > 1.0F {
    return None
  }
  if min_z >= 0.0F {
    min_z = -1.0e-6F
  }
  if max_z >= 0.0F {
    max_z = -1.0e-6F
  }
  Some(
    (@math.Vec3::new(min_x, min_y, min_z), @math.Vec3::new(max_x, max_y, max_z)),
  )
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
fn cluster_assign_add_object_to_cluster(
  cluster : ObjectsInCluster,
  object : ClusterableObjectAssignmentData,
) -> Unit {
  match object.object_type {
    PointLight(_, _) => cluster.add_point_light(object.entity)
    SpotLight(_, _, _) => cluster.add_spot_light(object.entity)
    ReflectionProbe => cluster.add_reflection_probe(object.entity)
    IrradianceVolume => cluster.add_irradiance_volume(object.entity)
    Decal => cluster.add_decal(object.entity)
  }
}

///|
fn cluster_assign_fill_object_clusters(
  clusters : Clusters,
  visible : VisibleClusterableObjects,
  object : ClusterableObjectAssignmentData,
  clip_from_view : ClusterProjectionMatrix3d,
  view_from_world : ClusterProjectionMatrix3d,
  cluster_factors : @math.Vec2,
  is_orthographic : Bool,
) -> Unit {
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
  guard cluster_assign_project_aabb_corners(
      clip_from_view,
      center_view,
      object.range,
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
  for y in min_y..<=max_y {
    for x in min_x..<=max_x {
      for z in min_z..<=max_z {
        let cluster_index = (y * clusters.dimensions_x + x) *
          clusters.dimensions_z +
          z
        if cluster_index >= 0 &&
          cluster_index < clusters.clusterable_objects.length() {
          cluster_assign_add_object_to_cluster(
            clusters.clusterable_objects[cluster_index],
            object,
          )
        }
      }
    }
  }
}

///|
pub fn cluster_assign_lights_system(world : @ecs.World) -> Unit {
  let clusterable_objects = cluster_assign_collect_objects(world)
  let camera_entities = []
  world.for_each_component(@sprite.ecs_key_camera, fn(entity, _camera) {
    camera_entities.push(entity)
  })
  for entity in camera_entities {
    let config = match
      (try! world.get_by_key(entity, ClusterConfig::component())) {
      Some(cluster_config) => cluster_config
      None => ClusterConfig::default()
    }
    let camera = match (try! world.get_by_key(entity, @sprite.ecs_key_camera)) {
      Some(camera_component) => camera_component
      None => continue
    }
    let (screen_width, screen_height) = cluster_assign_viewport_size(camera)
    let projection = cluster_assign_camera_projection(
      world, entity, screen_width, screen_height,
    )
    let camera_transform = cluster_assign_entity_transform(world, entity)
    let view_from_world = cluster_assign_view_from_world_matrix(
      camera_transform,
    )
    let clip_from_view = projection.clip_from_view()
    let is_orthographic = projection.is_orthographic()
    let (dimensions_x, dimensions_y, dimensions_z) = cluster_config_dimensions_for_screen_size(
      config, screen_width, screen_height,
    )
    let tile_size_x = cluster_assign_tile_size(screen_width, dimensions_x)
    let tile_size_y = cluster_assign_tile_size(screen_height, dimensions_y)
    let cluster_count = dimensions_x * dimensions_y * dimensions_z
    let mut far = match cluster_config_far_z_mode(config) {
      ClusterFarZMode::MaxClusterableObjectRange => 0.0F
      ClusterFarZMode::Constant(value) => value
    }
    if cluster_config_far_z_mode(config)
      is ClusterFarZMode::MaxClusterableObjectRange {
      for object in clusterable_objects {
        let view_position = view_from_world.mul_vec4(
          @math.Vec4::new(
            object.transform.translation.x,
            object.transform.translation.y,
            object.transform.translation.z,
            1.0F,
          ),
        )
        let object_far = -view_position.z + object.range
        if object_far > far {
          far = object_far
        }
      }
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
      clusterable_objects: cluster_assign_cluster_objects(cluster_count),
    }
    let visible = VisibleClusterableObjects::new()
    let cluster_factors = calculate_cluster_factors(
      near,
      far,
      cluster_assign_float_from_int(dimensions_z),
      is_orthographic,
    )
    for object in clusterable_objects {
      cluster_assign_fill_object_clusters(
        clusters, visible, object, clip_from_view, view_from_world, cluster_factors,
        is_orthographic,
      )
    }
    try! world.set_by_key(entity, Clusters::component(), clusters)
    try! world.set_by_key(
      entity,
      VisibleClusterableObjects::component(),
      visible,
    )
  }

  // Keep previously-created non-camera entries in sync for compatibility paths.
  world.for_each_component(VisibleClusterableObjects::component(), fn(
    entity,
    existing,
  ) {
    if (try! world.contains_by_key(entity, @sprite.ecs_key_camera)) {
      return
    }
    let next = VisibleClusterableObjects::new()
    for object in clusterable_objects {
      next.add(object.entity, object.object_type)
    }
    if next != existing {
      try! world.set_by_key(
        entity,
        VisibleClusterableObjects::component(),
        next,
      )
    }
  })
}
