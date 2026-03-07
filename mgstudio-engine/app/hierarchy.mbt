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
pub struct ValidateParentHasComponentPlugin[C] {
  schedule : ScheduleStage
  marker : C?
}

///|
pub fn[C] ValidateParentHasComponentPlugin::default() -> ValidateParentHasComponentPlugin[
  C,
] {
  ValidateParentHasComponentPlugin::in_schedule(Last)
}

///|
pub fn[C] ValidateParentHasComponentPlugin::in_schedule(
  label : ScheduleStage,
) -> ValidateParentHasComponentPlugin[C] {
  { schedule: label, marker: None }
}

///|
pub let validate_parent_has_component_system_set : SystemSet = system_set(
  "bevy_app.validate_parent_has_component",
)

///|
pub struct CheckParentHasComponent[C] {
  entity : @core.Entity
  marker : C?
}

///|
pub fn[C] CheckParentHasComponent::new(
  entity : @core.Entity,
) -> CheckParentHasComponent[C] {
  { entity, marker: None }
}

///|
pub impl[C] ToJson for CheckParentHasComponent[C] with to_json(self) {
  (self.entity.id, self.entity.generation).to_json()
}

///|
pub impl[C] @json.FromJson for CheckParentHasComponent[C] with from_json(
  json,
  path,
) {
  let (id, generation) : (Int, Int) = @json.from_json(json, path~)
  CheckParentHasComponent::new(@core.Entity::new(id, generation))
}

///|
fn[T] component_debug_name(key : @ecs.ComponentKey[T]) -> String {
  if key.debug_name() != "" {
    key.debug_name()
  } else {
    "component#" + key.id().to_string()
  }
}

///|
pub fn[C] check_parent_has_component_message_key(
  component_key : @ecs.ComponentKey[C],
) -> @ecs.MessageKey[CheckParentHasComponent[C]] {
  @ecs.register_message(
    debug_name="bevy_app::CheckParentHasComponent<" +
      component_debug_name(component_key) +
      ">",
  )
}

///|
pub impl[C : @ecs.Component] @ecs.Message for CheckParentHasComponent[C] with message() {
  let component_key : @ecs.ComponentKey[C] = @ecs.Component::component()
  check_parent_has_component_message_key(component_key)
}

///|
fn[C] validate_parent_has_component_insert(
  world : @ecs.World,
  component_key : @ecs.ComponentKey[C],
  message_key : @ecs.MessageKey[CheckParentHasComponent[C]],
  entity : @core.Entity,
) -> Unit {
  let child_of_result : Result[@hierarchy.Parent?, @ecs.EcsError] = try? world.get(
    entity, @hierarchy.ecs_key_parent,
  )
  guard child_of_result is Ok(Some(child_of)) else { return }
  if world.component(component_key).contains(child_of.entity()) {
    return
  }
  ignore(world.send_message(message_key, CheckParentHasComponent::new(entity)))
}

///|
fn validate_parent_has_component_warning(
  component_name : String,
  child : @core.Entity,
  parent : @core.Entity,
) -> String {
  "warning[B0004]: Entity (" +
  child.id.to_string() +
  ", " +
  child.generation.to_string() +
  ") with the " +
  component_name +
  " component has a parent (" +
  parent.id.to_string() +
  ", " +
  parent.generation.to_string() +
  ") without " +
  component_name +
  ". This will cause inconsistent behaviors! See: https://bevy.org/learn/errors/b0004"
}

///|
fn current_world_abort_missing() -> @ecs.World {
  match current_world() {
    Some(world) => world
    None => abort("Missing current world while running hierarchy validation")
  }
}

///|
fn[C] check_parent_has_component(
  component_key : @ecs.ComponentKey[C],
  component_name : String,
  messages : @ecs.MessageReader[CheckParentHasComponent[C]],
) -> Unit {
  let world = current_world_abort_missing()
  for message in (try! messages.read()) {
    let child_of_result : Result[@hierarchy.Parent?, @ecs.EcsError] = try? world.get(
      message.entity,
      @hierarchy.ecs_key_parent,
    )
    guard child_of_result is Ok(Some(child_of)) else { continue }
    if !world.component(component_key).contains(message.entity) {
      continue
    }
    let parent = child_of.entity()
    if world.component(component_key).contains(parent) {
      continue
    }
    println(
      validate_parent_has_component_warning(
        component_name,
        message.entity,
        parent,
      ),
    )
  }
}

///|
fn validate_parent_insert_observer_name(component_name : String) -> String {
  "bevy_app.validate_parent_has_component.insert<" + component_name + ">"
}

///|
pub fn[C : @ecs.Component] validate_parent_has_component_plugin(
  plugin : ValidateParentHasComponentPlugin[C],
) -> Plugin[@ecs.World] {
  fn(app : App[@ecs.World]) {
    let component_key : @ecs.ComponentKey[C] = @ecs.Component::component()
    let component_name = component_debug_name(component_key)
    let message_key = check_parent_has_component_message_key(component_key)
    ignore(
      @ecs.register_component_insert_observer(
        component_key,
        validate_parent_insert_observer_name(component_name),
        fn(world, entity) {
          validate_parent_has_component_insert(
            world, component_key, message_key, entity,
          )
        },
      ),
    )
    app
    .add_message(message_key)
    .add_systems(
      plugin.schedule,
      system(
        system_param(fn(
          messages : @ecs.MessageReader[CheckParentHasComponent[C]],
        ) {
          check_parent_has_component(component_key, component_name, messages)
        }),
      )
      .run_if_on_message(message_key)
      .in_set(validate_parent_has_component_system_set),
    )
  }
}
