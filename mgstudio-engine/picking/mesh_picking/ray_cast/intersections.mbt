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

///|
// Bevy source: `bevy/crates/bevy_picking/src/mesh_picking/ray_cast/intersections.rs`.

///|
const MESH_RAY_CAST_DEFAULT_MAX_DISTANCE : Float = 1_000_000.0F

///|
const MESH_RAY_CAST_DEFAULT_RAY_EPSILON : Float = 0.000001F

///|
const MESH_RAY_CAST_DEFAULT_MAX_HITS : Int = 64

///|
pub struct MeshRayCastIntersectionSettings {
  max_distance : Float
  ray_epsilon : Float
  max_hits : Int
  include_invisible : Bool
  only_entities : Array[@core.Entity]?
}

///|
pub fn MeshRayCastIntersectionSettings::default() -> MeshRayCastIntersectionSettings {
  {
    max_distance: MESH_RAY_CAST_DEFAULT_MAX_DISTANCE,
    ray_epsilon: MESH_RAY_CAST_DEFAULT_RAY_EPSILON,
    max_hits: MESH_RAY_CAST_DEFAULT_MAX_HITS,
    include_invisible: false,
    only_entities: None,
  }
}

///|
pub fn MeshRayCastIntersectionSettings::with_max_distance(
  self : MeshRayCastIntersectionSettings,
  max_distance : Float,
) -> MeshRayCastIntersectionSettings {
  MeshRayCastIntersectionSettings::{ ..self, max_distance, }
}

///|
pub fn MeshRayCastIntersectionSettings::with_ray_epsilon(
  self : MeshRayCastIntersectionSettings,
  ray_epsilon : Float,
) -> MeshRayCastIntersectionSettings {
  MeshRayCastIntersectionSettings::{ ..self, ray_epsilon, }
}

///|
pub fn MeshRayCastIntersectionSettings::with_max_hits(
  self : MeshRayCastIntersectionSettings,
  max_hits : Int,
) -> MeshRayCastIntersectionSettings {
  MeshRayCastIntersectionSettings::{ ..self, max_hits, }
}

///|
pub fn MeshRayCastIntersectionSettings::with_include_invisible(
  self : MeshRayCastIntersectionSettings,
  include_invisible : Bool,
) -> MeshRayCastIntersectionSettings {
  MeshRayCastIntersectionSettings::{ ..self, include_invisible, }
}

///|
pub fn MeshRayCastIntersectionSettings::with_only_entities(
  self : MeshRayCastIntersectionSettings,
  only_entities : Array[@core.Entity]?,
) -> MeshRayCastIntersectionSettings {
  MeshRayCastIntersectionSettings::{ ..self, only_entities, }
}

///|
pub struct MeshRayCastIntersectionHit {
  point : @math.Vec3
  normal : @math.Vec3
  distance : Float
}

///|
fn mesh_ray_cast_entity_eq(a : @core.Entity, b : @core.Entity) -> Bool {
  a.id == b.id && a.generation == b.generation
}

///|
fn mesh_ray_cast_entity_in_list(
  entity : @core.Entity,
  entities : Array[@core.Entity],
) -> Bool {
  for candidate in entities {
    if mesh_ray_cast_entity_eq(entity, candidate) {
      return true
    }
  }
  false
}

///|
fn mesh_ray_cast_local_aabb(mesh3d : @pbr.Mesh3d) -> (@math.Vec3, @math.Vec3)? {
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
fn mesh_ray_cast_local_aabb_hit(
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
pub fn mesh_ray_cast_intersections(
  world : @ecs.World,
  origin : @math.Vec3,
  direction : @math.Vec3,
  settings : MeshRayCastIntersectionSettings,
) -> Array[(@core.Entity, MeshRayCastIntersectionHit)] {
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
  let hits : Array[(@core.Entity, MeshRayCastIntersectionHit)] = []
  world.for_each_component(@pbr.ecs_key_mesh3d, fn(entity, mesh3d) {
    if settings.only_entities is Some(only_entities) &&
      !mesh_ray_cast_entity_in_list(entity, only_entities) {
      return
    }
    if !settings.include_invisible &&
      (try! world.get_by_key(entity, @visibility.ecs_key_view_visibility))
      is Some(view_visibility) &&
      !view_visibility.is_visible() {
      return
    }
    guard mesh_ray_cast_local_aabb(mesh3d) is Some((min_corner, max_corner)) else {
      return
    }
    let transform = match
      (try! world.get_by_key(entity, @transform.ecs_key_transform)) {
      Some(value) => value
      None => @transform.Transform::identity()
    }
    guard @pbr_render.render3d_inverse_transform_point(transform, origin)
      is Some(local_origin) else {
      return
    }
    guard @pbr_render.render3d_inverse_transform_direction(
        transform, ray_direction,
      )
      is Some(local_direction) else {
      return
    }
    guard mesh_ray_cast_local_aabb_hit(
        local_origin, local_direction, min_corner, max_corner, ray_epsilon, max_distance,
      )
      is Some((distance, local_normal)) else {
      return
    }
    let normal = @pbr_render.render3d_transform_local_normal(
      transform, local_normal,
    )
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
    let distance_cmp = @pbr_render.cmp_float(a.1.distance, b.1.distance)
    if distance_cmp != 0 {
      return distance_cmp
    }
    let id_cmp = @pbr_render.cmp_int(a.0.id, b.0.id)
    if id_cmp != 0 {
      return id_cmp
    }
    @pbr_render.cmp_int(a.0.generation, b.0.generation)
  })

  let capped_hits : Array[(@core.Entity, MeshRayCastIntersectionHit)] = []
  for i in 0..<hits.length() {
    if i >= max_hits {
      break
    }
    capped_hits.push(hits[i])
  }
  capped_hits
}

///|
pub fn mesh_ray_cast_intersections_first(
  world : @ecs.World,
  origin : @math.Vec3,
  direction : @math.Vec3,
  settings : MeshRayCastIntersectionSettings,
) -> (@core.Entity, MeshRayCastIntersectionHit)? {
  let hits = mesh_ray_cast_intersections(
    world,
    origin,
    direction,
    settings.with_max_hits(1),
  )
  if hits.length() > 0 {
    Some(hits[0])
  } else {
    None
  }
}
