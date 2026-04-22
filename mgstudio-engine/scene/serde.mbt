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
// Bevy source: `bevy/crates/bevy_scene/src/serde.rs`.

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
pub impl ToJson for SceneInstance with to_json(self) {
  self.instance_id.to_json()
}

///|
pub impl @json.FromJson for SceneInstance with from_json(json, path) {
  let instance_id : Int = @json.from_json(json, path~)
  SceneInstance::new(instance_id)
}

///|
pub impl ToJson for SceneInstanceReady with to_json(self) {
  (self.entity, self.instance_id).to_json()
}

///|
pub impl @json.FromJson for SceneInstanceReady with from_json(json, path) {
  let pair : (@core.Entity?, Int)? = Some(@json.from_json(json, path~)) catch {
    _ => None
  }
  match pair {
    Some((entity, instance_id)) => SceneInstanceReady::new(entity, instance_id)
    None => {
      let instance_id : Int = @json.from_json(json, path~)
      SceneInstanceReady::new(None, instance_id)
    }
  }
}
