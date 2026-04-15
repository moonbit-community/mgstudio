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
///
/// Features:
/// - Enter commits a bubble line and Backspace removes one character.
/// - Mouse left click toggles IME and updates IME cursor position.
/// - IME events (`Enabled`, `Disabled`, `Preedit`, `Commit`) update UI and edit text.
struct StatusTextHandles {
  ime_enabled : @core.Entity
  ime_active : @core.Entity
  ime_buffer : @core.Entity
}

///|
struct EditTextState {
  handle : @text.TextHandle
  font : @text.TextFont
}

///|
struct BubbleLine {
  handle : @text.TextHandle
  timer : @time.Timer
  y : Float
}

///|
let status_text_handles_ref : Ref[StatusTextHandles?] = Ref::new(None)

///|
let edit_text_state_ref : Ref[EditTextState?] = Ref::new(None)

///|
let bubble_lines_ref : Ref[Array[BubbleLine]] = Ref::new([])

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_systems(@app.Startup, @app.system(setup_scene))
  .add_systems(@app.Update, @app.system(@app.system_param(toggle_ime_system)))
  .add_systems(
    @app.Update,
    @app.system(@app.system_param(listen_ime_events_system)),
  )
  .add_systems(
    @app.Update,
    @app.system(@app.system_param(listen_keyboard_input_events_system)),
  )
  .add_systems(@app.Update, @app.system(bubbling_text_system))
  .run()
}

///|
fn setup_scene(world : @ecs.World) -> Unit {
  @sprite.Camera2dBundle::new(
    @sprite.Camera::default(),
    @transform.Transform::identity(),
  ).spawn(world)
  |> ignore

  let asset_server = @asset.AssetServer::new()
  let font = asset_server.load_font("fonts/FiraMono-Medium.ttf")
  let ui_font = @text.TextFont::default().with_font(font).with_font_size(30.0F)
  let edit_font = @text.TextFont::default()
    .with_font(font)
    .with_font_size(100.0F)

  let root = world.spawn_empty()
  try! world.set_by_key(root, @ui.ecs_key_ui_root, @ui.UiRoot::default())
  try! world.set_by_key(
    root,
    @ui.ecs_key_node,
    @ui.Node::default()
    .with_position_type(@ui.PositionType::Absolute)
    .with_top(@ui.Val::Px(12.0F))
    .with_left(@ui.Val::Px(12.0F))
    .with_flex_direction(@ui.FlexDirection::Column),
  )

  ignore(
    spawn_ui_text_line(
      world, root, "Click to toggle IME. Press return to start a new line.\n", ui_font,
    ),
  )
  ignore(spawn_ui_text_line(world, root, "\n", ui_font))

  let ime_enabled = spawn_ui_text_line(
    world, root, "IME Enabled: false\n", ui_font,
  )
  let ime_active = spawn_ui_text_line(
    world, root, "IME Active:  false\n", ui_font,
  )
  let ime_buffer = spawn_ui_text_line(world, root, "IME Buffer:  \n", ui_font)
  status_text_handles_ref.val = Some(StatusTextHandles::{
    ime_enabled,
    ime_active,
    ime_buffer,
  })

  let edit_handle = @text.Text2dBundle::new(
    @text.Text2d::new(""),
    edit_font,
    @transform.Transform::identity(),
  ).spawn()
  edit_text_state_ref.val = Some(EditTextState::{
    handle: edit_handle,
    font: edit_font,
  })
  bubble_lines_ref.val.clear()
}

///|
fn spawn_ui_text_line(
  world : @ecs.World,
  root : @core.Entity,
  content : String,
  font : @text.TextFont,
) -> @core.Entity {
  let text_entity = world.spawn_empty()
  try! world.set_by_key(
    text_entity,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(root),
  )
  try! world.set_by_key(text_entity, @ui.ecs_key_node, @ui.Node::default())
  try! world.set_by_key(
    text_entity,
    @text.ecs_key_text,
    @text.Text::new(content),
  )
  try! world.set_by_key(text_entity, @text.ecs_key_text_font, font)
  text_entity
}

///|
fn update_primary_window(
  world : @ecs.World,
  update : (@window.Window) -> Unit,
) -> Unit {
  try! world
  .query_entities_filtered(
    (
      @ecs.With::new(@window.ecs_key_window),
      @ecs.With::new(@window.ecs_key_primary_window),
    ),
  )
  .view(fn(_query_entity, entity) {
    guard (try! world.get_by_key(entity, @window.ecs_key_window))
      is Some(window) else {
      return
    }
    update(window)
    try! (world.replace(entity, @window.ecs_key_window, window) |> ignore)
  })
}

///|
fn set_ime_enabled_text(value : Bool) -> Unit {
  guard status_text_handles_ref.val is Some(handles) else { return }
  guard @app.current_world() is Some(world) else { return }
  guard (try! world.get_by_key(handles.ime_enabled, @text.ecs_key_text))
    is Some(text_value) else {
    return
  }
  text_value.content = "IME Enabled: \{value}\n"
  ignore(
    try! world.replace(handles.ime_enabled, @text.ecs_key_text, text_value),
  )
}

///|
fn set_ime_active_text(value : Bool) -> Unit {
  guard status_text_handles_ref.val is Some(handles) else { return }
  guard @app.current_world() is Some(world) else { return }
  guard (try! world.get_by_key(handles.ime_active, @text.ecs_key_text))
    is Some(text_value) else {
    return
  }
  text_value.content = "IME Active:  \{value}\n"
  ignore(try! world.replace(handles.ime_active, @text.ecs_key_text, text_value))
}

///|
fn set_ime_buffer_text(value : String) -> Unit {
  guard status_text_handles_ref.val is Some(handles) else { return }
  guard @app.current_world() is Some(world) else { return }
  guard (try! world.get_by_key(handles.ime_buffer, @text.ecs_key_text))
    is Some(text_value) else {
    return
  }
  text_value.content = "IME Buffer:  \{value}\n"
  ignore(try! world.replace(handles.ime_buffer, @text.ecs_key_text, text_value))
}

///|
fn edit_text_content() -> String {
  guard edit_text_state_ref.val is Some(edit_state) else { return "" }
  @text.text_get_content(edit_state.handle).unwrap_or("")
}

///|
fn set_edit_text_content(content : String) -> Unit {
  guard edit_text_state_ref.val is Some(edit_state) else { return }
  @text.text_set_content(edit_state.handle, content)
}

///|
fn append_edit_text(content : String) -> Unit {
  set_edit_text_content(edit_text_content() + content)
}

///|
fn toggle_ime_system(mouse : @input.ButtonInput[@window.MouseButton]) -> Unit {
  if !mouse.just_pressed(Left) {
    return
  }
  guard @app.current_world() is Some(world) else { return }
  guard @input.mouse_position() is Some(cursor_position) else { return }
  let ime_enabled : Ref[Bool?] = Ref::new(None)
  update_primary_window(world, fn(window) {
    window.ime_position = cursor_position
    window.ime_enabled = !window.ime_enabled
    ime_enabled.val = Some(window.ime_enabled)
  })
  if ime_enabled.val is Some(value) {
    set_ime_enabled_text(value)
  }
}

///|
fn listen_ime_events_system(
  ime_reader : @ecs.MessageReader[@window.Ime],
) -> Unit {
  for ime in (try! ime_reader.read()) {
    match ime {
      Enabled(_) => set_ime_active_text(true)
      Disabled(_) => set_ime_active_text(false)
      Preedit(_, value, cursor) =>
        if cursor is Some(_) {
          set_ime_buffer_text(value)
        } else {
          set_ime_buffer_text("")
        }
      Commit(_, value) => append_edit_text(value)
      DeleteSurrounding(_, _, _) => ()
    }
  }
}

///|
fn listen_keyboard_input_events_system(
  keyboard_inputs : @ecs.MessageReader[@input.KeyboardInput],
) -> Unit {
  for keyboard_input in (try! keyboard_inputs.read()) {
    if !keyboard_input.state.is_pressed() {
      continue
    }
    match keyboard_input.logical_key {
      @input.Key::Enter => commit_text_line()
      @input.Key::Backspace => remove_last_character()
      _ =>
        if keyboard_input.text is Some(inserted_text) &&
          is_printable_text(inserted_text) {
          append_edit_text(inserted_text)
        }
    }
  }
}

///|
fn bubbling_text_system(world : @ecs.World) -> Unit {
  if bubble_lines_ref.val.length() == 0 {
    return
  }
  let time : @time.Time[Unit] = match
    (try! world.get_resource(@time.default_time_resource_key())) {
    Some(time) => time
    None => abort("Missing Time<Unit> resource in text_input example")
  }
  let delta = time.delta()
  let delta_seconds = time.delta_seconds()
  let next_lines : Array[BubbleLine] = []
  for bubble_line in bubble_lines_ref.val {
    let next_timer = bubble_line.timer.tick(delta)
    if next_timer.just_finished() {
      @text.text_despawn(bubble_line.handle) |> ignore
      continue
    }
    let next_y = bubble_line.y + delta_seconds * 100.0F
    @text.text_set_transform(
      bubble_line.handle,
      @transform.Transform::from_xyz(0.0F, next_y, 0.0F),
    )
    next_lines.push(BubbleLine::{
      handle: bubble_line.handle,
      timer: next_timer,
      y: next_y,
    })
  }
  bubble_lines_ref.val = next_lines
}

///|
fn commit_text_line() -> Unit {
  guard edit_text_state_ref.val is Some(edit_state) else { return }
  let committed = edit_text_content()
  if committed == "" {
    return
  }
  let handle = @text.Text2dBundle::new(
    @text.Text2d::new(committed),
    edit_state.font,
    @transform.Transform::identity(),
  ).spawn()
  bubble_lines_ref.val.push(BubbleLine::{
    handle,
    timer: @time.Timer::from_seconds(5.0F, @time.TimerMode::Once),
    y: 0.0F,
  })
  set_edit_text_content("")
}

///|
fn remove_last_character() -> Unit {
  let text = edit_text_content()
  if text == "" {
    return
  }
  let chars : Array[Char] = []
  for ch in text {
    chars.push(ch)
  }
  if chars.length() == 0 {
    return
  }
  chars.pop() |> ignore
  if chars.length() > 0 {
    set_edit_text_content(String::from_array(chars))
  } else {
    set_edit_text_content("")
  }
}

///|
fn is_printable_char(ch : Char) -> Bool {
  let code_point = ch.to_int()
  let is_private_use = (code_point >= 0xE000 && code_point <= 0xF8FF) ||
    (code_point >= 0xF0000 && code_point <= 0xFFFFD) ||
    (code_point >= 0x100000 && code_point <= 0x10FFFD)
  !is_private_use && !(code_point < 0x20 || code_point == 0x7F)
}

///|
fn is_printable_text(text : String) -> Bool {
  if text.length() == 0 {
    return false
  }
  for ch in text {
    if !is_printable_char(ch) {
      return false
    }
  }
  true
}
