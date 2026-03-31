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
/// High-level query helpers (Bevy-like) built on top of Rapier's QueryPipeline3DReal.

///|
pub struct RayHit3d {
  entity : @core.Entity
  toi : Float
}

///|
pub struct RayHitNormal3d {
  entity : @core.Entity
  toi : Float
  normal : @math.Vec3
}

///|
pub struct PointProjection3d {
  entity : @core.Entity
  point : @math.Vec3
  is_inside : Bool
}

///|
pub struct ShapeCastHit3d {
  entity : @core.Entity
  toi : Float
  point : @math.Vec3
  normal : @math.Vec3
}

///|
fn entity_from_collider_handle(
  ctx : Physics3dContext,
  h : @collision.ColliderHandle3D,
) -> @core.Entity? {
  ctx.collider_to_entity.get(h.into_raw_parts())
}

///|
pub fn Physics3dContext::rigid_body_handle_of(
  self : Physics3dContext,
  entity : @core.Entity,
) -> @dynamics.RigidBodyHandle? {
  self.entity_to_body.get(entity_key(entity))
}

///|
pub fn Physics3dContext::collider_handle_of(
  self : Physics3dContext,
  entity : @core.Entity,
) -> @collision.ColliderHandle3D? {
  self.entity_to_collider.get(entity_key(entity))
}

///|
pub fn Physics3dContext::query_filter_exclude_entity(
  self : Physics3dContext,
  filter : @collision.QueryFilter3DReal,
  entity : @core.Entity,
) -> @collision.QueryFilter3DReal {
  match self.collider_handle_of(entity) {
    Some(h) => filter.exclude_collider(h)
    None =>
      match self.rigid_body_handle_of(entity) {
        Some(bh) => filter.exclude_rigid_body(bh)
        None => filter
      }
  }
}

///|
pub fn Physics3dContext::cast_ray_entity(
  self : Physics3dContext,
  origin : @math.Vec3,
  dir : @math.Vec3,
  max_toi : Float,
  solid : Bool,
) -> RayHit3d? {
  let ray = @collision.Ray3::new(
    mg_vec3_to_rapier(origin),
    mg_vec3_to_rapier(dir),
  )
  match
    self
    .query()
    .cast_ray(self.rigid_bodies, self.colliders, ray, max_toi, solid) {
    Some((h, toi)) =>
      match entity_from_collider_handle(self, h) {
        Some(e) => Some(RayHit3d::{ entity: e, toi })
        None => None
      }
    None => None
  }
}

///|
pub fn Physics3dContext::cast_ray_entity_with_filter(
  self : Physics3dContext,
  origin : @math.Vec3,
  dir : @math.Vec3,
  max_toi : Float,
  solid : Bool,
  filter : @collision.QueryFilter3DReal,
) -> RayHit3d? {
  let ray = @collision.Ray3::new(
    mg_vec3_to_rapier(origin),
    mg_vec3_to_rapier(dir),
  )
  match
    self
    .query()
    .with_filter(filter)
    .cast_ray(self.rigid_bodies, self.colliders, ray, max_toi, solid) {
    Some((h, toi)) =>
      match entity_from_collider_handle(self, h) {
        Some(e) => Some(RayHit3d::{ entity: e, toi })
        None => None
      }
    None => None
  }
}

///|
pub fn Physics3dContext::cast_ray_and_get_normal_entity(
  self : Physics3dContext,
  origin : @math.Vec3,
  dir : @math.Vec3,
  max_toi : Float,
  solid : Bool,
) -> RayHitNormal3d? {
  let ray = @collision.Ray3::new(
    mg_vec3_to_rapier(origin),
    mg_vec3_to_rapier(dir),
  )
  match
    self
    .query()
    .cast_ray_and_get_normal(
      self.rigid_bodies,
      self.colliders,
      ray,
      max_toi,
      solid,
    ) {
    Some((h, inter)) =>
      match entity_from_collider_handle(self, h) {
        Some(e) =>
          Some(RayHitNormal3d::{
            entity: e,
            toi: inter.toi(),
            normal: rapier_vec3_to_mg(inter.normal()),
          })
        None => None
      }
    None => None
  }
}

///|
pub fn Physics3dContext::cast_ray_and_get_normal_entity_with_filter(
  self : Physics3dContext,
  origin : @math.Vec3,
  dir : @math.Vec3,
  max_toi : Float,
  solid : Bool,
  filter : @collision.QueryFilter3DReal,
) -> RayHitNormal3d? {
  let ray = @collision.Ray3::new(
    mg_vec3_to_rapier(origin),
    mg_vec3_to_rapier(dir),
  )
  match
    self
    .query()
    .with_filter(filter)
    .cast_ray_and_get_normal(
      self.rigid_bodies,
      self.colliders,
      ray,
      max_toi,
      solid,
    ) {
    Some((h, inter)) =>
      match entity_from_collider_handle(self, h) {
        Some(e) =>
          Some(RayHitNormal3d::{
            entity: e,
            toi: inter.toi(),
            normal: rapier_vec3_to_mg(inter.normal()),
          })
        None => None
      }
    None => None
  }
}

///|
pub fn Physics3dContext::intersect_ray_entities(
  self : Physics3dContext,
  origin : @math.Vec3,
  dir : @math.Vec3,
  max_toi : Float,
  solid : Bool,
) -> Array[RayHitNormal3d] {
  self.intersect_ray_entities_with_filter(
    origin,
    dir,
    max_toi,
    solid,
    @collision.QueryFilter3DReal::new(),
  )
}

///|
pub fn Physics3dContext::intersect_ray_entities_with_filter(
  self : Physics3dContext,
  origin : @math.Vec3,
  dir : @math.Vec3,
  max_toi : Float,
  solid : Bool,
  filter : @collision.QueryFilter3DReal,
) -> Array[RayHitNormal3d] {
  let ray = @collision.Ray3::new(
    mg_vec3_to_rapier(origin),
    mg_vec3_to_rapier(dir),
  )
  let hits = self
    .query()
    .with_filter(filter)
    .intersect_ray(self.rigid_bodies, self.colliders, ray, max_toi, solid)
  let out : Array[RayHitNormal3d] = []
  for pair in hits {
    let (h, inter) = pair
    if entity_from_collider_handle(self, h) is Some(e) {
      out.push(RayHitNormal3d::{
        entity: e,
        toi: inter.toi(),
        normal: rapier_vec3_to_mg(inter.normal()),
      })
    }
  }
  out
}

///|
pub fn Physics3dContext::intersect_point_entities(
  self : Physics3dContext,
  point : @math.Vec3,
) -> Array[@core.Entity] {
  self.intersect_point_entities_with_filter(
    point,
    @collision.QueryFilter3DReal::new(),
  )
}

///|
pub fn Physics3dContext::intersect_point_entities_with_filter(
  self : Physics3dContext,
  point : @math.Vec3,
  filter : @collision.QueryFilter3DReal,
) -> Array[@core.Entity] {
  let hs = self
    .query()
    .with_filter(filter)
    .intersect_point(
      self.rigid_bodies,
      self.colliders,
      mg_vec3_to_rapier(point),
    )
  let out : Array[@core.Entity] = []
  for h in hs {
    if entity_from_collider_handle(self, h) is Some(e) {
      out.push(e)
    }
  }
  out
}

///|
pub fn Physics3dContext::project_point_entity(
  self : Physics3dContext,
  point : @math.Vec3,
  max_dist : Float,
  solid : Bool,
) -> PointProjection3d? {
  self.project_point_entity_with_filter(
    point,
    max_dist,
    solid,
    @collision.QueryFilter3DReal::new(),
  )
}

///|
pub fn Physics3dContext::project_point_entity_with_filter(
  self : Physics3dContext,
  point : @math.Vec3,
  max_dist : Float,
  solid : Bool,
  filter : @collision.QueryFilter3DReal,
) -> PointProjection3d? {
  match
    self
    .query()
    .with_filter(filter)
    .project_point(
      self.rigid_bodies,
      self.colliders,
      mg_vec3_to_rapier(point),
      max_dist,
      solid,
    ) {
    Some((h, proj)) =>
      match entity_from_collider_handle(self, h) {
        Some(e) =>
          Some(PointProjection3d::{
            entity: e,
            point: rapier_vec3_to_mg(proj.point()),
            is_inside: proj.is_inside(),
          })
        None => None
      }
    None => None
  }
}

///|
pub fn Physics3dContext::intersect_shape_entities(
  self : Physics3dContext,
  shape_pos : @transform.Transform,
  shape : @collision.Shape3D,
) -> Array[@core.Entity] {
  self.intersect_shape_entities_with_filter(
    shape_pos,
    shape,
    @collision.QueryFilter3DReal::new(),
  )
}

///|
pub fn Physics3dContext::intersect_shape_entities_with_filter(
  self : Physics3dContext,
  shape_pos : @transform.Transform,
  shape : @collision.Shape3D,
  filter : @collision.QueryFilter3DReal,
) -> Array[@core.Entity] {
  let hs = self
    .query()
    .with_filter(filter)
    .intersect_shape(
      self.rigid_bodies,
      self.colliders,
      mg_transform_to_iso3(shape_pos),
      shape,
    )
  let out : Array[@core.Entity] = []
  for h in hs {
    if entity_from_collider_handle(self, h) is Some(e) {
      out.push(e)
    }
  }
  out
}

///|
pub fn Physics3dContext::cast_shape_entity(
  self : Physics3dContext,
  shape_pos : @transform.Transform,
  shape_vel : @math.Vec3,
  shape : @collision.Shape3D,
  options : @collision.ShapeCastOptions3,
) -> ShapeCastHit3d? {
  self.cast_shape_entity_with_filter(
    shape_pos,
    shape_vel,
    shape,
    options,
    @collision.QueryFilter3DReal::new(),
  )
}

///|
pub fn Physics3dContext::cast_shape_entity_with_filter(
  self : Physics3dContext,
  shape_pos : @transform.Transform,
  shape_vel : @math.Vec3,
  shape : @collision.Shape3D,
  options : @collision.ShapeCastOptions3,
  filter : @collision.QueryFilter3DReal,
) -> ShapeCastHit3d? {
  match
    self
    .query()
    .with_filter(filter)
    .cast_shape(
      self.rigid_bodies,
      self.colliders,
      mg_transform_to_iso3(shape_pos),
      mg_vec3_to_rapier(shape_vel),
      shape,
      options,
    ) {
    Some((h, hit)) =>
      match entity_from_collider_handle(self, h) {
        Some(e) =>
          Some(ShapeCastHit3d::{
            entity: e,
            toi: hit.toi(),
            point: rapier_vec3_to_mg(hit.point()),
            normal: rapier_vec3_to_mg(hit.normal()),
          })
        None => None
      }
    None => None
  }
}
