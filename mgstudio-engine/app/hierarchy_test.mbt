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
struct HierarchyValidationMarker {} derive(Eq, Show)

///|
let hierarchy_validation_marker_key : @ecs.ComponentKey[
  HierarchyValidationMarker,
] = @ecs.register_component(debug_name="tests.app.hierarchy.validation_marker")

///|
pub impl @ecs.Component for HierarchyValidationMarker with component() {
  hierarchy_validation_marker_key
}

///|
test "app hierarchy: validate-parent plugin queues a check when parent lacks component" {
  let plugin : ValidateParentHasComponentPlugin[HierarchyValidationMarker] = ValidateParentHasComponentPlugin::default()
  let app = App::new(@ecs.World::new()).add_plugins([
    validate_parent_has_component_plugin(plugin),
  ])
  let world = app.world()
  let parent = world.spawn_empty()
  let child = world.spawn_empty()

  try! world.set_by_key(
    child,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(parent),
  )
  try! world.set_by_key(child, hierarchy_validation_marker_key, HierarchyValidationMarker::{

  })

  let reader = world.message_reader(
    check_parent_has_component_message_key(hierarchy_validation_marker_key),
    Ref::new(0),
  )
  inspect(reader.len(), content="1")
  let pending = try! reader.read()
  inspect(pending.length(), content="1")
  inspect(pending[0].caller is None, content="true")
}

///|
test "app hierarchy: validate-parent plugin skips checks when parent already has component" {
  let plugin : ValidateParentHasComponentPlugin[HierarchyValidationMarker] = ValidateParentHasComponentPlugin::default()
  let app = App::new(@ecs.World::new()).add_plugins([
    validate_parent_has_component_plugin(plugin),
  ])
  let world = app.world()
  let parent = world.spawn_empty()
  let child = world.spawn_empty()

  try! world.set_by_key(parent, hierarchy_validation_marker_key, HierarchyValidationMarker::{

  })
  try! world.set_by_key(
    child,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(parent),
  )
  try! world.set_by_key(child, hierarchy_validation_marker_key, HierarchyValidationMarker::{

  })

  let reader = world.message_reader(
    check_parent_has_component_message_key(hierarchy_validation_marker_key),
    Ref::new(0),
  )
  inspect(reader.len(), content="0")
}

///|
test "app hierarchy: validate-parent plugin rechecks on component replace" {
  let plugin : ValidateParentHasComponentPlugin[HierarchyValidationMarker] = ValidateParentHasComponentPlugin::default()
  let app = App::new(@ecs.World::new()).add_plugins([
    validate_parent_has_component_plugin(plugin),
  ])
  let world = app.world()
  let parent = world.spawn_empty()
  let child = world.spawn_empty()

  try! world.set_by_key(
    child,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(parent),
  )
  try! world.set_by_key(child, hierarchy_validation_marker_key, HierarchyValidationMarker::{

  })
  try! world.set_by_key(child, hierarchy_validation_marker_key, HierarchyValidationMarker::{

  })

  let reader = world.message_reader(
    check_parent_has_component_message_key(hierarchy_validation_marker_key),
    Ref::new(0),
  )
  inspect(reader.len(), content="2")
}

///|
test "app hierarchy: check-parent message preserves explicit caller" {
  let entity = @core.Entity::new(10, 1)
  let message : CheckParentHasComponent[HierarchyValidationMarker] = CheckParentHasComponent::new(
    entity,
    caller=Some("caller-location"),
  )
  inspect(
    message.entity().id == 10 && message.entity().generation == 1,
    content="true",
  )
  inspect(message.caller(), content="Some(\"caller-location\")")
}

///|
test "app hierarchy: check-parent message defaults caller to none" {
  let entity = @core.Entity::new(11, 3)
  let message : CheckParentHasComponent[HierarchyValidationMarker] = CheckParentHasComponent::new(
    entity,
  )
  inspect(
    message.entity().id == 11 && message.entity().generation == 3,
    content="true",
  )
  inspect(message.caller() is None, content="true")
}
