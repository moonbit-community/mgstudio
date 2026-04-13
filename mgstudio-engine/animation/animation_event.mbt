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
// Bevy source: `bevy/crates/bevy_animation/src/animation_event.rs`.
// Bevy-aligned animation event runtime and dispatch.

///|
pub(open) trait AnimationEvent {
  animation_event_marker(Self) -> Unit
}

///|
pub struct AnimationClipEvent {
  time : Float
  label : String
  payload : String
  callback_id : Int?
  typed_event_payload : @any.Any?
  typed_event_type_key : String?
}

///|
pub fn AnimationClipEvent::new(
  time : Float,
  label : String,
  payload : String,
) -> AnimationClipEvent {
  AnimationClipEvent::{
    time,
    label,
    payload,
    callback_id: None,
    typed_event_payload: None,
    typed_event_type_key: None,
  }
}

///|
pub fn AnimationClipEvent::new_callback(
  time : Float,
  callback_id : Int,
) -> AnimationClipEvent {
  AnimationClipEvent::{
    time,
    label: "",
    payload: "",
    callback_id: Some(callback_id),
    typed_event_payload: None,
    typed_event_type_key: None,
  }
}

///|
let animation_typed_event_dispatchers : Array[
  (String, (@ecs.World, @any.Any, @core.Entity, String?) -> Unit),
] = []

///|
fn animation_typed_event_find_dispatcher(
  type_key : String,
) -> ((@ecs.World, @any.Any, @core.Entity, String?) -> Unit)? {
  for entry in animation_typed_event_dispatchers {
    if entry.0 == type_key {
      return Some(entry.1)
    }
  }
  None
}

///|
fn[T : AnimationEvent] animation_typed_event_type_key(event : T) -> String {
  event.animation_event_marker()
  @any.of(event).type_name()
}

///|
fn[T : AnimationEvent + @ecs.TriggerEvent] animation_typed_event_register(
  event : T,
) -> String {
  let type_key = animation_typed_event_type_key(event)
  if animation_typed_event_find_dispatcher(type_key) is None {
    animation_typed_event_dispatchers.push(
      (
        type_key,
        fn(world, payload, entity, caller) {
          match payload.try_to() {
            Some(event_value) => {
              let event_ref : Ref[T] = Ref::new(event_value)
              T::set_observer_entity(event_ref, entity)
              world.trigger(event_ref.val, caller~)
            }
            None => abort("animation clip typed event payload type mismatch")
          }
        },
      ),
    )
  }
  type_key
}

///|
pub fn[T : AnimationEvent + @ecs.TriggerEvent] AnimationClipEvent::new_typed(
  time : Float,
  event : T,
) -> AnimationClipEvent {
  let type_key = animation_typed_event_register(event)
  AnimationClipEvent::{
    time,
    label: "",
    payload: "",
    callback_id: None,
    typed_event_payload: Some(@any.of(event)),
    typed_event_type_key: Some(type_key),
  }
}

///|
pub fn AnimationClipEvent::time(self : AnimationClipEvent) -> Float {
  self.time
}

///|
pub fn AnimationClipEvent::label(self : AnimationClipEvent) -> String {
  self.label
}

///|
pub fn AnimationClipEvent::payload(self : AnimationClipEvent) -> String {
  self.payload
}

///|
pub fn AnimationClipEvent::callback_id(self : AnimationClipEvent) -> Int? {
  self.callback_id
}

///|
pub fn AnimationClipEvent::typed_event_payload(
  self : AnimationClipEvent,
) -> @any.Any? {
  self.typed_event_payload
}

///|
pub(all) enum AnimationEventTarget {
  Root
  Node(AnimationTargetId)
}

///|
pub struct AnimationTriggeredEvent {
  player : @core.Entity
  target : @core.Entity
  target_id : AnimationTargetId?
  time : Float
  weight : Float
  label : String
  payload : String
}

///|
pub fn AnimationTriggeredEvent::player(
  self : AnimationTriggeredEvent,
) -> @core.Entity {
  self.player
}

///|
pub fn AnimationTriggeredEvent::target(
  self : AnimationTriggeredEvent,
) -> @core.Entity {
  self.target
}

///|
pub fn AnimationTriggeredEvent::target_id(
  self : AnimationTriggeredEvent,
) -> AnimationTargetId? {
  self.target_id
}

///|
pub fn AnimationTriggeredEvent::time(self : AnimationTriggeredEvent) -> Float {
  self.time
}

///|
pub fn AnimationTriggeredEvent::weight(self : AnimationTriggeredEvent) -> Float {
  self.weight
}

///|
pub fn AnimationTriggeredEvent::label(self : AnimationTriggeredEvent) -> String {
  self.label
}

///|
pub fn AnimationTriggeredEvent::payload(
  self : AnimationTriggeredEvent,
) -> String {
  self.payload
}

///|
pub type AnimationEventCallback = (@core.Entity, Float, Float) -> Unit

///|
let animation_event_callbacks : Array[AnimationEventCallback] = []

///|
pub fn animation_register_event_callback(
  callback : AnimationEventCallback,
) -> Int {
  animation_event_callbacks.push(callback)
  animation_event_callbacks.length() - 1
}

///|
fn animation_event_callback_get(callback_id : Int) -> AnimationEventCallback? {
  animation_event_callbacks.get(callback_id)
}

///|
let animation_triggered_events : Ref[@core.Messages[AnimationTriggeredEvent]] = Ref::new(
  @core.Messages::new(),
)

///|
pub impl @core.Message for AnimationTriggeredEvent with reader(
  sequence : @core.SystemSequence,
) {
  animation_triggered_events.val.reader(sequence)
}

///|
pub impl @core.Message for AnimationTriggeredEvent with writer(
  tick : @core.Sequence,
) {
  animation_triggered_events.val.writer(tick)
}

///|
pub(all) enum AnimationTriggeredEventsDirection {
  Forward
  Reverse
  ForwardLooping
  ReverseLooping
}

///|
fn animation_clip_collect_triggered_events(
  events : Array[AnimationClipEvent],
  active : ActiveAnimation,
) -> Array[AnimationClipEvent] {
  let triggered : Array[AnimationClipEvent] = []
  if events.length() == 0 {
    return triggered
  }

  let reverse = active.is_playback_reversed()
  let finished = active.is_finished()
  if finished && !active.just_completed() {
    return triggered
  }
  guard active.last_seek_time is Some(last_time) else { return triggered }
  let this_time = active.seek_time()
  let looping = active.just_completed() && !finished
  let direction = match (reverse, looping) {
    (false, false) => AnimationTriggeredEventsDirection::Forward
    (false, true) => AnimationTriggeredEventsDirection::ForwardLooping
    (true, false) => AnimationTriggeredEventsDirection::Reverse
    (true, true) => AnimationTriggeredEventsDirection::ReverseLooping
  }

  match direction {
    Forward =>
      for event in events {
        if event.time >= last_time && (finished || event.time < this_time) {
          triggered.push(event)
        }
      }
    Reverse => {
      let mut i = events.length() - 1
      while i < events.length() {
        let event = events[i]
        if event.time <= last_time && (finished || event.time > this_time) {
          triggered.push(event)
        }
        if i == 0 {
          break
        }
        i = i - 1
      }
    }
    ForwardLooping => {
      for event in events {
        if event.time >= last_time {
          triggered.push(event)
        }
      }
      for event in events {
        if event.time < this_time {
          triggered.push(event)
        }
      }
    }
    ReverseLooping => {
      let mut i = events.length() - 1
      while i < events.length() {
        let event = events[i]
        if event.time <= last_time {
          triggered.push(event)
        }
        if i == 0 {
          break
        }
        i = i - 1
      }
      let mut j = events.length() - 1
      while j < events.length() {
        let event = events[j]
        if event.time > this_time {
          triggered.push(event)
        }
        if j == 0 {
          break
        }
        j = j - 1
      }
    }
  }

  triggered
}

///|
fn animation_emit_triggered_events(
  world : @ecs.World,
  writer : @core.MessageWriter[AnimationTriggeredEvent],
  player_entity : @core.Entity,
  target_entity : @core.Entity,
  target_id : AnimationTargetId?,
  active : ActiveAnimation,
  events : Array[AnimationClipEvent],
) -> Unit {
  for event in events {
    if event.callback_id is Some(callback_id) {
      if animation_event_callback_get(callback_id) is Some(callback) {
        callback(target_entity, event.time, active.weight())
      }
    }
    if event.typed_event_type_key is Some(type_key) &&
      event.typed_event_payload is Some(payload) {
      guard animation_typed_event_find_dispatcher(type_key) is Some(dispatch) else {
        abort("animation clip typed event dispatcher was not registered")
      }
      dispatch(world, payload, target_entity, Some("animation.trigger_events"))
    }
    writer.write({
      player: player_entity,
      target: target_entity,
      target_id,
      time: event.time,
      weight: active.weight(),
      label: event.label,
      payload: event.payload,
    })
  }
}

///|
pub fn animation_clip_event(
  time : Float,
  label : String,
  payload : String,
) -> AnimationClipEvent {
  AnimationClipEvent::new(time, label, payload)
}

///|
pub fn animation_clip_callback_event(
  time : Float,
  callback_id : Int,
) -> AnimationClipEvent {
  AnimationClipEvent::new_callback(time, callback_id)
}

///|
pub fn animation_register_clip_event_callback(
  callback : AnimationEventCallback,
) -> Int {
  animation_register_event_callback(callback)
}
