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
pub struct ValidateParentHasComponentPlugin[_] {
  schedule : ScheduleStage
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
  { schedule: label }
}

///|
pub let validate_parent_has_component_system_set : SystemSet = system_set(
  "bevy_app.validate_parent_has_component",
)

///|
pub struct CheckParentHasComponent[_] {
  entity : @core.Entity
  caller : String?
}

///|
pub fn[C] CheckParentHasComponent::new(
  entity : @core.Entity,
  caller? : String? = None,
) -> CheckParentHasComponent[C] {
  { entity, caller }
}

///|
pub fn[C] CheckParentHasComponent::entity(
  self : CheckParentHasComponent[C],
) -> @core.Entity {
  self.entity
}

///|
pub fn[C] CheckParentHasComponent::caller(
  self : CheckParentHasComponent[C],
) -> String? {
  self.caller
}

///|
fn[T] component_debug_name(key : @ecs.ComponentKey[T]) -> String {
  if key.debug_name() != "" {
    key.debug_name()
  } else {
    "component#\{key.id().to_string()}"
  }
}

///|
pub fn[C] check_parent_has_component_message_key(
  component_key : @ecs.ComponentKey[C],
) -> @ecs.MessageKey[CheckParentHasComponent[C]] {
  @ecs.register_message(
    debug_name="mgstudio_app::CheckParentHasComponent<\{component_debug_name(component_key)}>",
  )
}

///|
pub impl[C : @ecs.Component] @ecs.Message for CheckParentHasComponent[C] with message() {
  let component_key : @ecs.ComponentKey[C] = @ecs.Component::component()
  check_parent_has_component_message_key(component_key)
}

///|
fn[C : @ecs.Component] validate_parent_has_component(
  event : @ecs.ComponentOn[@ecs.Insert, C],
) -> Unit {
  let world = current_world_abort_missing()
  let component_key : @ecs.ComponentKey[C] = @ecs.Component::component()
  let message_key = check_parent_has_component_message_key(component_key)
  guard (world.get_by_key(event.entity, @hierarchy.ecs_key_parent) catch {
      _ => None
    })
    is Some(child_of) else {
    return
  }
  if (try! world.contains_by_key(child_of.entity(), component_key)) {
    return
  }
  ignore(
    world.send_message(
      message_key,
      CheckParentHasComponent::new(event.entity, caller=event.caller()),
    ),
  )
}

///|
fn validate_parent_has_component_entity_label(
  entity : @core.Entity,
  name : @ecs.Name?,
  is_parent? : Bool = false,
) -> String {
  if name is Some(name_value) {
    if is_parent {
      "the \{name_value.as_str()} entity"
    } else {
      "The \{name_value.as_str()} entity"
    }
  } else {
    "Entity (\{entity.id.to_string()}, \{entity.generation.to_string()})"
  }
}

///|
fn validate_parent_has_component_warning(
  caller : String?,
  component_name : String,
  child : @core.Entity,
  child_name : @ecs.Name?,
  parent : @core.Entity,
  parent_name : @ecs.Name?,
) -> String {
  let caller_prefix = match caller {
    Some(location) => "\{location}: "
    None => ""
  }
  let parent_label = validate_parent_has_component_entity_label(
    parent,
    parent_name,
    is_parent=true,
  )
  "warning[B0004]: \{caller_prefix}\{validate_parent_has_component_entity_label(child, child_name)} with the \{component_name} component has a parent (\{parent_label}) without \{component_name}. This will cause inconsistent behaviors! See: https://bevy.org/learn/errors/b0004"
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
    guard (world.get_by_key(message.entity, @hierarchy.ecs_key_parent) catch {
        _ => None
      })
      is Some(child_of) else {
      continue
    }
    if !(try! world.contains_by_key(message.entity, component_key)) {
      continue
    }
    let parent = child_of.entity()
    if (try! world.contains_by_key(parent, component_key)) {
      continue
    }
    let child_name = try! world.get_by_key(message.entity, @ecs.ecs_key_name)
    let parent_name = try! world.get_by_key(parent, @ecs.ecs_key_name)
    println(
      validate_parent_has_component_warning(
        message.caller,
        component_name,
        message.entity,
        child_name,
        parent,
        parent_name,
      ),
    )
  }
}

///|
pub fn[C : @ecs.Component] validate_parent_has_component_plugin(
  plugin : ValidateParentHasComponentPlugin[C],
) -> Plugin[@ecs.World] {
  fn(app : App[@ecs.World]) {
    let component_key : @ecs.ComponentKey[C] = @ecs.Component::component()
    let component_name = component_debug_name(component_key)
    let message_key = check_parent_has_component_message_key(component_key)
    app
    .add_message(message_key)
    .add_component_observer(fn(event : @ecs.ComponentOn[@ecs.Insert, C]) {
      validate_parent_has_component(event)
    })
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
