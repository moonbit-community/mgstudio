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
  trigger : AnimationEventTriggerFn?
}

///|
pub fn AnimationClipEvent::new(
  time : Float,
  label : String,
  payload : String,
) -> AnimationClipEvent {
  AnimationClipEvent::{ time, label, payload, trigger: None }
}

///|
pub type AnimationEventTriggerFn = (@ecs.World, @core.Entity, Float, Float) -> Unit

///|
pub fn AnimationClipEvent::new_callback(
  time : Float,
  trigger : AnimationEventTriggerFn,
) -> AnimationClipEvent {
  AnimationClipEvent::{ time, label: "", payload: "", trigger: Some(trigger) }
}

///|
pub fn[T : AnimationEvent + @ecs.TriggerEvent] AnimationClipEvent::new_typed(
  time : Float,
  event : T,
) -> AnimationClipEvent {
  event.animation_event_marker()
  let payload = @any.of(event)
  let trigger : AnimationEventTriggerFn = fn(
    world : @ecs.World,
    entity : @core.Entity,
    _time : Float,
    _weight : Float,
  ) {
    match payload.try_to() {
      Some(event_value) => {
        let event_ref : Ref[T] = Ref::new(event_value)
        T::set_observer_entity(event_ref, entity)
        world.trigger(
          event_ref.val,
          caller=Some("mgstudio.animation.trigger_events"),
        )
      }
      None => abort("animation clip typed event payload type mismatch")
    }
  }
  AnimationClipEvent::{ time, label: "", payload: "", trigger: Some(trigger) }
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
pub fn AnimationClipEvent::trigger(
  self : AnimationClipEvent,
) -> AnimationEventTriggerFn? {
  self.trigger
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
    if event.trigger is Some(trigger) {
      trigger(world, target_entity, event.time, active.weight())
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
  callback : AnimationEventTriggerFn,
) -> AnimationClipEvent {
  AnimationClipEvent::new_callback(time, callback)
}
