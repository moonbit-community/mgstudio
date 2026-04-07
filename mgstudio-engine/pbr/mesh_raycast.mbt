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
const MESH_RAY_CAST_DEFAULT_MAX_DISTANCE : Float = 1_000_000.0F

///|
const MESH_RAY_CAST_DEFAULT_RAY_EPSILON : Float = 0.000001F

///|
const MESH_RAY_CAST_DEFAULT_MAX_HITS : Int = 64

///|
pub struct MeshRayCastSettings {
  max_distance : Float
  ray_epsilon : Float
  max_hits : Int
  include_invisible : Bool
  only_entities : Array[@core.Entity]?
}

///|
pub fn MeshRayCastSettings::default() -> MeshRayCastSettings {
  {
    max_distance: MESH_RAY_CAST_DEFAULT_MAX_DISTANCE,
    ray_epsilon: MESH_RAY_CAST_DEFAULT_RAY_EPSILON,
    max_hits: MESH_RAY_CAST_DEFAULT_MAX_HITS,
    include_invisible: false,
    only_entities: None,
  }
}

///|
pub fn MeshRayCastSettings::with_max_distance(
  self : MeshRayCastSettings,
  max_distance : Float,
) -> MeshRayCastSettings {
  MeshRayCastSettings::{ ..self, max_distance, }
}

///|
pub fn MeshRayCastSettings::with_ray_epsilon(
  self : MeshRayCastSettings,
  ray_epsilon : Float,
) -> MeshRayCastSettings {
  MeshRayCastSettings::{ ..self, ray_epsilon, }
}

///|
pub fn MeshRayCastSettings::with_max_hits(
  self : MeshRayCastSettings,
  max_hits : Int,
) -> MeshRayCastSettings {
  MeshRayCastSettings::{ ..self, max_hits, }
}

///|
pub fn MeshRayCastSettings::with_include_invisible(
  self : MeshRayCastSettings,
  include_invisible : Bool,
) -> MeshRayCastSettings {
  MeshRayCastSettings::{ ..self, include_invisible, }
}

///|
pub fn MeshRayCastSettings::with_only_entities(
  self : MeshRayCastSettings,
  only_entities : Array[@core.Entity]?,
) -> MeshRayCastSettings {
  MeshRayCastSettings::{ ..self, only_entities, }
}

///|
pub struct MeshRayCastHit {
  point : @math.Vec3
  normal : @math.Vec3
  distance : Float
}

///|
fn render3d_entity_eq(a : @core.Entity, b : @core.Entity) -> Bool {
  a.id == b.id && a.generation == b.generation
}

///|
fn render3d_entity_in_list(
  entity : @core.Entity,
  entities : Array[@core.Entity],
) -> Bool {
  for candidate in entities {
    if render3d_entity_eq(entity, candidate) {
      return true
    }
  }
  false
}

///|
pub fn mesh_ray_cast(
  world : @ecs.World,
  origin : @math.Vec3,
  direction : @math.Vec3,
  settings : MeshRayCastSettings,
) -> Array[(@core.Entity, MeshRayCastHit)] {
  let ray_direction = direction.normalize_or_zero()
  if ray_direction.length_squared() <= 1.0e-12F {
    return []
  }
  let max_distance = if settings.max_distance <= 0.0F {
    MESH_RAY_CAST_DEFAULT_MAX_DISTANCE
  } else {
    settings.max_distance
  }
  let ray_epsilon = if settings.ray_epsilon <= 0.0F {
    MESH_RAY_CAST_DEFAULT_RAY_EPSILON
  } else {
    settings.ray_epsilon
  }
  let max_hits = if settings.max_hits <= 0 { 1 } else { settings.max_hits }
  let hits : Array[(@core.Entity, MeshRayCastHit)] = []
  world.for_each_component(ecs_key_mesh3d, fn(entity, mesh3d) {
    if settings.only_entities is Some(only_entities) &&
      !render3d_entity_in_list(entity, only_entities) {
      return
    }
    if !settings.include_invisible &&
      (try! world.get_by_key(entity, @visibility.ecs_key_view_visibility))
      is Some(view_visibility) &&
      !view_visibility.is_visible() {
      return
    }
    guard render3d_mesh_local_aabb(mesh3d) is Some((min_corner, max_corner)) else {
      return
    }
    let transform = match
      (try! world.get_by_key(entity, @transform.ecs_key_transform)) {
      Some(value) => value
      None => @transform.Transform::identity()
    }
    guard render3d_inverse_transform_point(transform, origin)
      is Some(local_origin) else {
      return
    }
    guard render3d_inverse_transform_direction(transform, ray_direction)
      is Some(local_direction) else {
      return
    }
    guard render3d_ray_local_aabb_hit(
        local_origin, local_direction, min_corner, max_corner, ray_epsilon, max_distance,
      )
      is Some((distance, local_normal)) else {
      return
    }
    let normal = render3d_transform_local_normal(transform, local_normal)
    if normal.length_squared() <= 1.0e-12F {
      return
    }
    hits.push(
      (
        entity,
        {
          point: origin.add(ray_direction.mul_scalar(distance)),
          normal,
          distance,
        },
      ),
    )
  })

  hits.sort_by(fn(a, b) {
    let distance_cmp = cmp_float(a.1.distance, b.1.distance)
    if distance_cmp != 0 {
      return distance_cmp
    }
    let id_cmp = cmp_int(a.0.id, b.0.id)
    if id_cmp != 0 {
      return id_cmp
    }
    cmp_int(a.0.generation, b.0.generation)
  })

  let capped_hits : Array[(@core.Entity, MeshRayCastHit)] = []
  for i in 0..<hits.length() {
    if i >= max_hits {
      break
    }
    capped_hits.push(hits[i])
  }
  capped_hits
}

///|
pub fn mesh_ray_cast_first(
  world : @ecs.World,
  origin : @math.Vec3,
  direction : @math.Vec3,
  settings : MeshRayCastSettings,
) -> (@core.Entity, MeshRayCastHit)? {
  let hits = mesh_ray_cast(world, origin, direction, settings.with_max_hits(1))
  if hits.length() > 0 {
    Some(hits[0])
  } else {
    None
  }
}

///|
pub fn mesh_ray_cast_from_camera(
  world : @ecs.World,
  screen : @math.Vec2,
  camera : @sprite.Camera,
  projection : Projection,
  camera_transform : @transform.Transform,
  target_size : @math.IVec2,
  scale_factor : Float,
  settings : MeshRayCastSettings,
) -> Array[(@core.Entity, MeshRayCastHit)] {
  if render3d_camera_viewport_to_world_ray(
      screen, camera, projection, camera_transform, target_size, scale_factor,
    )
    is Some((origin, direction)) {
    mesh_ray_cast(world, origin, direction, settings)
  } else {
    []
  }
}

///|
pub fn mesh_ray_cast_from_camera_first(
  world : @ecs.World,
  screen : @math.Vec2,
  camera : @sprite.Camera,
  projection : Projection,
  camera_transform : @transform.Transform,
  target_size : @math.IVec2,
  scale_factor : Float,
  settings : MeshRayCastSettings,
) -> (@core.Entity, MeshRayCastHit)? {
  let hits = mesh_ray_cast_from_camera(
    world,
    screen,
    camera,
    projection,
    camera_transform,
    target_size,
    scale_factor,
    settings.with_max_hits(1),
  )
  if hits.length() > 0 {
    Some(hits[0])
  } else {
    None
  }
}

///|
pub fn render3d_camera_viewport_to_world_ray(
  screen : @math.Vec2,
  camera : @sprite.Camera,
  projection : Projection,
  camera_transform : @transform.Transform,
  target_size : @math.IVec2,
  scale_factor : Float,
) -> (@math.Vec3, @math.Vec3)? {
  guard render3d_camera_viewport_rect_logical(camera, target_size, scale_factor)
    is Some((viewport_x, viewport_y, viewport_width, viewport_height)) else {
    return None
  }
  if screen.x < viewport_x ||
    screen.y < viewport_y ||
    screen.x > viewport_x + viewport_width ||
    screen.y > viewport_y + viewport_height {
    return None
  }
  let viewport_local_x = (screen.x - viewport_x) / viewport_width
  let viewport_local_y = (screen.y - viewport_y) / viewport_height
  let ndc_x = viewport_local_x * 2.0F - 1.0F
  let ndc_y = 1.0F - viewport_local_y * 2.0F
  let runtime_projection = render3d_projection_runtime_projection(
    projection, camera, target_size, scale_factor,
  )
  let clip_from_view = runtime_projection.get_clip_from_view()
  guard render3d_projection_matrix_inverse(clip_from_view)
    is Some(view_from_clip) else {
    return None
  }
  let near_view_h = view_from_clip.mul_vec4(
    @math.Vec4::new(ndc_x, ndc_y, 1.0F, 1.0F),
  )
  let far_view_h = view_from_clip.mul_vec4(
    @math.Vec4::new(ndc_x, ndc_y, 0.0F, 1.0F),
  )
  if near_view_h.w == 0.0F || far_view_h.w == 0.0F {
    return None
  }
  let near_view = @math.Vec3::new(
    near_view_h.x / near_view_h.w,
    near_view_h.y / near_view_h.w,
    near_view_h.z / near_view_h.w,
  )
  let far_view = @math.Vec3::new(
    far_view_h.x / far_view_h.w,
    far_view_h.y / far_view_h.w,
    far_view_h.z / far_view_h.w,
  )
  let ray_camera = far_view.sub(near_view).normalize_or_zero()
  if ray_camera.length_squared() <= 1.0e-12F {
    return None
  }
  let ray_world = quat_rotate_vec3(camera_transform.rotation, ray_camera).normalize_or_zero()
  if ray_world.length_squared() <= 1.0e-12F {
    return None
  }
  Some(
    (
      camera_transform.translation.add(
        quat_rotate_vec3(camera_transform.rotation, near_view),
      ),
      ray_world,
    ),
  )
}

///|
pub fn render3d_camera_world_to_viewport(
  world : @math.Vec3,
  camera : @sprite.Camera,
  projection : Projection,
  camera_transform : @transform.Transform,
  target_size : @math.IVec2,
  scale_factor : Float,
) -> @math.Vec2? {
  guard render3d_camera_viewport_rect_logical(camera, target_size, scale_factor)
    is Some((viewport_x, viewport_y, viewport_width, viewport_height)) else {
    return None
  }
  let to_world = world.sub(camera_transform.translation)
  let inv_rotation = render3d_quat_conjugate(camera_transform.rotation).normalize()
  let view_pos = quat_rotate_vec3(inv_rotation, to_world)
  let runtime_projection = render3d_projection_runtime_projection(
    projection, camera, target_size, scale_factor,
  )
  guard runtime_projection.get_clip_from_view().project_point3(view_pos)
    is Some(ndc_point) else {
    return None
  }
  if ndc_point.z < 0.0F || ndc_point.z > 1.0F {
    return None
  }
  let ndc_x = ndc_point.x
  let ndc_y = ndc_point.y
  let local_x = (ndc_x + 1.0F) * 0.5F * viewport_width
  let local_y = (1.0F - ndc_y) * 0.5F * viewport_height
  if local_x < 0.0F ||
    local_y < 0.0F ||
    local_x > viewport_width ||
    local_y > viewport_height {
    return None
  }
  Some(@math.Vec2::new(local_x + viewport_x, local_y + viewport_y))
}
