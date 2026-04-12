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
pub impl ToJson for SceneRoot with to_json(self) {
  self.scene.id().to_json()
}

///|
pub impl @json.FromJson for SceneRoot with from_json(json, path) {
  let scene_id : Int = @json.from_json(json, path~)
  SceneRoot::new(@asset.Handle::new(scene_id))
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
pub impl ToJson for SceneInstance with to_json(self) {
  self.instance_id.to_json()
}

///|
pub impl @json.FromJson for SceneInstance with from_json(json, path) {
  let instance_id : Int = @json.from_json(json, path~)
  SceneInstance::new(instance_id)
}

///|
pub struct SceneInstanceReady {
  instance_id : Int
  spawned_entities : Int
}

///|
pub fn SceneInstanceReady::new(
  instance_id : Int,
  spawned_entities : Int,
) -> SceneInstanceReady {
  SceneInstanceReady::{ instance_id, spawned_entities }
}

///|
pub impl ToJson for SceneInstanceReady with to_json(self) {
  (self.instance_id, self.spawned_entities).to_json()
}

///|
pub impl @json.FromJson for SceneInstanceReady with from_json(json, path) {
  let pair : (Int, Int)? = Some(@json.from_json(json, path~)) catch {
    _ => None
  }
  match pair {
    Some((instance_id, spawned_entities)) =>
      SceneInstanceReady::new(instance_id, spawned_entities)
    None => {
      let spawned_entities : Int = @json.from_json(json, path~)
      SceneInstanceReady::new(0, spawned_entities)
    }
  }
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
  try! world.contains_by_key(entity, ecs_key_scene_instance_ready)
}

///|
pub fn scene_components_scene_root_count(world : @ecs.World) -> Int {
  world.component_count(ecs_key_scene_root)
}
