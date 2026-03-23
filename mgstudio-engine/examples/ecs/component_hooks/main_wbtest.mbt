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
test "examples ecs component_hooks: hooks keep index and message queue in sync" {
  let world = @ecs.World::new()
  world
  .resource(my_component_index_key)
  .insert(MyComponentIndex::default(), world.read_sequence())
  world
  .resource(my_message_key.messages_resource())
  .insert(@ecs.Messages::new(), world.read_sequence())

  setup(world)

  let entity = world.spawn()
  try! world.set(
    entity,
    my_component_key,
    MyComponent::new(@window.KeyCode::KeyA),
  )

  match my_component_index_or_abort(world).entities.get(@window.KeyCode::KeyA) {
    Some(indexed_entity) => inspect(indexed_entity == entity, content="true")
    None => abort("expected KeyA to be indexed after on_add")
  }
  match world.resource(my_message_key.messages_resource()).get() {
    Some(messages) => inspect(messages.len(), content="1")
    None =>
      abort("expected MyMessage queue to exist in component_hooks example")
  }

  inspect(try! world.remove(entity, my_component_key), content="true")
  inspect(world.is_alive(entity), content="false")
  inspect(
    my_component_index_or_abort(world).entities.contains(@window.KeyCode::KeyA),
    content="false",
  )
}
