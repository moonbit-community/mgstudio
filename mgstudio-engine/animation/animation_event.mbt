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
let animation_typed_event_dispatchers_bootstrap : Array[
  (String, (@ecs.World, @any.Any, @core.Entity, String?) -> Unit),
] = []

///|
pub type AnimationTypedEventDispatcher = (
  String,
  (@ecs.World, @any.Any, @core.Entity, String?) -> Unit,
)

///|
pub type AnimationEventCallback = (@core.Entity, Float, Float) -> Unit

///|
pub struct AnimationEventRuntimeState {
  typed_event_dispatchers : Array[AnimationTypedEventDispatcher]
  event_callbacks : Array[AnimationEventCallback]
}

///|
fn AnimationEventRuntimeState::from_bootstrap() -> AnimationEventRuntimeState {
  let typed_event_dispatchers : Array[AnimationTypedEventDispatcher] = []
  for entry in animation_typed_event_dispatchers_bootstrap {
    typed_event_dispatchers.push(entry)
  }
  let event_callbacks : Array[AnimationEventCallback] = []
  for callback in animation_event_callbacks_bootstrap {
    event_callbacks.push(callback)
  }
  AnimationEventRuntimeState::{ typed_event_dispatchers, event_callbacks }
}

///|
pub let ecs_key_animation_event_runtime_state : @ecs.ResourceKey[
  AnimationEventRuntimeState,
] = @ecs.register_resource(debug_name="animation.event_runtime_state")

///|
pub impl @app.Resource for AnimationEventRuntimeState with resource() {
  ecs_key_animation_event_runtime_state
}

///|
pub fn animation_event_runtime_plugin(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  if app.contains_resource(ecs_key_animation_event_runtime_state) {
    app
  } else {
    let next = app.insert_world_resource(
      ecs_key_animation_event_runtime_state,
      AnimationEventRuntimeState::from_bootstrap(),
    )
    animation_typed_event_dispatchers_bootstrap.clear()
    animation_event_callbacks_bootstrap.clear()
    next
  }
}

///|
fn animation_event_runtime_state_ref_if_present() -> Ref[
  AnimationEventRuntimeState,
]? {
  guard @app.current_world() is Some(world) else { return None }
  try! world.get_resource_ref_mut(ecs_key_animation_event_runtime_state)
}

///|
fn animation_typed_event_find_dispatcher_from(
  dispatchers : Array[AnimationTypedEventDispatcher],
  type_key : String,
) -> ((@ecs.World, @any.Any, @core.Entity, String?) -> Unit)? {
  for entry in dispatchers {
    if entry.0 == type_key {
      return Some(entry.1)
    }
  }
  None
}

///|
fn animation_typed_event_find_dispatcher(
  type_key : String,
) -> ((@ecs.World, @any.Any, @core.Entity, String?) -> Unit)? {
  if animation_event_runtime_state_ref_if_present() is Some(state_ref) {
    if animation_typed_event_find_dispatcher_from(
        state_ref.val.typed_event_dispatchers,
        type_key,
      )
      is Some(dispatch) {
      return Some(dispatch)
    }
  }
  animation_typed_event_find_dispatcher_from(
    animation_typed_event_dispatchers_bootstrap, type_key,
  )
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
  let dispatch : (@ecs.World, @any.Any, @core.Entity, String?) -> Unit = fn(
    world : @ecs.World,
    payload : @any.Any,
    entity : @core.Entity,
    caller : String?,
  ) {
    match payload.try_to() {
      Some(event_value) => {
        let event_ref : Ref[T] = Ref::new(event_value)
        T::set_observer_entity(event_ref, entity)
        world.trigger(event_ref.val, caller~)
      }
      None => abort("animation clip typed event payload type mismatch")
    }
  }
  if animation_event_runtime_state_ref_if_present() is Some(state_ref) {
    if animation_typed_event_find_dispatcher_from(
        state_ref.val.typed_event_dispatchers,
        type_key,
      )
      is None {
      state_ref.val.typed_event_dispatchers.push((type_key, dispatch))
    }
  } else if animation_typed_event_find_dispatcher_from(
      animation_typed_event_dispatchers_bootstrap, type_key,
    )
    is None {
    animation_typed_event_dispatchers_bootstrap.push((type_key, dispatch))
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
let animation_event_callbacks_bootstrap : Array[AnimationEventCallback] = []

///|
pub fn animation_register_event_callback(
  callback : AnimationEventCallback,
) -> Int {
  if animation_event_runtime_state_ref_if_present() is Some(state_ref) {
    state_ref.val.event_callbacks.push(callback)
    state_ref.val.event_callbacks.length() - 1
  } else {
    animation_event_callbacks_bootstrap.push(callback)
    animation_event_callbacks_bootstrap.length() - 1
  }
}

///|
fn animation_event_callback_get(callback_id : Int) -> AnimationEventCallback? {
  if animation_event_runtime_state_ref_if_present() is Some(state_ref) {
    if state_ref.val.event_callbacks.get(callback_id) is Some(callback) {
      return Some(callback)
    }
  }
  animation_event_callbacks_bootstrap.get(callback_id)
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
priv enum TriggeredEventsDirection {
  Forward
  Reverse
  ForwardLooping
  ReverseLooping
}

///|
priv struct TriggeredEvents {
  direction : TriggeredEventsDirection
  lower_start : Int
  lower_end : Int
  upper_start : Int
  upper_end : Int
}

///|
fn animation_clip_event_partition_point(
  events : Array[AnimationClipEvent],
  predicate : (AnimationClipEvent) -> Bool,
) -> Int {
  let mut left = 0
  let mut right = events.length()
  while left < right {
    let mid = left + (right - left) / 2
    if predicate(events[mid]) {
      left = mid + 1
    } else {
      right = mid
    }
  }
  left
}

///|
fn triggered_events_from_animation(
  events : Array[AnimationClipEvent],
  active : ActiveAnimation,
) -> TriggeredEvents? {
  if events.length() == 0 {
    return None
  }
  let reverse = active.is_playback_reversed()
  let is_finished = active.is_finished()
  if is_finished && !active.just_completed() {
    return None
  }
  guard active.last_seek_time is Some(last_time) else { return None }
  let this_time = active.seek_time()
  let looping = active.just_completed() && !is_finished
  let direction = match (reverse, looping) {
    (false, false) => TriggeredEventsDirection::Forward
    (false, true) => TriggeredEventsDirection::ForwardLooping
    (true, false) => TriggeredEventsDirection::Reverse
    (true, true) => TriggeredEventsDirection::ReverseLooping
  }

  match direction {
    Forward => {
      let start = animation_clip_event_partition_point(events, fn(event) {
        event.time < last_time
      })
      let end = if is_finished {
        events.length()
      } else {
        animation_clip_event_partition_point(events, fn(event) {
          event.time < this_time
        })
      }
      Some(TriggeredEvents::{
        direction,
        lower_start: start,
        lower_end: end,
        upper_start: 0,
        upper_end: 0,
      })
    }
    Reverse => {
      let end = animation_clip_event_partition_point(events, fn(event) {
        event.time <= last_time
      })
      let start = if is_finished {
        0
      } else {
        animation_clip_event_partition_point(events, fn(event) {
          event.time <= this_time
        })
      }
      Some(TriggeredEvents::{
        direction,
        lower_start: start,
        lower_end: end,
        upper_start: 0,
        upper_end: 0,
      })
    }
    ForwardLooping => {
      let upper_start = animation_clip_event_partition_point(events, fn(event) {
        event.time < last_time
      })
      let lower_end = animation_clip_event_partition_point(events, fn(event) {
        event.time < this_time
      })
      Some(TriggeredEvents::{
        direction,
        lower_start: 0,
        lower_end,
        upper_start,
        upper_end: events.length(),
      })
    }
    ReverseLooping => {
      let lower_end = animation_clip_event_partition_point(events, fn(event) {
        event.time <= last_time
      })
      let upper_start = animation_clip_event_partition_point(events, fn(event) {
        event.time <= this_time
      })
      Some(TriggeredEvents::{
        direction,
        lower_start: 0,
        lower_end,
        upper_start,
        upper_end: events.length(),
      })
    }
  }
}

///|
fn triggered_events_is_empty(triggered : TriggeredEvents) -> Bool {
  triggered.lower_start >= triggered.lower_end &&
  triggered.upper_start >= triggered.upper_end
}

///|
fn triggered_events_iter_collect(
  events : Array[AnimationClipEvent],
  triggered : TriggeredEvents,
) -> Array[AnimationClipEvent] {
  let ordered : Array[AnimationClipEvent] = []
  match triggered.direction {
    Forward => {
      let mut i = triggered.lower_start
      while i < triggered.lower_end {
        ordered.push(events[i])
        i = i + 1
      }
    }
    Reverse =>
      if triggered.lower_start < triggered.lower_end {
        let mut i = triggered.lower_end - 1
        while i >= triggered.lower_start {
          ordered.push(events[i])
          if i == 0 {
            break
          }
          i = i - 1
        }
      }
    ForwardLooping => {
      let mut i = triggered.upper_start
      while i < triggered.upper_end {
        ordered.push(events[i])
        i = i + 1
      }
      let mut j = triggered.lower_start
      while j < triggered.lower_end {
        ordered.push(events[j])
        j = j + 1
      }
    }
    ReverseLooping => {
      if triggered.lower_start < triggered.lower_end {
        let mut i = triggered.lower_end - 1
        while i >= triggered.lower_start {
          ordered.push(events[i])
          if i == 0 {
            break
          }
          i = i - 1
        }
      }
      if triggered.upper_start < triggered.upper_end {
        let mut j = triggered.upper_end - 1
        while j >= triggered.upper_start {
          ordered.push(events[j])
          if j == 0 {
            break
          }
          j = j - 1
        }
      }
    }
  }
  ordered
}

///|
fn animation_clip_collect_triggered_events(
  events : Array[AnimationClipEvent],
  active : ActiveAnimation,
) -> Array[AnimationClipEvent] {
  guard triggered_events_from_animation(events, active) is Some(triggered) else {
    return []
  }
  if triggered_events_is_empty(triggered) {
    return []
  }
  triggered_events_iter_collect(events, triggered)
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
