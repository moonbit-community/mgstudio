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
fn entity_from_collider_handle(
  ctx : Physics2dContext,
  h : @collision.ColliderHandle,
) -> @core.Entity? {
  ctx.collider_to_entity.get(h.into_raw_parts())
}

///|
pub fn Physics2dContext::cast_ray_entity(
  self : Physics2dContext,
  origin : @math.Vec2,
  dir : @math.Vec2,
  max_toi : Float,
  solid : Bool,
) -> RayHit2d? {
  let ray = @collision.Ray::new(mg_vec2_to_rapier(origin), mg_vec2_to_rapier(dir))
  match self.query().cast_ray(ray, max_toi, solid) {
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
  let ray = @collision.Ray::new(mg_vec2_to_rapier(origin), mg_vec2_to_rapier(dir))
  match self.query().cast_ray_and_get_normal(ray, max_toi, solid) {
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
pub fn Physics2dContext::intersect_point_entities(
  self : Physics2dContext,
  point : @math.Vec2,
) -> Array[@core.Entity] {
  let hs = self.query().intersect_point(mg_vec2_to_rapier(point))
  let out : Array[@core.Entity] = []
  for h in hs {
    if entity_from_collider_handle(self, h) is Some(e) {
      out.push(e)
    }
  }
  out
}

