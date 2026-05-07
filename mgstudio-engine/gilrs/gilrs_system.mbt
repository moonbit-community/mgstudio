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
// Bevy source: `bevy/crates/bevy_gilrs/src/gilrs_system.rs`.
// Mgstudio polls the backend on-demand and maps events through `input/gamepad`.

///|
priv struct GilrsEventRuntimeState {
  mut startup_polled : Bool
  mut poll_count : Int
}

///|
let gilrs_event_runtime_state_ref : Ref[GilrsEventRuntimeState] = Ref(GilrsEventRuntimeState::{
  startup_polled: false,
  poll_count: 0,
})

///|
fn gilrs_poll_once() -> Unit {
  gamepad_poll()
  gilrs_event_runtime_state_ref.val.poll_count = gilrs_event_runtime_state_ref.val.poll_count +
    1
}

///|
pub fn gilrs_event_poll_count() -> Int {
  gilrs_event_runtime_state_ref.val.poll_count
}

///|
pub fn gilrs_event_reset_runtime_state() -> Unit {
  gilrs_event_runtime_state_ref.val.startup_polled = false
  gilrs_event_runtime_state_ref.val.poll_count = 0
}

///|
pub fn gilrs_event_startup_system() -> Unit {
  gilrs_event_runtime_state_ref.val.startup_polled = true
  gilrs_poll_once()
}

///|
pub fn gilrs_event_system() -> Unit {
  if !gilrs_event_runtime_state_ref.val.startup_polled {
    gilrs_event_startup_system()
    return
  }
  gilrs_poll_once()
}
