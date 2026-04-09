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
// Bevy source-shape anchor (`bevy_transform/src/commands.rs`).

///|
pub fn set_parent_in_place(
  world : @ecs.World,
  child : @core.Entity,
  parent : @core.Entity,
) -> Unit raise @ecs.EcsError {
  ignore(try! world.entity(child))
  ignore(try! world.entity(parent))
  let child_global = try! compute_global_transform(world, child)
  let parent_global = try! compute_global_transform(world, parent)
  if child_global is Some(child_global) && parent_global is Some(parent_global) {
    let next_local = child_global
      .reparented_to(parent_global)
      .compute_transform()
    if (try! world.contains_by_key(child, ecs_key_transform)) {
      try! (world.replace(child, ecs_key_transform, next_local) |> ignore)
    } else {
      try! world.set_by_key(child, ecs_key_transform, next_local)
    }
  }
  try! world.set_by_key(
    child,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(parent),
  )
}

///|
pub fn remove_parent_in_place(
  world : @ecs.World,
  child : @core.Entity,
) -> Unit raise @ecs.EcsError {
  ignore(try! world.entity(child))
  guard (try! compute_global_transform(world, child)) is Some(global) else {
    if (try! world.contains_by_key(child, @hierarchy.ecs_key_parent)) {
      try! (world.remove_by_key(child, @hierarchy.ecs_key_parent) |> ignore)
    }
    return
  }
  let next_local = global.compute_transform()
  if (try! world.contains_by_key(child, ecs_key_transform)) {
    try! (world.replace(child, ecs_key_transform, next_local) |> ignore)
  } else {
    try! world.set_by_key(child, ecs_key_transform, next_local)
  }
  if (try! world.contains_by_key(child, @hierarchy.ecs_key_parent)) {
    try! (world.remove_by_key(child, @hierarchy.ecs_key_parent) |> ignore)
  }
}
