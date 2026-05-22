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
extenum @ecs.EcsPayload += {
  EcsPayload_app_FixedMainScheduleOrder(FixedMainScheduleOrder)
  EcsPayload_app_Stepping(Stepping)
  EcsPayload_app_DespawnOnExit(DespawnOnExit)
  EcsPayload_app_DespawnOnEnter(DespawnOnEnter)
  EcsPayload_app_HotPatchChanges(HotPatchChanges)
  EcsPayload_app_HotPatched(HotPatched)
  EcsPayload_app_PickingEvents(PickingEvents)
  EcsPayload_app_AppExit(AppExit)
  EcsPayload_app_MainScheduleOrder(MainScheduleOrder)
  EcsPayload_app_State(StatePayload)
  EcsPayload_app_PreviousState(StatePayload)
  EcsPayload_app_NextState(NextStatePayload)
  EcsPayload_app_StateTransitionEvent(StateTransitionEventPayload)
  EcsPayload_app_CheckParentHasComponent(CheckParentHasComponentPayload)
}

///|
pub impl @ecs.EcsPayloadCodec for Stepping with to_ecs_payload(self) {
  EcsPayload_app_Stepping(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Stepping with from_ecs_payload(payload) {
  match payload {
    EcsPayload_app_Stepping(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for DespawnOnExit with to_ecs_payload(self) {
  EcsPayload_app_DespawnOnExit(self)
}

///|
pub impl @ecs.EcsPayloadCodec for DespawnOnExit with from_ecs_payload(payload) {
  match payload {
    EcsPayload_app_DespawnOnExit(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for DespawnOnEnter with to_ecs_payload(self) {
  EcsPayload_app_DespawnOnEnter(self)
}

///|
pub impl @ecs.EcsPayloadCodec for DespawnOnEnter with from_ecs_payload(payload) {
  match payload {
    EcsPayload_app_DespawnOnEnter(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for HotPatchChanges with to_ecs_payload(self) {
  EcsPayload_app_HotPatchChanges(self)
}

///|
pub impl @ecs.EcsPayloadCodec for HotPatchChanges with from_ecs_payload(payload) {
  match payload {
    EcsPayload_app_HotPatchChanges(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for HotPatched with to_ecs_payload(self) {
  EcsPayload_app_HotPatched(self)
}

///|
pub impl @ecs.EcsPayloadCodec for HotPatched with from_ecs_payload(payload) {
  match payload {
    EcsPayload_app_HotPatched(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for PickingEvents with to_ecs_payload(self) {
  EcsPayload_app_PickingEvents(self)
}

///|
pub impl @ecs.EcsPayloadCodec for PickingEvents with from_ecs_payload(payload) {
  match payload {
    EcsPayload_app_PickingEvents(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for AppExit with to_ecs_payload(self) {
  EcsPayload_app_AppExit(self)
}

///|
pub impl @ecs.EcsPayloadCodec for AppExit with from_ecs_payload(payload) {
  match payload {
    EcsPayload_app_AppExit(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for MainScheduleOrder with to_ecs_payload(self) {
  EcsPayload_app_MainScheduleOrder(self)
}

///|
pub impl @ecs.EcsPayloadCodec for MainScheduleOrder with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_app_MainScheduleOrder(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for FixedMainScheduleOrder with to_ecs_payload(
  self,
) {
  EcsPayload_app_FixedMainScheduleOrder(self)
}

///|
pub impl @ecs.EcsPayloadCodec for FixedMainScheduleOrder with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_app_FixedMainScheduleOrder(value) => Some(value)
    _ => None
  }
}

///|
pub(all) struct StatePayload {
  value : @ecs.EcsPayload
}

///|
pub(all) struct NextStatePayload {
  tag : Int
  value : @ecs.EcsPayload?
}

///|
pub(all) struct StateTransitionEventPayload {
  exited : @ecs.EcsPayload?
  entered : @ecs.EcsPayload?
  allow_same_state_transitions : Bool
}

///|
pub(all) struct CheckParentHasComponentPayload {
  entity : @core.Entity
  caller : String?
}

///|
pub impl[S : @ecs.EcsPayloadCodec] @ecs.EcsPayloadCodec for State[S] with to_ecs_payload(
  self,
) {
  EcsPayload_app_State(StatePayload::{ value: S::to_ecs_payload(self.value) })
}

///|
pub impl[S : @ecs.EcsPayloadCodec] @ecs.EcsPayloadCodec for State[S] with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_app_State(state_payload) =>
      match S::from_ecs_payload(state_payload.value) {
        Some(value) => Some(State::{ value, })
        None => None
      }
    _ => None
  }
}

///|
pub impl[S : @ecs.EcsPayloadCodec] @ecs.EcsPayloadCodec for PreviousState[S] with to_ecs_payload(
  self,
) {
  EcsPayload_app_PreviousState(StatePayload::{
    value: S::to_ecs_payload(self.value),
  })
}

///|
pub impl[S : @ecs.EcsPayloadCodec] @ecs.EcsPayloadCodec for PreviousState[S] with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_app_PreviousState(state_payload) =>
      match S::from_ecs_payload(state_payload.value) {
        Some(value) => Some(PreviousState::{ value, })
        None => None
      }
    _ => None
  }
}

///|
pub impl[S : @ecs.EcsPayloadCodec] @ecs.EcsPayloadCodec for NextState[S] with to_ecs_payload(
  self,
) {
  let payload = match self {
    Unchanged => NextStatePayload::{ tag: 0, value: None }
    Pending(value) =>
      NextStatePayload::{ tag: 1, value: Some(S::to_ecs_payload(value)) }
    PendingIfNeq(value) =>
      NextStatePayload::{ tag: 2, value: Some(S::to_ecs_payload(value)) }
  }
  EcsPayload_app_NextState(payload)
}

///|
pub impl[S : @ecs.EcsPayloadCodec] @ecs.EcsPayloadCodec for NextState[S] with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_app_NextState(next_payload) =>
      match next_payload.tag {
        0 => Some(NextState::Unchanged)
        1 =>
          match next_payload.value {
            Some(value_payload) =>
              match S::from_ecs_payload(value_payload) {
                Some(value) => Some(NextState::Pending(value))
                None => None
              }
            None => None
          }
        2 =>
          match next_payload.value {
            Some(value_payload) =>
              match S::from_ecs_payload(value_payload) {
                Some(value) => Some(NextState::PendingIfNeq(value))
                None => None
              }
            None => None
          }
        _ => None
      }
    _ => None
  }
}

///|
pub impl[S : @ecs.EcsPayloadCodec] @ecs.EcsPayloadCodec for StateTransitionEvent[
  S,
] with to_ecs_payload(self) {
  EcsPayload_app_StateTransitionEvent(StateTransitionEventPayload::{
    exited: self.exited.map(fn(value) { S::to_ecs_payload(value) }),
    entered: self.entered.map(fn(value) { S::to_ecs_payload(value) }),
    allow_same_state_transitions: self.allow_same_state_transitions,
  })
}

///|
pub impl[S : @ecs.EcsPayloadCodec] @ecs.EcsPayloadCodec for StateTransitionEvent[
  S,
] with from_ecs_payload(payload) {
  match payload {
    EcsPayload_app_StateTransitionEvent(event_payload) => {
      let exited = match event_payload.exited {
        Some(value_payload) => S::from_ecs_payload(value_payload)
        None => None
      }
      let entered = match event_payload.entered {
        Some(value_payload) => S::from_ecs_payload(value_payload)
        None => None
      }
      Some(StateTransitionEvent::{
        exited,
        entered,
        allow_same_state_transitions: event_payload.allow_same_state_transitions,
      })
    }
    _ => None
  }
}

///|
pub impl[C] @ecs.EcsPayloadCodec for CheckParentHasComponent[C] with to_ecs_payload(
  self,
) {
  EcsPayload_app_CheckParentHasComponent(CheckParentHasComponentPayload::{
    entity: self.entity,
    caller: self.caller,
  })
}

///|
pub impl[C] @ecs.EcsPayloadCodec for CheckParentHasComponent[C] with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_app_CheckParentHasComponent(value) =>
      Some(CheckParentHasComponent::{
        entity: value.entity,
        caller: value.caller,
      })
    _ => None
  }
}
