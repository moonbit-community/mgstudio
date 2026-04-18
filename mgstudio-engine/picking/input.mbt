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
pub struct PointerInputSettings {
  is_touch_enabled : Bool
  is_mouse_enabled : Bool
} derive(Eq, Debug, ToJson, FromJson)

///|
pub fn PointerInputSettings::default() -> PointerInputSettings {
  PointerInputSettings::{ is_touch_enabled: true, is_mouse_enabled: true }
}

///|
pub fn PointerInputSettings::new(
  is_touch_enabled : Bool,
  is_mouse_enabled : Bool,
) -> PointerInputSettings {
  PointerInputSettings::{ is_touch_enabled, is_mouse_enabled }
}

///|
pub impl @app.Resource for PointerInputSettings with resource() {
  ecs_res_key_pointer_input_settings
}

///|
fn picking_pointer_input_settings(world : @ecs.World) -> PointerInputSettings {
  match get_pointer_input_settings_resource(world).get() {
    Some(settings) => settings
    None => PointerInputSettings::default()
  }
}

///|
fn picking_pointer_from_touch_id(touch_id : Int) -> @pointer_events.PointerId {
  if touch_id >= 0 {
    touch_id + 1
  } else {
    1
  }
}

///|
pub fn ensure_pointer_inputs_system(world : @ecs.World) -> Unit {
  let res = get_pointer_inputs_resource(world)
  if res.get() is None {
    res.insert(PointerInputs::default())
  }
}

///|
pub fn ensure_pointer_input_settings_system(world : @ecs.World) -> Unit {
  let res = get_pointer_input_settings_resource(world)
  if res.get() is None {
    res.insert(PointerInputSettings::default())
  }
}

///|
pub fn picking_collect_mouse_system(world : @ecs.World) -> Unit {
  let res = get_pointer_inputs_resource(world)
  guard res.get() is Some(inputs_value) else { return }
  let inputs = Ref::new(inputs_value)
  PointerInputs::clear(inputs)
  let settings = picking_pointer_input_settings(world)
  if settings.is_mouse_enabled {
    let pointer : @pointer_events.PointerId = 0
    let window_position = @input.mouse_position()
    let down = @input.mouse_button_pressed(@window.MouseButton::Left)
    let just_pressed = @input.mouse_button_just_pressed(
      @window.MouseButton::Left,
    )
    let just_released = @input.mouse_button_just_released(
      @window.MouseButton::Left,
    )
    PointerInputs::set(
      inputs,
      PointerInput::new(
        pointer, window_position, down, just_pressed, just_released,
      ),
    )
  }
  if settings.is_touch_enabled {
    let touches_opt = try world.get_resource(@input.Touches::resource()) catch {
      _ => None
    } noraise {
      value => value
    }
    match touches_opt {
      Some(touches) => {
        for touch in touches.iter() {
          let pointer = picking_pointer_from_touch_id(touch.id())
          PointerInputs::set(
            inputs,
            PointerInput::new(
              pointer,
              Some(touch.position()),
              true,
              false,
              false,
            ),
          )
        }
        for touch in touches.iter_just_pressed() {
          let pointer = picking_pointer_from_touch_id(touch.id())
          PointerInputs::set(
            inputs,
            PointerInput::new(
              pointer,
              Some(touch.position()),
              true,
              true,
              false,
            ),
          )
        }
        for touch in touches.iter_just_released() {
          let pointer = picking_pointer_from_touch_id(touch.id())
          PointerInputs::set(
            inputs,
            PointerInput::new(
              pointer,
              Some(touch.position()),
              false,
              false,
              true,
            ),
          )
        }
        for touch in touches.iter_just_canceled() {
          let pointer = picking_pointer_from_touch_id(touch.id())
          PointerInputs::set(
            inputs,
            PointerInput::new(
              pointer,
              Some(touch.position()),
              false,
              false,
              true,
            ),
          )
        }
      }
      None => ()
    }
  }
  res.insert(inputs.val)
}
