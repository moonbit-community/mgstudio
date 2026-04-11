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
} derive(Eq, Debug)

///|
let observer_marker_key : @ecs.ComponentKey[ObserverMarker] = @ecs.register_component(
  debug_name="tests.app.observer.marker",
)

///|
pub impl @ecs.Component for ObserverMarker with component() {
  observer_marker_key
}

///|
struct ObserverPulse {
  amount : Int
} derive(Eq, Debug)

///|
let observer_pulse_event_key : @ecs.EventKey[ObserverPulse] = @ecs.register_event(
  debug_name="tests.app.observer.pulse",
)

///|
pub impl @ecs.TriggerEvent for ObserverPulse with observer_event() {
  observer_pulse_event_key
}

///|
pub impl @ecs.TriggerEvent for ObserverPulse with observer_entity(_self) {
  None
}

///|
pub impl @ecs.TriggerEvent for ObserverPulse with set_observer_entity(
  _event_ref,
  _entity,
) {

}

///|
pub impl @ecs.TriggerEvent for ObserverPulse with auto_propagate(_self) {
  false
}

///|
pub impl @ecs.TriggerEvent for ObserverPulse with debug_name() {
  "ObserverPulse"
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
struct TriggerObserverTriggered {
  amount : Int
} derive(Eq)

///|
fn trigger_observer_triggered_key() -> @ecs.MessageKey[TriggerObserverTriggered] {
  @ecs.register_message(debug_name="tests.app.observer.trigger_message")
}

///|
pub impl @ecs.Message for TriggerObserverTriggered with message() {
  trigger_observer_triggered_key()
}

///|
fn write_insert_message(
  event : @ecs.ComponentOn[@ecs.Insert, ObserverMarker],
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
  event : @ecs.ComponentOn[@ecs.Remove, ObserverMarker],
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
fn write_trigger_message(
  event : @ecs.On[ObserverPulse],
  writer : @ecs.MessageWriter[TriggerObserverTriggered],
) -> Unit {
  ignore(writer.write({ amount: event.event().amount }))
}

///|
test "app observer: add_observer2 exposes On<E> with MessageWriter" {
  let message_key = trigger_observer_triggered_key()
  let app = App::new(@ecs.World::new())
    .add_message(message_key)
    .add_observer2(write_trigger_message)
  let world = app.world()

  world.trigger(ObserverPulse::{ amount: 13 })

  let reader = world.message_reader(message_key, Ref::new(0))
  let messages = try! reader.read()
  debug_inspect(messages.length(), content="1")
  debug_inspect(messages[0].amount, content="13")
}

///|
test "app observer: add_component_observer2 exposes ComponentOn<Insert, C> with MessageWriter" {
  let message_key = observer_triggered_key()
  let app = App::new(@ecs.World::new())
    .add_message(message_key)
    .add_component_observer2(write_insert_message)
  let world = app.world()
  let entity = world.spawn()

  try! world.set_by_key(entity, observer_marker_key, ObserverMarker::{
    value: 7,
  })

  let reader = world.message_reader(message_key, Ref::new(0))
  let messages = try! reader.read()
  debug_inspect(messages.length(), content="1")
  debug_inspect(messages[0].entity_id, content="0")
  debug_inspect(messages[0].entity_generation, content="1")
}

///|
test "app observer: add_component_observer2 exposes ComponentOn<Remove, C> with MessageWriter" {
  let message_key = observer_triggered_key()
  let app = App::new(@ecs.World::new())
    .add_message(message_key)
    .add_component_observer2(write_remove_message)
  let world = app.world()
  let entity = world.spawn()

  try! world.set_by_key(entity, observer_marker_key, ObserverMarker::{
    value: 11,
  })
  ignore(try! world.remove_by_key(entity, observer_marker_key))

  let reader = world.message_reader(message_key, Ref::new(0))
  let messages = try! reader.read()
  debug_inspect(messages.length(), content="1")
  debug_inspect(messages[0].entity_id, content="0")
  debug_inspect(messages[0].entity_generation, content="1")
}

///|
test "app observer: fallible component insert observers route errors through the default handler" {
  let kinds : Array[ErrorContextKind] = []
  let sources : Array[String] = []
  let app = App::new(@ecs.World::new())
    .set_error_handler(fn(_error, context) {
      kinds.push(context.kind())
      sources.push(context.source())
    })
    .add_component_observer_fallible(fn(
      _event : @ecs.ComponentOn[@ecs.Insert, ObserverMarker],
    ) raise {
      raise @ecs.Invalid("insert observer failed")
    })
  let world = app.world()
  let entity = world.spawn()

  try! world.set_by_key(entity, observer_marker_key, ObserverMarker::{
    value: 5,
  })

  debug_inspect(kinds.length(), content="1")
  debug_inspect(kinds[0] == ErrorContextKind::Observer, content="true")
  debug_inspect(sources[0], content="\"<component-observer>\"")
}

///|
test "app observer: fallible component remove observers route errors through the default handler" {
  let kinds : Array[ErrorContextKind] = []
  let app = App::new(@ecs.World::new())
    .set_error_handler(fn(_error, context) { kinds.push(context.kind()) })
    .add_component_observer_fallible(fn(
      _event : @ecs.ComponentOn[@ecs.Remove, ObserverMarker],
    ) raise {
      raise @ecs.Invalid("remove observer failed")
    })
  let world = app.world()
  let entity = world.spawn()

  try! world.set_by_key(entity, observer_marker_key, ObserverMarker::{
    value: 6,
  })
  ignore(try! world.remove_by_key(entity, observer_marker_key))

  debug_inspect(kinds.length(), content="1")
  debug_inspect(kinds[0] == ErrorContextKind::Observer, content="true")
}

///|
test "app observer: fallible trigger observers route errors through the default handler" {
  let kinds : Array[ErrorContextKind] = []
  let sources : Array[String] = []
  let app = App::new(@ecs.World::new())
    .set_error_handler(fn(_error, context) {
      kinds.push(context.kind())
      sources.push(context.source())
    })
    .add_observer_fallible(fn(_event : @ecs.On[ObserverPulse]) raise {
      raise @ecs.Invalid("trigger observer failed")
    })
  let world = app.world()

  world.trigger(ObserverPulse::{ amount: 5 })

  debug_inspect(kinds.length(), content="1")
  debug_inspect(kinds[0] == ErrorContextKind::Observer, content="true")
  debug_inspect(sources[0], content="\"<observer>\"")
}
