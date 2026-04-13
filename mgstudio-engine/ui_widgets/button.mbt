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
// Bevy source: `bevy/crates/bevy_ui_widgets/src/button.rs`.
pub using @ui {type Button}

///|
pub using @ui {type ButtonColors}

///|
pub let ecs_key_button : @ecs.ComponentKey[@ui.Button] = @ui.ecs_key_button

///|
pub let ecs_key_button_colors : @ecs.ComponentKey[@ui.ButtonColors] = @ui.ecs_key_button_colors

///|
fn button_on_key_input(
  keyboard : @input.ButtonInput[@window.KeyCode],
  focus : @app.Res[@input_focus.InputFocus],
  button_query : @ecs.Query[
    (@ecs.Has[Button], @ecs.Has[InteractionDisabled]),
    @ecs.All,
  ],
  commands : @app.Commands,
) -> Unit {
  if !keyboard.just_pressed(@window.KeyCode::Enter) &&
    !keyboard.just_pressed(@window.KeyCode::Space) {
    return
  }
  guard focus.get().get() is Some(entity) else { return }
  guard (button_query.get(entity) catch { _ => None })
    is Some((is_button, disabled)) else {
    return
  }
  if !is_button.present() || disabled.present() {
    return
  }
  commands.trigger(Activate::{ entity, })
}

///|
fn button_on_pointer_down(
  pointer : @app.OnPointer[@app.PointerDown],
  button_query : @ecs.Query[
    (@ecs.Has[Button], @ecs.Has[InteractionDisabled]),
    @ecs.All,
  ],
  commands : @app.Commands,
) -> Unit {
  guard pointer.target() is Some(entity) else { return }
  guard (button_query.get(entity) catch { _ => None })
    is Some((is_button, disabled)) else {
    return
  }
  if !is_button.present() || disabled.present() {
    return
  }
  commands.entity(entity).insert_component(Pressed::{  })
}

///|
fn button_clear_pressed(
  entity : @core.Entity,
  pressed_query : @ecs.Query[(@ecs.Has[Button], @ecs.Has[Pressed]), @ecs.All],
  commands : @app.Commands,
) -> Unit {
  guard (pressed_query.get(entity) catch { _ => None })
    is Some((is_button, pressed)) else {
    return
  }
  if !is_button.present() || !pressed.present() {
    return
  }
  commands.entity(entity).remove_component(ecs_key_pressed)
}

///|
fn button_on_pointer_up(
  pointer : @app.OnPointer[@app.PointerUp],
  pressed_query : @ecs.Query[(@ecs.Has[Button], @ecs.Has[Pressed]), @ecs.All],
  commands : @app.Commands,
) -> Unit {
  guard pointer.target() is Some(entity) else { return }
  button_clear_pressed(entity, pressed_query, commands)
}

///|
fn button_on_pointer_leave(
  pointer : @app.OnPointer[@app.PointerLeave],
  pressed_query : @ecs.Query[(@ecs.Has[Button], @ecs.Has[Pressed]), @ecs.All],
  commands : @app.Commands,
) -> Unit {
  guard pointer.target() is Some(entity) else { return }
  button_clear_pressed(entity, pressed_query, commands)
}

///|
fn button_on_pointer_click(
  pointer : @app.OnPointer[@app.PointerClick],
  button_query : @ecs.Query[
    (@ecs.Has[Button], @ecs.Has[InteractionDisabled]),
    @ecs.All,
  ],
  commands : @app.Commands,
) -> Unit {
  guard pointer.target() is Some(entity) else { return }
  guard (button_query.get(entity) catch { _ => None })
    is Some((is_button, disabled)) else {
    return
  }
  if !is_button.present() || disabled.present() {
    return
  }
  commands.trigger(Activate::{ entity, })
}

///|
pub fn button_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  app
  .add_systems(
    @app.Update,
    @app.system(@app.system_param4(button_on_key_input)),
  )
  .add_pointer_observer3(button_on_pointer_down)
  .add_pointer_observer3(button_on_pointer_up)
  .add_pointer_observer3(button_on_pointer_leave)
  .add_pointer_observer3(button_on_pointer_click)
}
