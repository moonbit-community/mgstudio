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
/// High-level query helpers (Bevy-like) built on top of Rapier's QueryPipeline.

///|
pub struct RayHit2d {
  entity : @core.Entity
  toi : Float
}

///|
pub struct RayHitNormal2d {
  entity : @core.Entity
  toi : Float
  normal : @math.Vec2
}

///|
pub struct PointProjection2d {
  entity : @core.Entity
  point : @math.Vec2
  is_inside : Bool
}

///|
pub struct PointProjectionFeature2d {
  entity : @core.Entity
  point : @math.Vec2
  is_inside : Bool
  feature : @collision.FeatureId
}

///|
pub struct ShapeCastHit2d {
  entity : @core.Entity
  toi : Float
  point : @math.Vec2
  normal : @math.Vec2
}

///|
fn entity_from_collider_handle(
  ctx : Physics2dContext,
  h : @collision.ColliderHandle,
) -> @core.Entity? {
  ctx.collider_to_entity.get(h.into_raw_parts())
}

///|
pub fn Physics2dContext::rigid_body_handle_of(
  self : Physics2dContext,
  entity : @core.Entity,
) -> @dynamics.RigidBodyHandle? {
  self.entity_to_body.get(entity_key(entity))
}

///|
pub fn Physics2dContext::collider_handle_of(
  self : Physics2dContext,
  entity : @core.Entity,
) -> @collision.ColliderHandle? {
  self.entity_to_collider.get(entity_key(entity))
}

///|
pub fn Physics2dContext::query_filter_exclude_entity(
  self : Physics2dContext,
  filter : @collision.QueryFilter,
  entity : @core.Entity,
) -> @collision.QueryFilter {
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

///|
fn rect_to_aabb(rect : @math.Rect) -> @rapier_core.Aabb {
  @rapier_core.Aabb::new(
    mg_vec2_to_rapier(rect.min),
    mg_vec2_to_rapier(rect.max),
  )
}

///|
pub fn Physics2dContext::cast_ray_entity(
  self : Physics2dContext,
  origin : @math.Vec2,
  dir : @math.Vec2,
  max_toi : Float,
  solid : Bool,
) -> RayHit2d? {
  let ray = @collision.Ray::new(
    mg_vec2_to_rapier(origin),
    mg_vec2_to_rapier(dir),
  )
  let bodies = self.rigid_bodies
  let colliders = self.colliders
  match self.query().cast_ray(bodies, colliders, ray, max_toi, solid) {
    Some((h, toi)) =>
      match entity_from_collider_handle(self, h) {
        Some(e) => Some(RayHit2d::{ entity: e, toi })
        None => None
      }
    None => None
  }
}

///|
pub fn Physics2dContext::cast_ray_entity_with_filter(
  self : Physics2dContext,
  origin : @math.Vec2,
  dir : @math.Vec2,
  max_toi : Float,
  solid : Bool,
  filter : @collision.QueryFilter,
) -> RayHit2d? {
  let ray = @collision.Ray::new(
    mg_vec2_to_rapier(origin),
    mg_vec2_to_rapier(dir),
  )
  let bodies = self.rigid_bodies
  let colliders = self.colliders
  match
    self
    .query()
    .with_filter(filter)
    .cast_ray(bodies, colliders, ray, max_toi, solid) {
    Some((h, toi)) =>
      match entity_from_collider_handle(self, h) {
        Some(e) => Some(RayHit2d::{ entity: e, toi })
        None => None
      }
    None => None
  }
}

///|
pub fn Physics2dContext::cast_ray_and_get_normal_entity(
  self : Physics2dContext,
  origin : @math.Vec2,
  dir : @math.Vec2,
  max_toi : Float,
  solid : Bool,
) -> RayHitNormal2d? {
  let ray = @collision.Ray::new(
    mg_vec2_to_rapier(origin),
    mg_vec2_to_rapier(dir),
  )
  let bodies = self.rigid_bodies
  let colliders = self.colliders
  match
    self.query().cast_ray_and_get_normal(bodies, colliders, ray, max_toi, solid) {
    Some((h, inter)) =>
      match entity_from_collider_handle(self, h) {
        Some(e) =>
          Some(RayHitNormal2d::{
            entity: e,
            toi: inter.toi(),
            normal: rapier_vec2_to_mg(inter.normal()),
          })
        None => None
      }
    None => None
  }
}

///|
pub fn Physics2dContext::cast_ray_and_get_normal_entity_with_filter(
  self : Physics2dContext,
  origin : @math.Vec2,
  dir : @math.Vec2,
  max_toi : Float,
  solid : Bool,
  filter : @collision.QueryFilter,
) -> RayHitNormal2d? {
  let ray = @collision.Ray::new(
    mg_vec2_to_rapier(origin),
    mg_vec2_to_rapier(dir),
  )
  let bodies = self.rigid_bodies
  let colliders = self.colliders
  match
    self
    .query()
    .with_filter(filter)
    .cast_ray_and_get_normal(bodies, colliders, ray, max_toi, solid) {
    Some((h, inter)) =>
      match entity_from_collider_handle(self, h) {
        Some(e) =>
          Some(RayHitNormal2d::{
            entity: e,
            toi: inter.toi(),
            normal: rapier_vec2_to_mg(inter.normal()),
          })
        None => None
      }
    None => None
  }
}

///|
pub fn Physics2dContext::intersect_ray_entities_with_filter(
  self : Physics2dContext,
  origin : @math.Vec2,
  dir : @math.Vec2,
  max_toi : Float,
  solid : Bool,
  filter : @collision.QueryFilter,
) -> Array[RayHitNormal2d] {
  let ray = @collision.Ray::new(
    mg_vec2_to_rapier(origin),
    mg_vec2_to_rapier(dir),
  )
  let bodies = self.rigid_bodies
  let colliders = self.colliders
  let hits = self
    .query()
    .with_filter(filter)
    .intersect_ray(bodies, colliders, ray, max_toi, solid)
  let out : Array[RayHitNormal2d] = []
  for pair in hits {
    let (h, inter) = pair
    if entity_from_collider_handle(self, h) is Some(e) {
      out.push(RayHitNormal2d::{
        entity: e,
        toi: inter.toi(),
        normal: rapier_vec2_to_mg(inter.normal()),
      })
    }
  }
  out
}

///|
pub fn Physics2dContext::intersect_ray_entities(
  self : Physics2dContext,
  origin : @math.Vec2,
  dir : @math.Vec2,
  max_toi : Float,
  solid : Bool,
) -> Array[RayHitNormal2d] {
  self.intersect_ray_entities_with_filter(
    origin,
    dir,
    max_toi,
    solid,
    @collision.QueryFilter::new(),
  )
}

///|
pub fn Physics2dContext::intersect_point_entities(
  self : Physics2dContext,
  point : @math.Vec2,
) -> Array[@core.Entity] {
  let bodies = self.rigid_bodies
  let colliders = self.colliders
  let hs = self
    .query()
    .intersect_point(bodies, colliders, mg_vec2_to_rapier(point))
  let out : Array[@core.Entity] = []
  for h in hs {
    if entity_from_collider_handle(self, h) is Some(e) {
      out.push(e)
    }
  }
  out
}

///|
pub fn Physics2dContext::intersect_point_entities_with_filter(
  self : Physics2dContext,
  point : @math.Vec2,
  filter : @collision.QueryFilter,
) -> Array[@core.Entity] {
  let bodies = self.rigid_bodies
  let colliders = self.colliders
  let hs = self
    .query()
    .with_filter(filter)
    .intersect_point(bodies, colliders, mg_vec2_to_rapier(point))
  let out : Array[@core.Entity] = []
  for h in hs {
    if entity_from_collider_handle(self, h) is Some(e) {
      out.push(e)
    }
  }
  out
}

///|
pub fn Physics2dContext::project_point_entity(
  self : Physics2dContext,
  point : @math.Vec2,
  max_dist : Float,
  solid : Bool,
) -> PointProjection2d? {
  let bodies = self.rigid_bodies
  let colliders = self.colliders
  match
    self
    .query()
    .project_point(bodies, colliders, mg_vec2_to_rapier(point), max_dist, solid) {
    Some((h, proj)) =>
      match entity_from_collider_handle(self, h) {
        Some(e) =>
          Some(PointProjection2d::{
            entity: e,
            point: rapier_vec2_to_mg(proj.point()),
            is_inside: proj.is_inside(),
          })
        None => None
      }
    None => None
  }
}

///|
pub fn Physics2dContext::project_point_entity_with_filter(
  self : Physics2dContext,
  point : @math.Vec2,
  max_dist : Float,
  solid : Bool,
  filter : @collision.QueryFilter,
) -> PointProjection2d? {
  let bodies = self.rigid_bodies
  let colliders = self.colliders
  match
    self
    .query()
    .with_filter(filter)
    .project_point(bodies, colliders, mg_vec2_to_rapier(point), max_dist, solid) {
    Some((h, proj)) =>
      match entity_from_collider_handle(self, h) {
        Some(e) =>
          Some(PointProjection2d::{
            entity: e,
            point: rapier_vec2_to_mg(proj.point()),
            is_inside: proj.is_inside(),
          })
        None => None
      }
    None => None
  }
}

///|
pub fn Physics2dContext::project_point_and_get_feature_entity(
  self : Physics2dContext,
  point : @math.Vec2,
  max_dist : Float,
  solid : Bool,
) -> PointProjectionFeature2d? {
  let bodies = self.rigid_bodies
  let colliders = self.colliders
  match
    self
    .query()
    .project_point_and_get_feature(
      bodies,
      colliders,
      mg_vec2_to_rapier(point),
      max_dist,
      solid,
    ) {
    Some((h, proj, feature)) =>
      match entity_from_collider_handle(self, h) {
        Some(e) =>
          Some(PointProjectionFeature2d::{
            entity: e,
            point: rapier_vec2_to_mg(proj.point()),
            is_inside: proj.is_inside(),
            feature,
          })
        None => None
      }
    None => None
  }
}

///|
pub fn Physics2dContext::project_point_and_get_feature_entity_with_filter(
  self : Physics2dContext,
  point : @math.Vec2,
  max_dist : Float,
  solid : Bool,
  filter : @collision.QueryFilter,
) -> PointProjectionFeature2d? {
  let bodies = self.rigid_bodies
  let colliders = self.colliders
  match
    self
    .query()
    .with_filter(filter)
    .project_point_and_get_feature(
      bodies,
      colliders,
      mg_vec2_to_rapier(point),
      max_dist,
      solid,
    ) {
    Some((h, proj, feature)) =>
      match entity_from_collider_handle(self, h) {
        Some(e) =>
          Some(PointProjectionFeature2d::{
            entity: e,
            point: rapier_vec2_to_mg(proj.point()),
            is_inside: proj.is_inside(),
            feature,
          })
        None => None
      }
    None => None
  }
}

///|
pub fn Physics2dContext::intersect_shape_entities(
  self : Physics2dContext,
  shape : ColliderShape2d,
  shape_pos : @math.Transform,
) -> Array[@core.Entity] {
  self.intersect_shape_entities_with_filter(
    shape,
    shape_pos,
    @collision.QueryFilter::new(),
  )
}

///|
pub fn Physics2dContext::intersect_shape_entities_with_filter(
  self : Physics2dContext,
  shape : ColliderShape2d,
  shape_pos : @math.Transform,
  filter : @collision.QueryFilter,
) -> Array[@core.Entity] {
  let bodies = self.rigid_bodies
  let colliders = self.colliders
  let scale = mg_transform_scale2d_abs(shape_pos)
  let hs = self
    .query()
    .with_filter(filter)
    .intersect_shape(
      bodies,
      colliders,
      mg_transform_to_iso2(shape_pos),
      collider_shape2d_to_rapier_scaled(shape, scale),
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
pub fn Physics2dContext::intersect_aabb_entities_conservative(
  self : Physics2dContext,
  rect : @math.Rect,
) -> Array[@core.Entity] {
  self.intersect_aabb_entities_conservative_with_filter(
    rect,
    @collision.QueryFilter::new(),
  )
}

///|
pub fn Physics2dContext::intersect_aabb_entities_conservative_with_filter(
  self : Physics2dContext,
  rect : @math.Rect,
  filter : @collision.QueryFilter,
) -> Array[@core.Entity] {
  let bodies = self.rigid_bodies
  let colliders = self.colliders
  let hs = self
    .query()
    .with_filter(filter)
    .intersect_aabb_conservative(bodies, colliders, rect_to_aabb(rect))
  let out : Array[@core.Entity] = []
  for h in hs {
    if entity_from_collider_handle(self, h) is Some(e) {
      out.push(e)
    }
  }
  out
}

///|
pub fn Physics2dContext::cast_shape_entity(
  self : Physics2dContext,
  shape : ColliderShape2d,
  shape_pos : @math.Transform,
  shape_vel : @math.Vec2,
  options : @collision.ShapeCastOptions,
) -> ShapeCastHit2d? {
  let query = self.query()
  let bodies = self.rigid_bodies
  let colliders = self.colliders
  let scale = mg_transform_scale2d_abs(shape_pos)
  match
    query.cast_shape(
      bodies,
      colliders,
      mg_transform_to_iso2(shape_pos),
      mg_vec2_to_rapier(shape_vel),
      collider_shape2d_to_rapier_scaled(shape, scale),
      options,
    ) {
    Some((h, hit)) =>
      match entity_from_collider_handle(self, h) {
        Some(e) =>
          Some(ShapeCastHit2d::{
            entity: e,
            toi: hit.toi(),
            point: rapier_vec2_to_mg(hit.point()),
            normal: rapier_vec2_to_mg(hit.normal()),
          })
        None => None
      }
    None => None
  }
}

///|
pub fn Physics2dContext::cast_shape_entity_with_filter(
  self : Physics2dContext,
  shape : ColliderShape2d,
  shape_pos : @math.Transform,
  shape_vel : @math.Vec2,
  options : @collision.ShapeCastOptions,
  filter : @collision.QueryFilter,
) -> ShapeCastHit2d? {
  let query = self.query().with_filter(filter)
  let bodies = self.rigid_bodies
  let colliders = self.colliders
  let scale = mg_transform_scale2d_abs(shape_pos)
  match
    query.cast_shape(
      bodies,
      colliders,
      mg_transform_to_iso2(shape_pos),
      mg_vec2_to_rapier(shape_vel),
      collider_shape2d_to_rapier_scaled(shape, scale),
      options,
    ) {
    Some((h, hit)) =>
      match entity_from_collider_handle(self, h) {
        Some(e) =>
          Some(ShapeCastHit2d::{
            entity: e,
            toi: hit.toi(),
            point: rapier_vec2_to_mg(hit.point()),
            normal: rapier_vec2_to_mg(hit.normal()),
          })
        None => None
      }
    None => None
  }
}
