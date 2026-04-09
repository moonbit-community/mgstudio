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
// Bevy source: `bevy/crates/bevy_picking/src/pointer.rs`.
/// Pointer input/button types and pointer-focused helpers.

///|
pub struct PointerInput {
  pointer : @pointer_events.PointerId
  window_position : @math.Vec2?
  down : Bool
  just_pressed : Bool
  just_released : Bool
} derive(ToJson, FromJson)

///|
pub fn PointerInput::new(
  pointer : @pointer_events.PointerId,
  window_position : @math.Vec2?,
  down : Bool,
  just_pressed : Bool,
  just_released : Bool,
) -> PointerInput {
  PointerInput::{ pointer, window_position, down, just_pressed, just_released }
}

///|
/// Per-frame pointer inputs captured from the runtime/input layer.
pub struct PointerInputs {
  mut pointers : Array[PointerInput]
} derive(ToJson, FromJson)

///|
pub fn PointerInputs::default() -> PointerInputs {
  PointerInputs::{ pointers: [] }
}

///|
pub fn PointerInputs::from_array(
  pointers : Array[PointerInput],
) -> PointerInputs {
  PointerInputs::{ pointers, }
}

///|
pub fn PointerInputs::clear(self : Ref[PointerInputs]) -> Unit {
  self.val.pointers.clear()
}

///|
pub fn PointerInputs::push(
  self : Ref[PointerInputs],
  input : PointerInput,
) -> Unit {
  self.val.pointers = self.val.pointers + [input]
}

///|
pub(all) enum PointerButton {
  Primary
  Secondary
  Middle
} derive(Eq, Show)

///|
pub impl @app.Resource for PointerInputs with resource() {
  ecs_res_key_pointer_inputs
}
