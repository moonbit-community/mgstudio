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
struct ObserverMarker {
  value : Int
} derive(Eq, Show)

///|
let observer_marker_key : @ecs.ComponentKey[ObserverMarker] = @ecs.register_component(
  debug_name="tests.app.observer.marker",
)

///|
pub impl @ecs.Component for ObserverMarker with component() {
  observer_marker_key
}

///|
struct ObserverTriggered {
  entity_id : Int
  entity_generation : Int
} derive(Eq)

///|
fn observer_triggered_key() -> @ecs.MessageKey[ObserverTriggered] {
  @ecs.register_message(debug_name="tests.app.observer.triggered")
}

///|
pub impl @ecs.Message for ObserverTriggered with message() {
  observer_triggered_key()
}

///|
fn write_insert_message(
  event : @ecs.On[@ecs.Insert, ObserverMarker],
  writer : @ecs.MessageWriter[ObserverTriggered],
) -> Unit {
  ignore(
    writer.write({
      entity_id: event.entity.id,
      entity_generation: event.entity.generation,
    }),
  )
}

///|
fn write_remove_message(
  event : @ecs.On[@ecs.Remove, ObserverMarker],
  writer : @ecs.MessageWriter[ObserverTriggered],
) -> Unit {
  ignore(
    writer.write({
      entity_id: event.entity.id,
      entity_generation: event.entity.generation,
    }),
  )
}

///|
test "app observer: add_observer2 exposes On<Insert, C> with MessageWriter" {
  let message_key = observer_triggered_key()
  let app = App::new(@ecs.World::new())
    .add_message(message_key)
    .add_observer2(write_insert_message)
  let world = app.world()
  let entity = world.spawn()

  try! world.set(entity, observer_marker_key, ObserverMarker::{ value: 7 })

  let reader = world.message_reader(message_key, Ref::new(0))
  let messages = try! reader.read()
  inspect(messages.length(), content="1")
  inspect(messages[0].entity_id, content="0")
  inspect(messages[0].entity_generation, content="1")
}

///|
test "app observer: add_observer2 exposes On<Remove, C> with MessageWriter" {
  let message_key = observer_triggered_key()
  let app = App::new(@ecs.World::new())
    .add_message(message_key)
    .add_observer2(write_remove_message)
  let world = app.world()
  let entity = world.spawn()

  try! world.set(entity, observer_marker_key, ObserverMarker::{ value: 11 })
  ignore(try! world.remove(entity, observer_marker_key))

  let reader = world.message_reader(message_key, Ref::new(0))
  let messages = try! reader.read()
  inspect(messages.length(), content="1")
  inspect(messages[0].entity_id, content="0")
  inspect(messages[0].entity_generation, content="1")
}

///|
test "app observer: fallible insert observers route errors through the default handler" {
  let kinds : Array[ErrorContextKind] = []
  let sources : Array[String] = []
  let app = App::new(@ecs.World::new())
    .set_error_handler(fn(_error, context) {
      kinds.push(context.kind())
      sources.push(context.source())
    })
    .add_observer_fallible(fn(
      _event : @ecs.On[@ecs.Insert, ObserverMarker],
    ) raise {
      raise @ecs.Invalid("insert observer failed")
    })
  let world = app.world()
  let entity = world.spawn()

  try! world.set(entity, observer_marker_key, ObserverMarker::{ value: 5 })

  inspect(kinds.length(), content="1")
  inspect(kinds[0] == ErrorContextKind::Observer, content="true")
  inspect(sources[0], content="<observer>")
}

///|
test "app observer: fallible remove observers route errors through the default handler" {
  let kinds : Array[ErrorContextKind] = []
  let app = App::new(@ecs.World::new())
    .set_error_handler(fn(_error, context) { kinds.push(context.kind()) })
    .add_observer_fallible(fn(
      _event : @ecs.On[@ecs.Remove, ObserverMarker],
    ) raise {
      raise @ecs.Invalid("remove observer failed")
    })
  let world = app.world()
  let entity = world.spawn()

  try! world.set(entity, observer_marker_key, ObserverMarker::{ value: 6 })
  ignore(try! world.remove(entity, observer_marker_key))

  inspect(kinds.length(), content="1")
  inspect(kinds[0] == ErrorContextKind::Observer, content="true")
}
