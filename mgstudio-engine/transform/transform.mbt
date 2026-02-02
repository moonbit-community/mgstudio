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
/// Bevy-like transform propagation (2D-first).
///
/// This package provides:
/// - `GlobalTransform` component (computed world-space transform)
/// - systems to maintain `Children` from `Parent` and propagate transforms

///|
pub struct Affine2 {
  a : Float
  b : Float
  c : Float
  d : Float
  tx : Float
  ty : Float
}

///|
pub fn Affine2::identity() -> Affine2 {
  Affine2::{ a: 1.0F, b: 0.0F, c: 0.0F, d: 1.0F, tx: 0.0F, ty: 0.0F }
}

///|
pub fn Affine2::mul(self : Affine2, other : Affine2) -> Affine2 {
  // (A, t) * (B, u) = (A*B, A*u + t)
  let a = self.a * other.a + self.c * other.b
  let b = self.b * other.a + self.d * other.b
  let c = self.a * other.c + self.c * other.d
  let d = self.b * other.c + self.d * other.d
  let tx = self.a * other.tx + self.c * other.ty + self.tx
  let ty = self.b * other.tx + self.d * other.ty + self.ty
  Affine2::{ a, b, c, d, tx, ty }
}

///|
pub fn Affine2::transform_point2(
  self : Affine2,
  point : @math.Vec2,
) -> @math.Vec2 {
  @math.Vec2::new(
    self.a * point.x + self.c * point.y + self.tx,
    self.b * point.x + self.d * point.y + self.ty,
  )
}

///|
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub struct GlobalTransform {
  affine : Affine2
  z : Float
}

///|
pub fn GlobalTransform::identity() -> GlobalTransform {
  GlobalTransform::{ affine: Affine2::identity(), z: 0.0F }
}

///|
pub fn GlobalTransform::from_transform(
  transform : @math.Transform,
) -> GlobalTransform {
  let rot_z = transform.rotation_z()
  let cosv = @math.cos(rot_z)
  let sinv = @math.sin(rot_z)
  let sx = transform.scale.x
  let sy = transform.scale.y
  let a = cosv * sx
  let b = sinv * sx
  let c = -sinv * sy
  let d = cosv * sy
  GlobalTransform::{
    affine: Affine2::{
      a,
      b,
      c,
      d,
      tx: transform.translation.x,
      ty: transform.translation.y,
    },
    z: transform.translation.z,
  }
}

///|
pub fn GlobalTransform::mul(
  self : GlobalTransform,
  other : GlobalTransform,
) -> GlobalTransform {
  GlobalTransform::{
    affine: self.affine.mul(other.affine),
    z: self.z + other.z,
  }
}

///|
pub fn GlobalTransform::to_transform_approx(
  self : GlobalTransform,
) -> @math.Transform {
  // Best-effort TRS decomposition for a 2D affine matrix.
  // This ignores shear in the returned Transform, but preserves translation.
  let a = self.affine.a
  let b = self.affine.b
  let c = self.affine.c
  let d = self.affine.d
  let scale_x = @math.sqrt(a * a + b * b)
  let rotation = if scale_x == 0.0F { 0.0F } else { @math.atan2(b, a) }
  let det = a * d - b * c
  let scale_y = if scale_x == 0.0F { 0.0F } else { det / scale_x }
  @math.Transform::from_xy_rotation_scale(
    @math.Vec2::new(self.affine.tx, self.affine.ty),
    rotation,
    @math.Vec2::new(scale_x, scale_y),
    z=self.z,
  )
}

///|
fn sort_by_parent_id(pairs : Array[(@core.Entity, @core.Entity)]) -> Unit {
  let mut i = 1
  while i < pairs.length() {
    let cur = pairs[i]
    let cur_key = cur.0.id
    let mut j = i
    while j > 0 && pairs[j - 1].0.id > cur_key {
      pairs[j] = pairs[j - 1]
      j = j - 1
    }
    pairs[j] = cur
    i = i + 1
  }
}

///|
pub fn[
  W : @hierarchy.Has_Parent + @hierarchy.Has_Children + @core.ChangeTickWorld,
] update_children_system(
  world : W,
) -> Unit {
  let parent_store = @hierarchy.Has_Parent::get_parent_store(world)
  let children_store = @hierarchy.Has_Children::get_children_store(world)
  let change_tick = @core.ChangeTickWorld::read_change_tick(world)

  // Rebuild from scratch (simple, correct); later we can make this incremental.
  let existing : Array[@core.Entity] = []
  children_store.for_each(fn(e, _children) { existing.push(e) })
  for e in existing {
    children_store.remove(e) |> ignore
  }
  let pairs : Array[(@core.Entity, @core.Entity)] = []
  parent_store.for_each(fn(child, parent) { pairs.push((parent.entity, child)) })
  if pairs.length() == 0 {
    return
  }
  sort_by_parent_id(pairs)
  let mut i = 0
  while i < pairs.length() {
    let parent = pairs[i].0
    let children : Array[@core.Entity] = []
    while i < pairs.length() && pairs[i].0.id == parent.id {
      children.push(pairs[i].1)
      i = i + 1
    }
    children_store.insert(
      parent,
      @hierarchy.Children::new(children),
      change_tick,
    )
  }
}

///|
pub fn[
  W : @math.Has_Transform + Has_GlobalTransform + @hierarchy.Has_Parent + @hierarchy.Has_Children + @core.ChangeTickWorld + @core.SystemContextWorld,
] propagate_transforms_system(
  world : W,
) -> Unit {
  let transform_store = @math.Has_Transform::get_transform_store(world)
  let global_store = Has_GlobalTransform::get_global_transform_store(world)
  let parent_store = @hierarchy.Has_Parent::get_parent_store(world)
  let children_store = @hierarchy.Has_Children::get_children_store(world)
  let change_tick = @core.ChangeTickWorld::read_change_tick(world)
  let system_ticks = @core.SystemContextWorld::get_system_context(world).ticks()
  let stack : Array[(@core.Entity, GlobalTransform, Bool)] = []
  transform_store.for_each(fn(e, _t) {
    if !parent_store.contains(e) {
      stack.push((e, GlobalTransform::identity(), false))
    }
  })
  while stack.length() > 0 {
    let (entity, parent_global, parent_changed) = stack.pop().unwrap()
    guard transform_store.get(entity) is Some(local_transform) else { continue }
    let local_gt = GlobalTransform::from_transform(local_transform)
    let local_ticks = transform_store.get_ticks(entity).unwrap()
    let local_changed = local_ticks.is_added(system_ticks) ||
      local_ticks.is_changed(system_ticks)
    let should_update = parent_changed ||
      local_changed ||
      !global_store.contains(entity)
    let global = parent_global.mul(local_gt)
    if should_update {
      if global_store.contains(entity) {
        global_store.set(entity, global, change_tick) |> ignore
      } else {
        global_store.insert(entity, global, change_tick)
      }
    }
    let changed = should_update
    if children_store.get(entity) is Some(children) {
      for child in children.entities {
        stack.push((child, global, changed))
      }
    }
  }
}

///|
pub fn[
  W : @math.Has_Transform + Has_GlobalTransform + @hierarchy.Has_Parent + @hierarchy.Has_Children + @core.ChangeTickWorld + @core.SystemContextWorld,
] transform_plugin(
  app : @app.App[W],
) -> @app.App[W] {
  // Keep `Children` in sync with `Parent`, then compute `GlobalTransform`.
  app
  .add_pre_update_system(update_children_system)
  .add_pre_update_system(propagate_transforms_system)
}
