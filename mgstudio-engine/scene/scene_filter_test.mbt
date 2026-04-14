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
struct SceneFilterTestComponent {}

///|
let scene_filter_test_component_key : @ecs.ComponentKey[
  SceneFilterTestComponent,
] = @ecs.register_component(
  debug_name="mgstudio.scene.SceneFilterTestComponent",
)

///|
pub impl @ecs.Component for SceneFilterTestComponent with component() {
  scene_filter_test_component_key
}

///|
struct SceneFilterTestResource {}

///|
let scene_filter_test_resource_key : @ecs.ResourceKey[SceneFilterTestResource] = @ecs.register_resource(
  debug_name="mgstudio.scene.SceneFilterTestResource",
)

///|
pub impl @app.Resource for SceneFilterTestResource with resource() {
  scene_filter_test_resource_key
}

///|
test "scene filter: unset allows every key" {
  let _component = SceneFilterTestComponent::{  }
  let _resource = SceneFilterTestResource::{  }
  let filter = SceneFilter::default()
  debug_inspect(
    filter.is_component_allowed_by_id(scene_filter_test_component_key.id()),
    content="true",
  )
  debug_inspect(
    filter.is_resource_allowed_by_id(scene_filter_test_resource_key.id()),
    content="true",
  )
  debug_inspect(filter.len(), content="0")
  debug_inspect(filter.is_empty(), content="true")
}

///|
test "scene filter: allow list only permits explicit entries" {
  let filter = SceneFilter::default().allow_component_by_id(
    scene_filter_test_component_key.id(),
  )
  debug_inspect(
    filter.is_component_allowed_by_id(scene_filter_test_component_key.id()),
    content="true",
  )
  debug_inspect(
    filter.is_resource_allowed_by_id(scene_filter_test_resource_key.id()),
    content="false",
  )
  debug_inspect(filter.len(), content="1")
}

///|
test "scene filter: deny list removes explicit entries from unset" {
  let filter = SceneFilter::default().deny_resource_by_id(
    scene_filter_test_resource_key.id(),
  )
  debug_inspect(
    filter.is_resource_allowed_by_id(scene_filter_test_resource_key.id()),
    content="false",
  )
  debug_inspect(
    filter.is_component_allowed_by_id(scene_filter_test_component_key.id()),
    content="true",
  )
  debug_inspect(filter.len(), content="1")
}

///|
test "scene filter: allow_all and deny_all mirror bevy semantics" {
  let allow_all = SceneFilter::allow_all()
  debug_inspect(
    allow_all.is_component_allowed_by_id(scene_filter_test_component_key.id()),
    content="true",
  )
  debug_inspect(
    allow_all.is_resource_allowed_by_id(scene_filter_test_resource_key.id()),
    content="true",
  )
  debug_inspect(allow_all.is_empty(), content="true")

  let deny_all = SceneFilter::deny_all()
  debug_inspect(
    deny_all.is_component_allowed_by_id(scene_filter_test_component_key.id()),
    content="false",
  )
  debug_inspect(
    deny_all.is_resource_allowed_by_id(scene_filter_test_resource_key.id()),
    content="false",
  )
  debug_inspect(deny_all.is_empty(), content="true")
}
