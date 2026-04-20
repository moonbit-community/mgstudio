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
// Bevy source: `bevy/crates/bevy_transform/src/helper.rs`.

///|
pub struct TransformHelper {}

///|
pub fn TransformHelper::default() -> TransformHelper {
  TransformHelper::{  }
}

///|
pub fn TransformHelper::compute_global_transform(
  _self : TransformHelper,
  world : @ecs.World,
  entity : @core.Entity,
) -> GlobalTransform? {
  compute_global_transform(world, entity)
}

///|
pub fn compute_global_transform(
  world : @ecs.World,
  entity : @core.Entity,
) -> GlobalTransform? {
  if !world.is_alive(entity) {
    return None
  }
  let local_transform = match
    (try! world.get_by_key(entity, ecs_key_transform)) {
    Some(transform) => transform
    None => return None
  }
  let mut global = GlobalTransform::from_transform(local_transform)
  let mut current = entity
  while true {
    guard (try! world.get_by_key(current, @hierarchy.ecs_key_parent))
      is Some(parent) else {
      break
    }
    current = parent.entity()
    if !world.is_alive(current) {
      return None
    }
    guard (try! world.get_by_key(current, ecs_key_transform))
      is Some(parent_local) else {
      return None
    }
    global = GlobalTransform::from_transform(parent_local).mul(global)
  }
  Some(global)
}

///|
pub fn compute_parent_global_transform(
  world : @ecs.World,
  entity : @core.Entity,
) -> GlobalTransform? {
  if !world.is_alive(entity) {
    return None
  }
  guard (try! world.get_by_key(entity, @hierarchy.ecs_key_parent))
    is Some(parent) else {
    return None
  }
  compute_global_transform(world, parent.entity())
}
