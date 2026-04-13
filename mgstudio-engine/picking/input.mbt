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
// Bevy source: `bevy/crates/bevy_picking/src/input.rs`.
/// Input collection systems.

///|
pub fn ensure_pointer_inputs_system(world : @ecs.World) -> Unit {
  let res = get_pointer_inputs_resource(world)
  if res.get() is None {
    res.insert(PointerInputs::default())
  }
}

///|
pub fn picking_collect_mouse_system(world : @ecs.World) -> Unit {
  let res = get_pointer_inputs_resource(world)
  guard res.get() is Some(inputs_value) else { return }
  let inputs = Ref::new(inputs_value)
  PointerInputs::clear(inputs)
  let pointer : @pointer_events.PointerId = 0
  let window_position = @input.mouse_position()
  let down = @input.mouse_button_pressed(@window.MouseButton::Left)
  let just_pressed = @input.mouse_button_just_pressed(@window.MouseButton::Left)
  let just_released = @input.mouse_button_just_released(
    @window.MouseButton::Left,
  )
  PointerInputs::push(
    inputs,
    PointerInput::new(
      pointer, window_position, down, just_pressed, just_released,
    ),
  )
  res.insert(inputs.val)
}
