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
/// Transform + hierarchy utilities inspired by Bevy's `bevy_transform`.
///
/// This package provides:
/// - Parent/Children relationships for transform nodes
/// - Global transform propagation (parent global * local)
///
/// Note: the current engine uses a lightweight handle-based scene graph rather
/// than a full ECS. We model "entities" here as `TransformId` and expose a
/// deterministic propagation pass that can be scheduled each frame.
///

///|

///|
pub struct TransformId {
  id : Int
} derive(Eq, Show)

///|
pub struct Parent {
  entity : TransformId
}

///|
pub struct Children {
  entities : Array[TransformId]
}

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
pub struct GlobalTransform {
  affine : Affine2
}

///|
pub fn GlobalTransform::identity() -> GlobalTransform {
  GlobalTransform::{ affine: Affine2::identity() }
}

///|
pub fn GlobalTransform::from_transform(
  transform : @math.Transform,
) -> GlobalTransform {
  let cosv = @math.cos(transform.rotation)
  let sinv = @math.sin(transform.rotation)
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
  }
}

///|
pub fn GlobalTransform::mul(
  self : GlobalTransform,
  other : GlobalTransform,
) -> GlobalTransform {
  GlobalTransform::{ affine: self.affine.mul(other.affine) }
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
  @math.Transform::new(
    @math.Vec2::new(self.affine.tx, self.affine.ty),
    rotation,
    @math.Vec2::new(scale_x, scale_y),
  )
}

///|
priv struct Node {
  mut local_transform : @math.Transform
  mut global : GlobalTransform
  mut global_updated_tick : Int
  mut parent : Int?
  children : Array[Int]
  mut changed : Bool
}

///|
priv struct Store {
  nodes : Array[Node]
  mut tick : Int
}

///|
let store : Ref[Store] = Ref::new(Store::{ nodes: [], tick: 0 })

///|
pub fn reset() -> Unit {
  store.val.nodes.clear()
  store.val.tick = 0
}

///|
pub fn spawn(local_transform : @math.Transform) -> TransformId {
  let id = store.val.nodes.length()
  store.val.nodes.push(Node::{
    local_transform,
    global: GlobalTransform::identity(),
    global_updated_tick: 0,
    parent: None,
    children: [],
    changed: true,
  })
  TransformId::{ id, }
}

///|
pub fn set_local(
  entity : TransformId,
  local_transform : @math.Transform,
) -> Unit {
  let id = entity.id
  if id < 0 || id >= store.val.nodes.length() {
    return
  }
  store.val.nodes[id].local_transform = local_transform
  store.val.nodes[id].changed = true
}

///|
pub fn set_local_transform(
  entity : TransformId,
  local_transform : @math.Transform,
) -> Unit {
  set_local(entity, local_transform)
}

///|
pub fn local_transform(entity : TransformId) -> @math.Transform? {
  let id = entity.id
  if id < 0 || id >= store.val.nodes.length() {
    None
  } else {
    Some(store.val.nodes[id].local_transform)
  }
}

///|
pub fn global(entity : TransformId) -> GlobalTransform? {
  let id = entity.id
  if id < 0 || id >= store.val.nodes.length() {
    None
  } else {
    Some(store.val.nodes[id].global)
  }
}

///|
pub fn world_transform(entity : TransformId) -> @math.Transform? {
  global(entity).map(fn(gt) { gt.to_transform_approx() })
}

///|
pub fn propagate_tick() -> Int {
  store.val.tick
}

///|
pub fn global_updated_tick(entity : TransformId) -> Int? {
  let id = entity.id
  if id < 0 || id >= store.val.nodes.length() {
    None
  } else {
    Some(store.val.nodes[id].global_updated_tick)
  }
}

///|
pub fn parent(entity : TransformId) -> TransformId? {
  let id = entity.id
  if id < 0 || id >= store.val.nodes.length() {
    return None
  }
  match store.val.nodes[id].parent {
    Some(pid) => Some(TransformId::{ id: pid })
    None => None
  }
}

///|
pub fn parent_component(entity : TransformId) -> Parent? {
  parent(entity).map(fn(p) { Parent::{ entity: p } })
}

///|
pub fn children_component(entity : TransformId) -> Children {
  Children::{ entities: children(entity) }
}

///|
pub fn children(entity : TransformId) -> Array[TransformId] {
  let id = entity.id
  if id < 0 || id >= store.val.nodes.length() {
    return []
  }
  let out : Array[TransformId] = []
  for child_id in store.val.nodes[id].children {
    out.push(TransformId::{ id: child_id })
  }
  out
}

///|
fn is_ancestor(candidate : Int, target : Int) -> Bool {
  let mut current = candidate
  while true {
    if current == target {
      return true
    }
    let next = store.val.nodes[current].parent
    if next is Some(pid) {
      current = pid
      continue
    } else {
      return false
    }
  }
  false
}

///|
fn remove_child(parent_id : Int, child_id : Int) -> Unit {
  let list = store.val.nodes[parent_id].children
  let mut i = 0
  let len = list.length()
  while i < len {
    if list[i] == child_id {
      // Remove by swap-with-last to keep this O(1).
      let last_index = list.length() - 1
      list[i] = list[last_index]
      list.pop() |> ignore
      return
    }
    i = i + 1
  }
}

///|
pub fn set_parent(entity : TransformId, parent_opt : TransformId?) -> Unit {
  let id = entity.id
  if id < 0 || id >= store.val.nodes.length() {
    return
  }
  let new_parent_id : Int? = parent_opt.map(fn(p) { p.id })
  if new_parent_id is Some(pid) {
    if pid < 0 || pid >= store.val.nodes.length() {
      return
    }
    if pid == id {
      return
    }
    // Prevent cycles: new parent cannot be a descendant of the entity.
    if is_ancestor(pid, id) {
      return
    }
  }
  // Detach from old parent if any.
  if store.val.nodes[id].parent is Some(old_parent) {
    remove_child(old_parent, id)
  }
  // Attach to new parent.
  if new_parent_id is Some(pid) {
    store.val.nodes[pid].children.push(id)
    store.val.nodes[id].parent = Some(pid)
  } else {
    store.val.nodes[id].parent = None
  }
  store.val.nodes[id].changed = true
}

///|
pub fn propagate() -> Unit {
  let count = store.val.nodes.length()
  if count == 0 {
    return
  }
  store.val.tick = store.val.tick + 1
  let tick = store.val.tick
  let stack : Array[(Int, GlobalTransform, Bool)] = []
  for id in 0..<count {
    if store.val.nodes[id].parent is None {
      stack.push((id, GlobalTransform::identity(), false))
    }
  }
  while stack.length() > 0 {
    let (id, parent_global, parent_changed) = stack.pop().unwrap()
    let local_gt = GlobalTransform::from_transform(
      store.val.nodes[id].local_transform,
    )
    let should_update = parent_changed || store.val.nodes[id].changed
    if should_update {
      store.val.nodes[id].global = parent_global.mul(local_gt)
      store.val.nodes[id].changed = false
      store.val.nodes[id].global_updated_tick = tick
    }
    let changed = should_update
    let global_value = store.val.nodes[id].global
    for child_id in store.val.nodes[id].children {
      stack.push((child_id, global_value, changed))
    }
  }
}

///|
fn[W] transform_propagate_system(_world : W) -> Unit {
  propagate()
}

///|
pub fn[W] transform_plugin(app : @app.App[W]) -> @app.App[W] {
  // Run propagation every frame.
  app.add_system(transform_propagate_system)
}
