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
// Bevy source: `bevy/crates/bevy_scene/src/components.rs`.

///|
pub struct SceneRoot {
  scene : @asset.Handle[Scene]
}

///|
pub fn SceneRoot::new(scene : @asset.Handle[Scene]) -> SceneRoot {
  SceneRoot::{ scene, }
}

///|
pub struct SceneInstance {
  instance_id : Int
}

///|
pub fn SceneInstance::new(instance_id : Int) -> SceneInstance {
  SceneInstance::{ instance_id, }
}

///|
pub struct SceneInstanceReady {
  entity : @core.Entity?
  instance_id : Int
}

///|
pub fn SceneInstanceReady::new(
  entity : @core.Entity?,
  instance_id : Int,
) -> SceneInstanceReady {
  SceneInstanceReady::{ entity, instance_id }
}

///|
pub fn scene_components_has_scene_root(
  world : @ecs.World,
  entity : @core.Entity,
) -> Bool {
  try! world.contains_by_key(entity, ecs_key_scene_root)
}

///|
pub fn scene_components_has_scene_instance(
  world : @ecs.World,
  entity : @core.Entity,
) -> Bool {
  try! world.contains_by_key(entity, ecs_key_scene_instance)
}

///|
pub fn scene_components_has_scene_instance_ready(
  world : @ecs.World,
  entity : @core.Entity,
) -> Bool {
  guard scene_instance_component(world, entity) is Some(instance) else {
    return false
  }
  scene_instance_is_ready(world, instance.instance_id)
}

///|
pub fn scene_components_scene_root_count(world : @ecs.World) -> Int {
  world.component_count(ecs_key_scene_root)
}
