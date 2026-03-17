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
/// Port of `bevy/examples/ecs/component_hooks.rs`.

///|
struct MyComponent {
  key : @window.KeyCode
} derive(Eq)

///|
pub fn MyComponent::new(key : @window.KeyCode) -> MyComponent {
  { key, }
}

///|
struct MyComponentIndex {
  entities : @hashmap.HashMap[@window.KeyCode, @core.Entity]
}

///|
struct MyMessage {}

///|
let my_component_key : @ecs.ComponentKey[MyComponent] = @ecs.register_component(
  debug_name="examples.ecs.component_hooks.MyComponent",
)

///|
let my_component_index_key : @ecs.ResourceKey[MyComponentIndex] = @ecs.register_resource(
  debug_name="examples.ecs.component_hooks.MyComponentIndex",
)

///|
let my_message_key : @ecs.MessageKey[MyMessage] = @ecs.register_message(
  debug_name="examples.ecs.component_hooks.MyMessage",
)

///|
pub impl @ecs.Component for MyComponent with component() {
  my_component_key
}

///|
pub impl @app.Resource for MyComponentIndex with resource() {
  my_component_index_key
}

///|
pub impl @ecs.Message for MyMessage with message() {
  my_message_key
}

///|
pub impl Default for MyComponentIndex with default() {
  { entities: @hashmap.HashMap::new() }
}

///|
fn caller_suffix(caller : String?) -> String {
  match caller {
    Some(location) => " due to " + location
    None => ""
  }
}

///|
fn my_component_index_or_abort(world : @ecs.World) -> MyComponentIndex {
  match world.resource(my_component_index_key).get() {
    Some(index) => index
    None =>
      abort("Missing MyComponentIndex resource in component_hooks example")
  }
}

///|
fn my_component_or_abort(
  world : @ecs.DeferredWorld,
  entity : @core.Entity,
) -> MyComponent {
  match (try! world.get(entity, my_component_key)) {
    Some(component) => component
    None =>
      abort("Missing MyComponent on hook target in component_hooks example")
  }
}

///|
fn my_component_index_text(index : MyComponentIndex) -> String {
  let entries : Array[String] = []
  index.entities.each(fn(key, entity) {
    entries.push(key.to_string() + ":" + entity.id.to_string())
  })
  "{" + entries.join(", ") + "}"
}

///|
fn update_my_component_index(
  world : @ecs.DeferredWorld,
  update : (MyComponentIndex) -> MyComponentIndex,
) -> Unit {
  if !world
    .resource(my_component_index_key)
    .update(world.read_change_tick(), update) {
    abort("Missing MyComponentIndex resource in component_hooks example")
  }
}

///|
fn write_my_message(world : @ecs.DeferredWorld) -> Unit {
  if !world
    .resource(my_message_key.messages_resource())
    .update(world.read_change_tick(), fn(messages) {
      ignore(messages.write_message(my_message_key, MyMessage::{  }))
      messages
    }) {
    abort("Missing MyMessage queue in component_hooks example")
  }
}

///|
fn setup(world : @ecs.World) -> Unit {
  ignore(
    try! world
    .register_component_hooks_for_key(my_component_key)
    .on_add(fn(world, context) {
      let component = my_component_or_abort(world, context.entity)
      @app.log_info(
        context.component_id.to_string() +
        " added to entity " +
        context.entity.id.to_string() +
        " with value " +
        component.key.to_string() +
        caller_suffix(context.caller),
      )
      update_my_component_index(world, fn(index) {
        index.entities.set(component.key, context.entity)
        index
      })
      write_my_message(world)
    })
    .on_insert(fn(world, _context) {
      @app.log_info(
        "Current Index: " +
        my_component_index_text(my_component_index_or_abort(world.world())),
      )
    })
    .on_replace(fn(world, context) {
      let component = my_component_or_abort(world, context.entity)
      update_my_component_index(world, fn(index) {
        index.entities.remove(component.key)
        index
      })
    })
    .on_remove(fn(world, context) {
      let component = my_component_or_abort(world, context.entity)
      @app.log_info(
        context.component_id.to_string() +
        " removed from entity " +
        context.entity.id.to_string() +
        " with value " +
        component.key.to_string() +
        caller_suffix(context.caller),
      )
      world.commands().entity(context.entity).despawn()
    }),
  )
}

///|
fn trigger_hooks(
  commands : @app.Commands,
  keys : @input.ButtonInput[@window.KeyCode],
  index : @app.Res[MyComponentIndex],
) -> Unit {
  for entry in index.get().entities.iter() {
    let (key, entity) = entry
    if !keys.pressed(key) {
      commands.entity(entity).remove_component(my_component_key)
    }
  }
  for key in keys.get_just_pressed() {
    ignore(commands.spawn_component(MyComponent::new(key)))
  }
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.default_plugins())
  .init_resource(MyComponentIndex::default)
  .add_message(my_message_key)
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(@app.Update, @app.system(@app.system_param3(trigger_hooks)))
  .run()
}
