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
pub fn any_to_string_export(value : @js.Any) -> String {
  any_to_string(value)
}

///|
pub fn create_host(
  canvas_opt : @dom.Element?,
  assets_source_spec : String,
  data_source_spec : String,
) -> @js.Any {
  let assets_source : @rtcore.SourceSpec = @rtcore.parse_url_source(
    Some(assets_source_spec),
    "./_mgstudio_assets/",
  ) catch {
    _ => @rtcore.url_source("./_mgstudio_assets/")
  }
  let data_source : @rtcore.SourceSpec = @rtcore.parse_idb_source(
    Some(data_source_spec),
    "mgstudio",
  ) catch {
    _ => @rtcore.idb_source("mgstudio")
  }
  let state = new_state(assets_source, data_source)
  state.gpu.profile_enabled = url_search_param_enabled("mg_profile")
  if state.gpu.profile_enabled {
    console_error(
      @js.any("mgstudio-runtime-web profile enabled (mg_profile=1)"),
    )
  }
  @js.log(
    @js.any(
      "mgstudio-runtime-web assets-source=" +
      state.assets_source.base +
      " data-source=" +
      state.data_source.base,
    ),
  )
  let default_canvas = ensure_canvas(canvas_opt)
  let window_create = @js.from_fn3(fn(width, height, title) {
    let target = default_canvas
    prepare_canvas_for_input(target)
    let width_num = to_int(number_or(width, 800))
    let height_num = to_int(number_or(height, 600))
    target._set("width", @js.any(width_num)) |> ignore
    target._set("height", @js.any(height_num)) |> ignore
    let text = string_from_id_optional(state, title)
    set_document_title_js(text)
    let size = get_canvas_pixel_size(target)
    let pixel_width : Int = size._get("width").cast()
    let pixel_height : Int = size._get("height").cast()
    let scale_factor = get_device_pixel_ratio()
    set_canvas_target_pixel_size(target, pixel_width, pixel_height)
    state.window = Some(WindowState::{
      canvas: target,
      width: pixel_width,
      height: pixel_height,
      scale_factor,
      position_x: window_screen_x_js(),
      position_y: window_screen_y_js(),
    })
    init_input(state)
    bind_pointer_events(state, target)
    set_canvas_cursor_visible_js(target, true)
    1
  })
  let window_poll_events = @js.from_fn1(fn(_ : @js.Any) { () })
  let window_get_width = @js.from_fn1(fn(_ : @js.Any) {
    update_window_size(state)
    if state.window is Some(window_state) {
      window_state.width
    } else {
      0
    }
  })
  let window_get_height = @js.from_fn1(fn(_ : @js.Any) {
    update_window_size(state)
    if state.window is Some(window_state) {
      window_state.height
    } else {
      0
    }
  })
  let window_get_scale_factor = @js.from_fn1(fn(_ : @js.Any) {
    update_window_size(state)
    if state.window is Some(window_state) {
      window_state.scale_factor
    } else {
      1.0
    }
  })
  let window_should_close = @js.from_fn1(fn(_ : @js.Any) { state.should_close })
  let window_request_close = @js.from_fn1(fn(_ : @js.Any) {
    state.should_close = true
  })
  let window_run_loop = @js.from_fn1(fn(step : @js.Any) {
    fn tick() {
      if state.should_close {
        return
      }
      host_call0_any(step) |> ignore
      request_animation_frame(@js.from_fn0(fn() { tick() }))
    }

    request_animation_frame(@js.from_fn0(fn() { tick() }))
  })
  let window_set_title = @js.from_fn2(fn(_ : @js.Any, title_any : @js.Any) {
    let text = string_from_id_optional(state, title_any)
    set_document_title_js(text)
    0
  })
  let window_set_size = @js.from_fn3(fn(
    _ : @js.Any,
    width_any : @js.Any,
    height_any : @js.Any,
  ) {
    if state.window is Some(window_state) {
      let width_int = to_int(
        number_or(width_any, window_state.width.to_double()),
      )
      let height_int = to_int(
        number_or(height_any, window_state.height.to_double()),
      )
      let target_width = if width_int > 0 { width_int } else { 1 }
      let target_height = if height_int > 0 { height_int } else { 1 }
      set_canvas_target_pixel_size(
        window_state.canvas,
        target_width,
        target_height,
      )
      update_window_size(state)
    }
    0
  })
  let window_set_resizable = @js.from_fn2(fn(
    _ : @js.Any,
    _resizable_any : @js.Any,
  ) {
    // Browser canvases are intrinsically "resizable" with layout/CSS; keep this
    // import as a no-op for ABI parity.
    state.window |> ignore
    0
  })
  let window_set_cursor_visible = @js.from_fn2(fn(
    _ : @js.Any,
    visible_any : @js.Any,
  ) {
    if state.window is Some(window_state) {
      let visible = number_or(visible_any, 0) != 0
      set_canvas_cursor_visible_js(window_state.canvas, visible)
    }
    0
  })
  let window_set_cursor_grab_mode = @js.from_fn2(fn(
    _ : @js.Any,
    mode_any : @js.Any,
  ) {
    if state.window is Some(window_state) {
      let mut mode = to_int(number_or(mode_any, 0))
      if mode < 0 {
        mode = 0
      }
      if mode > 2 {
        mode = 2
      }
      set_canvas_cursor_grab_mode_js(window_state.canvas, mode)
    }
    0
  })
  let window_set_mode = @js.from_fn2(fn(_ : @js.Any, mode_any : @js.Any) {
    if state.window is Some(window_state) {
      let mut mode = to_int(number_or(mode_any, 0))
      if mode < 0 {
        mode = 0
      }
      if mode > 2 {
        mode = 2
      }
      set_window_mode_js(window_state.canvas, mode)
    }
    0
  })
  let window_set_position = @js.from_fn3(fn(
    _ : @js.Any,
    x_any : @js.Any,
    y_any : @js.Any,
  ) {
    if state.window is Some(window_state) {
      let x = to_int(number_or(x_any, window_state.position_x.to_double()))
      let y = to_int(number_or(y_any, window_state.position_y.to_double()))
      window_state.position_x = x
      window_state.position_y = y
      window_move_to_js(x, y)
    }
    0
  })
  let window_get_position_x = @js.from_fn1(fn(_ : @js.Any) {
    if state.window is Some(window_state) {
      let x = window_screen_x_js()
      window_state.position_x = x
      x
    } else {
      0
    }
  })
  let window_get_position_y = @js.from_fn1(fn(_ : @js.Any) {
    if state.window is Some(window_state) {
      let y = window_screen_y_js()
      window_state.position_y = y
      y
    } else {
      0
    }
  })
  let time_now = @js.from_fn0(fn() { performance_now() })
  fn find_gamepad(gamepad_id : Int) -> GamepadSnapshot? {
    for gamepad in state.input.gamepads {
      if gamepad.id == gamepad_id {
        return Some(gamepad)
      }
    }
    None
  }
  fn value_or_nan(values : Array[Double], index : Int) -> Double {
    if index >= 0 && index < values.length() {
      values[index]
    } else {
      0.0 / 0.0
    }
  }
  fn value_or_zero(value : Double) -> Double {
    if value != value {
      0.0
    } else {
      value
    }
  }
  fn pressed_or_false(values : Array[Bool], index : Int) -> Bool {
    if index >= 0 && index < values.length() {
      values[index]
    } else {
      false
    }
  }
  fn gamepad_button_value(gamepad : GamepadSnapshot, button : Int) -> Double {
    match button {
      0 => value_or_nan(gamepad.button_values, 0)
      1 => value_or_nan(gamepad.button_values, 1)
      3 => value_or_nan(gamepad.button_values, 3)
      4 => value_or_nan(gamepad.button_values, 2)
      6 => value_or_nan(gamepad.button_values, 4)
      7 => value_or_nan(gamepad.button_values, 5)
      8 => value_or_nan(gamepad.button_values, 6)
      9 => value_or_nan(gamepad.button_values, 7)
      10 => value_or_nan(gamepad.button_values, 8)
      11 => value_or_nan(gamepad.button_values, 9)
      12 => value_or_nan(gamepad.button_values, 16)
      13 => value_or_nan(gamepad.button_values, 10)
      14 => value_or_nan(gamepad.button_values, 11)
      15 => value_or_nan(gamepad.button_values, 12)
      16 => value_or_nan(gamepad.button_values, 13)
      17 => value_or_nan(gamepad.button_values, 14)
      18 => value_or_nan(gamepad.button_values, 15)
      _ => 0.0 / 0.0
    }
  }
  fn gamepad_button_pressed(gamepad : GamepadSnapshot, button : Int) -> Bool {
    match button {
      0 => pressed_or_false(gamepad.button_pressed, 0)
      1 => pressed_or_false(gamepad.button_pressed, 1)
      3 => pressed_or_false(gamepad.button_pressed, 3)
      4 => pressed_or_false(gamepad.button_pressed, 2)
      6 => pressed_or_false(gamepad.button_pressed, 4)
      7 => pressed_or_false(gamepad.button_pressed, 5)
      8 => pressed_or_false(gamepad.button_pressed, 6)
      9 => pressed_or_false(gamepad.button_pressed, 7)
      10 => pressed_or_false(gamepad.button_pressed, 8)
      11 => pressed_or_false(gamepad.button_pressed, 9)
      12 => pressed_or_false(gamepad.button_pressed, 16)
      13 => pressed_or_false(gamepad.button_pressed, 10)
      14 => pressed_or_false(gamepad.button_pressed, 11)
      15 => pressed_or_false(gamepad.button_pressed, 12)
      16 => pressed_or_false(gamepad.button_pressed, 13)
      17 => pressed_or_false(gamepad.button_pressed, 14)
      18 => pressed_or_false(gamepad.button_pressed, 15)
      _ => false
    }
  }
  fn gamepad_axis_value(gamepad : GamepadSnapshot, axis : Int) -> Double {
    match axis {
      0 => value_or_nan(gamepad.axis_values, 0)
      1 => value_or_nan(gamepad.axis_values, 1)
      2 => gamepad_button_value(gamepad, 8)
      3 => value_or_nan(gamepad.axis_values, 2)
      4 => value_or_nan(gamepad.axis_values, 3)
      5 => gamepad_button_value(gamepad, 9)
      6 => {
        let right = value_or_zero(gamepad_button_value(gamepad, 18))
        let left = value_or_zero(gamepad_button_value(gamepad, 17))
        right - left
      }
      7 => {
        let up = value_or_zero(gamepad_button_value(gamepad, 15))
        let down = value_or_zero(gamepad_button_value(gamepad, 16))
        up - down
      }
      _ => 0.0 / 0.0
    }
  }
  let input_gamepad_poll = @js.from_fn0(fn() { poll_gamepads(state) })
  let input_gamepad_count = @js.from_fn0(fn() { state.input.gamepads.length() })
  let input_gamepad_id = @js.from_fn1(fn(index_any : @js.Any) {
    let index = to_int(number_or(index_any, -1))
    if index >= 0 && index < state.input.gamepads.length() {
      state.input.gamepads[index].id
    } else {
      -1
    }
  })
  let input_gamepad_connected = @js.from_fn1(fn(gamepad_id_any : @js.Any) {
    let gamepad_id = to_int(number_or(gamepad_id_any, -1))
    find_gamepad(gamepad_id) is Some(_)
  })
  let input_gamepad_name_len = @js.from_fn1(fn(gamepad_id_any : @js.Any) {
    let gamepad_id = to_int(number_or(gamepad_id_any, -1))
    if find_gamepad(gamepad_id) is Some(gamepad) {
      gamepad.name.length()
    } else {
      0
    }
  })
  let input_gamepad_name_code_unit = @js.from_fn2(fn(
    gamepad_id_any : @js.Any,
    offset_any : @js.Any,
  ) {
    let gamepad_id = to_int(number_or(gamepad_id_any, -1))
    let offset = to_int(number_or(offset_any, -1))
    if find_gamepad(gamepad_id) is Some(gamepad) &&
      offset >= 0 &&
      offset < gamepad.name.length() {
      gamepad.name.code_unit_at(offset).to_int()
    } else {
      0
    }
  })
  let input_gamepad_vendor_id = @js.from_fn1(fn(gamepad_id_any : @js.Any) {
    let gamepad_id = to_int(number_or(gamepad_id_any, -1))
    if find_gamepad(gamepad_id) is Some(gamepad) {
      gamepad.vendor_id.unwrap_or(-1)
    } else {
      -1
    }
  })
  let input_gamepad_product_id = @js.from_fn1(fn(gamepad_id_any : @js.Any) {
    let gamepad_id = to_int(number_or(gamepad_id_any, -1))
    if find_gamepad(gamepad_id) is Some(gamepad) {
      gamepad.product_id.unwrap_or(-1)
    } else {
      -1
    }
  })
  let input_gamepad_button_value = @js.from_fn2(fn(
    gamepad_id_any : @js.Any,
    button_any : @js.Any,
  ) {
    let gamepad_id = to_int(number_or(gamepad_id_any, -1))
    let button = to_int(number_or(button_any, -1))
    if find_gamepad(gamepad_id) is Some(gamepad) {
      gamepad_button_value(gamepad, button)
    } else {
      0.0 / 0.0
    }
  })
  let input_gamepad_button_pressed = @js.from_fn2(fn(
    gamepad_id_any : @js.Any,
    button_any : @js.Any,
  ) {
    let gamepad_id = to_int(number_or(gamepad_id_any, -1))
    let button = to_int(number_or(button_any, -1))
    if find_gamepad(gamepad_id) is Some(gamepad) {
      gamepad_button_pressed(gamepad, button)
    } else {
      false
    }
  })
  let input_gamepad_axis_value = @js.from_fn2(fn(
    gamepad_id_any : @js.Any,
    axis_any : @js.Any,
  ) {
    let gamepad_id = to_int(number_or(gamepad_id_any, -1))
    let axis = to_int(number_or(axis_any, -1))
    if find_gamepad(gamepad_id) is Some(gamepad) {
      gamepad_axis_value(gamepad, axis)
    } else {
      0.0 / 0.0
    }
  })
  let input_is_key_down = @js.from_fn1(fn(code) {
    let text = string_from_id_required(state, code, "input_is_key_down")
    set_has(state.input.pressed, @js.any(text))
  })
  let input_is_key_just_pressed = @js.from_fn1(fn(code) {
    let text = string_from_id_required(state, code, "input_is_key_just_pressed")
    set_has(state.input.just_pressed, @js.any(text))
  })
  let input_is_key_just_released = @js.from_fn1(fn(code) {
    let text = string_from_id_required(
      state, code, "input_is_key_just_released",
    )
    set_has(state.input.just_released, @js.any(text))
  })
  let input_is_key_repeated = @js.from_fn1(fn(code) {
    let text = string_from_id_required(state, code, "input_is_key_repeated")
    set_has(state.input.repeated, @js.any(text))
  })
  let input_text_event_count = @js.from_fn0(fn() {
    state.input.text_events.length()
  })
  let input_text_event_len = @js.from_fn1(fn(index_any : @js.Any) {
    let index = to_int(number_or(index_any, -1))
    if index >= 0 && index < state.input.text_events.length() {
      state.input.text_events[index].length()
    } else {
      0
    }
  })
  let input_text_event_code_unit = @js.from_fn2(fn(
    index_any : @js.Any,
    offset_any : @js.Any,
  ) {
    let index = to_int(number_or(index_any, -1))
    let offset = to_int(number_or(offset_any, -1))
    if index >= 0 && index < state.input.text_events.length() {
      let text = state.input.text_events[index]
      if offset >= 0 && offset < text.length() {
        text.code_unit_at(offset).to_int()
      } else {
        0
      }
    } else {
      0
    }
  })
  let input_finish_frame = @js.from_fn0(fn() {
    set_clear(state.input.just_pressed)
    set_clear(state.input.just_released)
    set_clear(state.input.repeated)
    state.input.text_events.clear()
    set_clear(state.input.mouse_just_pressed)
    set_clear(state.input.mouse_just_released)
    state.input.wheel_x = 0.0
    state.input.wheel_y = 0.0
    state.input.touch_events.clear()
  })
  let input_is_mouse_button_down = @js.from_fn1(fn(name) {
    let text = string_from_id_required(
      state, name, "input_is_mouse_button_down",
    )
    set_has(state.input.mouse_buttons, @js.any(text))
  })
  let input_is_mouse_button_just_pressed = @js.from_fn1(fn(name) {
    let text = string_from_id_required(
      state, name, "input_is_mouse_button_just_pressed",
    )
    set_has(state.input.mouse_just_pressed, @js.any(text))
  })
  let input_is_mouse_button_just_released = @js.from_fn1(fn(name) {
    let text = string_from_id_required(
      state, name, "input_is_mouse_button_just_released",
    )
    set_has(state.input.mouse_just_released, @js.any(text))
  })
  let input_mouse_x = @js.from_fn0(fn() { state.input.mouse_x })
  let input_mouse_y = @js.from_fn0(fn() { state.input.mouse_y })
  let input_wheel_x = @js.from_fn0(fn() { state.input.wheel_x })
  let input_wheel_y = @js.from_fn0(fn() { state.input.wheel_y })
  let input_has_cursor = @js.from_fn0(fn() { state.input.has_cursor })
  let input_touch_event_count = @js.from_fn0(fn() {
    state.input.touch_events.length()
  })
  let input_touch_event_id = @js.from_fn1(fn(index_any : @js.Any) {
    let index = to_int(number_or(index_any, -1))
    if index >= 0 && index < state.input.touch_events.length() {
      state.input.touch_events[index].id
    } else {
      -1
    }
  })
  let input_touch_event_phase = @js.from_fn1(fn(index_any : @js.Any) {
    let index = to_int(number_or(index_any, -1))
    if index >= 0 && index < state.input.touch_events.length() {
      state.input.touch_events[index].phase
    } else {
      3
    }
  })
  let input_touch_event_x = @js.from_fn1(fn(index_any : @js.Any) {
    let index = to_int(number_or(index_any, -1))
    if index >= 0 && index < state.input.touch_events.length() {
      state.input.touch_events[index].x
    } else {
      0.0
    }
  })
  let input_touch_event_y = @js.from_fn1(fn(index_any : @js.Any) {
    let index = to_int(number_or(index_any, -1))
    if index >= 0 && index < state.input.touch_events.length() {
      state.input.touch_events[index].y
    } else {
      0.0
    }
  })
  let debug_string = @js.from_fn1(fn(value) {
    console_error(@js.any(string_from_id_optional(state, value)))
    0
  })
  let a11y_begin_update = @js.from_fn1(fn(root_any : @js.Any) {
    if state.window is None {
      return 0
    }
    let canvas = state.window.unwrap().canvas
    let root_id = to_int(number_or(root_any, 0))
    state.a11y_container = Some(a11y_begin_update_js(canvas, root_id))
    0
  })
  let a11y_push_node = wrap_variadic(
    @js.from_fn1(fn(args) {
      guard state.a11y_container is Some(container) else { return }
      let node_id = to_int(arg_number(args, 0, 0))
      let parent_id = to_int(arg_number(args, 1, 0))
      let role_id = to_int(arg_number(args, 2, 0))
      let x = arg_number(args, 3, 0)
      let y = arg_number(args, 4, 0)
      let w = arg_number(args, 5, 0)
      let h = arg_number(args, 6, 0)
      let name_id = to_int(arg_number(args, 7, 0))
      let actions_mask = to_int(arg_number(args, 8, 0))
      let name = string_from_id_optional(state, @js.any(name_id))
      a11y_push_node_js(
        container, node_id, parent_id, role_id, x, y, w, h, name, name, actions_mask,
      )
    }),
  )
  let a11y_end_update = @js.from_fn0(fn() {
    if state.a11y_container is Some(container) {
      a11y_end_update_js(container)
    }
    0
  })
  let a11y_apply_update = @js.from_fn1(fn(update_any : @js.Any) {
    if state.window is None {
      return 0
    }
    let update_id = to_int(number_or(update_any, 0))
    if update_id <= 0 {
      return 0
    }
    let payload = string_from_id_optional(state, @js.any(update_id))
    if payload == "" {
      return 0
    }
    let json = @json.parse(payload) catch { _ => return 0 }
    let update : @moon_accesskit.TreeUpdate = @json.from_json(json) catch {
      _ => return 0
    }
    let canvas = state.window.unwrap().canvas
    state.a11y_container = Some(a11y_begin_update_js(canvas, -1))
    guard state.a11y_container is Some(container) else { return 0 }
    let nodes_by_id : @hashmap.HashMap[UInt64, @moon_accesskit.Node] = @hashmap.HashMap::new()
    for nu in update.nodes() {
      nodes_by_id.set(nu.id().to_u64(), nu.node())
    }
    let focused_id = update.focus().to_u64()
    fn host_role(role : @moon_accesskit.Role) -> Int {
      match role {
        @moon_accesskit.Role::Window
        | @moon_accesskit.Role::Application
        | @moon_accesskit.Role::RootWebArea => 1
        @moon_accesskit.Role::Button | @moon_accesskit.Role::DefaultButton => 3
        @moon_accesskit.Role::Label
        | @moon_accesskit.Role::TextRun
        | @moon_accesskit.Role::Paragraph => 4
        @moon_accesskit.Role::Image => 5
        _ => 2
      }
    }

    fn label_for(node : @moon_accesskit.Node) -> String {
      match node.label() {
        Some(s) => s
        None => ""
      }
    }

    fn value_for(node : @moon_accesskit.Node) -> String {
      node.value().unwrap_or("")
    }

    let root_id = match update.tree() {
      Some(t) => t.root_id().to_u64()
      None => 0UL
    }
    let stack : Array[(UInt64, UInt64, Bool)] = []
    stack.push((0UL, root_id, false))
    let visited : @hashmap.HashMap[UInt64, Bool] = @hashmap.HashMap::new()
    while stack.length() > 0 {
      let (parent_id, cur_id, hidden_ancestor) = stack.pop().unwrap()
      if visited.contains(cur_id) {
        continue
      }
      visited.set(cur_id, true)
      guard nodes_by_id.get(cur_id) is Some(node) else { continue }
      if hidden_ancestor || node.is_hidden() {
        continue
      }
      let parent_int = if parent_id == 0UL { -1 } else { parent_id.to_int() }
      let cur_int = cur_id.to_int()
      if cur_id != root_id {
        let supports_scroll = node.supports_action(
            @moon_accesskit.Action::ScrollUp,
          ) ||
          node.supports_action(@moon_accesskit.Action::ScrollDown) ||
          node.supports_action(@moon_accesskit.Action::ScrollLeft) ||
          node.supports_action(@moon_accesskit.Action::ScrollRight)
        let actions_mask = (if node.supports_action(
              @moon_accesskit.Action::Focus,
            ) {
            1
          } else {
            0
          }) +
          (if node.supports_action(@moon_accesskit.Action::Click) {
            2
          } else {
            0
          }) +
          (if supports_scroll { 4 } else { 0 }) +
          (if node.supports_action(@moon_accesskit.Action::SetValue) {
            8
          } else {
            0
          })
        match node.bounds() {
          Some(b) => {
            let x = b.x0
            let y = b.y0
            let w = b.x1 - b.x0
            let h = b.y1 - b.y0
            a11y_push_node_js(
              container,
              cur_int,
              parent_int,
              host_role(node.role()),
              x,
              y,
              w,
              h,
              label_for(node),
              value_for(node),
              actions_mask,
            )
          }
          None => ()
        }
      }
      let children = node.children()
      for i in 0..<children.length() {
        stack.push((cur_id, children[i].to_u64(), false))
      }
    }
    a11y_end_update_js(container)
    if focused_id != 0UL {
      let focused_node = focused_id.to_int()
      if state.a11y_focused_node != focused_node {
        a11y_focus_node_js(focused_node)
        state.a11y_focused_node = focused_node
      }
    } else {
      state.a11y_focused_node = 0
    }
    0
  })
  let a11y_actions_len = @js.from_fn0(fn() { a11y_actions_len_js() })
  let a11y_action_target = @js.from_fn1(fn(index_any) {
    a11y_actions_target_js(to_int(number_or(index_any, 0)))
  })
  let a11y_action_kind = @js.from_fn1(fn(index_any) {
    a11y_actions_kind_js(to_int(number_or(index_any, 0)))
  })
  let a11y_action_value_len = @js.from_fn1(fn(index_any) {
    a11y_actions_value_len_js(to_int(number_or(index_any, 0)))
  })
  let a11y_action_value_code_unit = wrap_variadic(
    @js.from_fn1(fn(args) {
      let index = to_int(arg_number(args, 0, 0))
      let offset = to_int(arg_number(args, 1, 0))
      a11y_actions_value_code_unit_js(index, offset)
    }),
  )
  let a11y_actions_clear = @js.from_fn0(fn() {
    a11y_actions_clear_js()
    0
  })
  let string_sink_reset = @js.from_fn0(fn() {
    string_sink_reset_js()
    0
  })
  let string_sink_take = @js.from_fn0(fn() {
    let text = string_sink_take_js()
    if text == "" {
      return 0
    }
    let id = state.next_string_id
    state.next_string_id = id + 1
    map_set(state.strings, @js.any(id), @js.any(text))
    id
  })
  let string_drop = @js.from_fn1(fn(id_any) {
    let id = to_int(number_or(id_any, 0))
    if id > 0 {
      map_delete(state.strings, @js.any(id)) |> ignore
    }
    0
  })
  let bytes_sink_reset = @js.from_fn0(fn() {
    bytes_sink_reset_js()
    0
  })
  let bytes_sink_take = @js.from_fn0(fn() {
    let data = bytes_sink_take_js()
    let id = state.assets.next_blob_id
    state.assets.next_blob_id = id + 1
    map_set(state.assets.blobs, @js.any(id), data)
    id
  })
  let bytes_drop = @js.from_fn1(fn(id_any) {
    let id = to_int(number_or(id_any, 0))
    if id > 0 {
      map_delete(state.assets.blobs, @js.any(id)) |> ignore
    }
    0
  })
  let gpu_request_device = @js.from_fn0(fn() {
    if state.gpu.device is None {
      throw_error("WebGPU device not initialized. Call create_host() first.")
      return 0
    }
    1
  })
  let gpu_get_queue = @js.from_fn1(fn(_ : @js.Any) { 1 })
  let gpu_create_surface = @js.from_fn1(fn(_ : @js.Any) {
    if state.window is None {
      throw_error("Unknown window id")
      return 0
    }
    1
  })
  let gpu_configure_surface = wrap_variadic(
    @js.from_fn1(fn(args) {
      if state.gpu.context is None || state.gpu.device is None {
        return
      }
      if state.window is Some(window_state) {
        let width_int = to_int(
          arg_number(args, 2, window_state.width.to_double()),
        )
        let height_int = to_int(
          arg_number(args, 3, window_state.height.to_double()),
        )
        window_state.width = width_int
        window_state.height = height_int
        window_state.canvas._set("width", @js.any(width_int)) |> ignore
        window_state.canvas._set("height", @js.any(height_int)) |> ignore
        configure_surface_context(state, width_int, height_int)
      }
    }),
  )
  let asset_load_texture = @js.from_fn2(fn(path, nearest) {
    let id = state.gpu.next_texture_id
    state.gpu.next_texture_id = id + 1
    set_add(state.assets.loading_textures, @js.any(id))
    let path_text = string_from_id_required(state, path, "asset_load_texture")
    if path_text != "" {
      map_set(state.assets.texture_paths, @js.any(id), @js.any(path_text))
    }
    let nearest_value = number_or(nearest, 0) != 0
    @js.run_async(async fn() noraise {
      // Always pass the coerced JS string to avoid relying on wasm string interop here.
      let result = load_texture_from_path(
        state,
        id,
        @js.any(path_text),
        nearest_value,
      ) catch {
        err => {
          let message = "Texture load error: " + err.to_string()
          console_error(@js.any(message))
          dispatch_asset_error(message)
          set_delete(state.assets.loading_textures, @js.any(id)) |> ignore
        }
      }
      result |> ignore
    })
    id
  })
  let asset_load_texture_bytes = @js.from_fn2(fn(bytes_id_any, nearest_any) {
    let id = state.gpu.next_texture_id
    state.gpu.next_texture_id = id + 1
    set_add(state.assets.loading_textures, @js.any(id))
    let bytes_id = to_int(number_or(bytes_id_any, -1))
    let nearest_value = number_or(nearest_any, 0) != 0
    @js.run_async(async fn() noraise {
      if bytes_id <= 0 {
        dispatch_asset_error("Texture load error: bytes id not found")
        set_delete(state.assets.loading_textures, @js.any(id)) |> ignore
        return
      }
      let result = load_texture_from_blob_id(state, id, bytes_id, nearest_value) catch {
        err => {
          let message = "Texture load error: " + err.to_string()
          console_error(@js.any(message))
          dispatch_asset_error(message)
          set_delete(state.assets.loading_textures, @js.any(id)) |> ignore
        }
      }
      result |> ignore
    })
    id
  })
  let asset_load_wgsl = @js.from_fn1(fn(path) {
    let id = next_shader_id(state)
    set_add(state.assets.loading_shaders, @js.any(id))
    let path_text = string_from_id_required(state, path, "asset_load_wgsl")
    if path_text != "" {
      map_set(state.assets.shader_paths, @js.any(id), @js.any(path_text))
    }
    @js.run_async(async fn() noraise {
      let result = load_wgsl_from_path(state, id, path_text) catch {
        err => {
          let message = "Shader load error: " + err.to_string()
          console_error(@js.any(message))
          dispatch_asset_error(message)
          ""
        }
      }
      set_delete(state.assets.loading_shaders, @js.any(id)) |> ignore
      result |> ignore
    })
    id
  })
  let asset_load_font = @js.from_fn1(fn(path) {
    let id = state.assets.next_font_id
    state.assets.next_font_id = id + 1
    let path_text = string_from_id_required(state, path, "asset_load_font")
    if path_text == "" {
      return id
    }
    let url = resolve_asset_url(state, @js.any(path_text)) catch {
      err => {
        let message = "Font load error: " + err.to_string()
        console_error(@js.any(message))
        dispatch_asset_error(message)
        ""
      }
    }
    if url == "" {
      return id
    }
    let family = "mgstudio-font-" + id.to_string()
    let entry = @js.from_entries([
      ("id", @js.any(id)),
      ("family", @js.any(family)),
      ("loaded", @js.any(false)),
      ("bytes", js_null()),
    ])
    map_set(state.assets.fonts, @js.any(id), entry)
    set_add(state.assets.loading_fonts, @js.any(id))
    @js.run_async(async fn() noraise {
      let result = load_font_face(family, url).wait() catch {
        err => {
          let message = "Font load error: " + err.to_string()
          console_error(@js.any(message))
          dispatch_asset_error(message)
          js_null()
        }
      }
      if !host_is_nullish(result) {
        entry._set("loaded", @js.any(true)) |> ignore
      }
      // Best-effort: also fetch and store raw font bytes for engine-side text.
      // If fetching fails, keep `bytes` as nullish and let the engine retry later.
      let bytes_resp_opt : @http.Response? = Some(
        @http.fetch(url, method_="GET"),
      ) catch {
        _ => None
      }
      if bytes_resp_opt is Some(bytes_resp) {
        if bytes_resp.ok {
          let promise : @js.Promise[@arraybuffer.ArrayBuffer] = response_array_buffer(
            bytes_resp.as_any(),
          )
          let buf_opt : @arraybuffer.ArrayBuffer? = Some(promise.wait()) catch {
            _ => None
          }
          if buf_opt is Some(buf) {
            let bytes_u8 = uint8array_from_array_buffer(buf)
            entry._set("bytes", bytes_u8) |> ignore
            let len = to_int(number_or(bytes_u8._get("length"), 0))
            let b0 = uint8array_get_u8(bytes_u8, 0)
            let b1 = uint8array_get_u8(bytes_u8, 1)
            let b2 = uint8array_get_u8(bytes_u8, 2)
            let b3 = uint8array_get_u8(bytes_u8, 3)
            report_debug_once(
              state,
              "font_bytes_loaded_" + id.to_string(),
              "font bytes loaded: id=" +
              id.to_string() +
              " len=" +
              len.to_string() +
              " magic=[" +
              b0.to_string() +
              "," +
              b1.to_string() +
              "," +
              b2.to_string() +
              "," +
              b3.to_string() +
              "] path=" +
              path_text,
            )
          } else {
            dispatch_asset_error(
              "Font bytes load error: failed to read ArrayBuffer (path: " +
              path_text +
              ")",
            )
          }
        } else {
          dispatch_asset_error(
            "Font bytes load error: fetch failed (" +
            bytes_resp.status.to_string() +
            ") (path: " +
            path_text +
            ")",
          )
        }
      }
      set_delete(state.assets.loading_fonts, @js.any(id)) |> ignore
      result |> ignore
    })
    id
  })

  // Legacy text host APIs.
  //
  // The current Text2d pipeline rasterizes glyphs in the guest using
  // `moon_swash` (and shapes/line-breaks with `moon_cosmic`), sourcing font
  // bytes via `asset_font_bytes_*`.
  //
  // These Canvas2D-based helpers are kept for backwards-compatibility and
  // debugging, but are not required for core rendering.
  let font_rasterize_glyph = wrap_variadic(
    @js.from_fn1(fn(args) {
      let font_id = to_int(arg_number(args, 0, -1))
      let font_size = arg_number(args, 1, 16)
      let codepoint = to_int(arg_number(args, 2, 0))
      let smoothing = arg_number(args, 3, 1) != 0
      let entry = map_get(state.assets.fonts, @js.any(font_id))
      if host_is_nullish(entry) {
        dispatch_asset_error("Font rasterize error: font id not found")
        return -1
      }
      let loaded = entry._get("loaded")
      if host_is_nullish(loaded) || !(loaded.cast() : Bool) {
        return -1
      }
      let family = any_to_string(entry._get("family"))
      let result = rasterize_glyph(family, font_size, codepoint, smoothing)
      if host_is_nullish(result) {
        dispatch_asset_error("Font rasterize error: rasterizer unavailable")
        return -1
      }
      let glyph_id = state.assets.next_glyph_id
      state.assets.next_glyph_id = glyph_id + 1
      let width = to_int(number_or(result._get("width"), 0))
      let height = to_int(number_or(result._get("height"), 0))
      let offset_x = to_int(number_or(result._get("offsetX"), 0))
      let offset_y = to_int(number_or(result._get("offsetY"), 0))
      let data = result._get("data")
      let glyph_entry = @js.from_entries([
        ("width", @js.any(width)),
        ("height", @js.any(height)),
        ("offsetX", @js.any(offset_x)),
        ("offsetY", @js.any(offset_y)),
        ("data", data),
      ])
      map_set(state.assets.glyphs, @js.any(glyph_id), glyph_entry)
      glyph_id
    }),
  )
  let font_glyph_width = @js.from_fn1(fn(glyph_id) {
    let id = to_int(number_or(glyph_id, -1))
    let entry = map_get(state.assets.glyphs, @js.any(id))
    if host_is_nullish(entry) {
      0
    } else {
      to_int(number_or(entry._get("width"), 0))
    }
  })
  let font_glyph_height = @js.from_fn1(fn(glyph_id) {
    let id = to_int(number_or(glyph_id, -1))
    let entry = map_get(state.assets.glyphs, @js.any(id))
    if host_is_nullish(entry) {
      0
    } else {
      to_int(number_or(entry._get("height"), 0))
    }
  })
  let font_glyph_offset_x = @js.from_fn1(fn(glyph_id) {
    let id = to_int(number_or(glyph_id, -1))
    let entry = map_get(state.assets.glyphs, @js.any(id))
    if host_is_nullish(entry) {
      0
    } else {
      to_int(number_or(entry._get("offsetX"), 0))
    }
  })
  let font_glyph_offset_y = @js.from_fn1(fn(glyph_id) {
    let id = to_int(number_or(glyph_id, -1))
    let entry = map_get(state.assets.glyphs, @js.any(id))
    if host_is_nullish(entry) {
      0
    } else {
      to_int(number_or(entry._get("offsetY"), 0))
    }
  })
  let font_measure_advance = wrap_variadic(
    @js.from_fn1(fn(args) {
      let font_id = to_int(arg_number(args, 0, -1))
      let font_size = arg_number(args, 1, 16)
      let codepoint = to_int(arg_number(args, 2, 0))
      let entry = map_get(state.assets.fonts, @js.any(font_id))
      if host_is_nullish(entry) {
        return 0.0
      }
      let loaded = entry._get("loaded")
      if host_is_nullish(loaded) || !(loaded.cast() : Bool) {
        return 0.0
      }
      let family = any_to_string(entry._get("family"))
      measure_glyph_advance(family, font_size, codepoint)
    }),
  )
  let asset_font_bytes_len = @js.from_fn1(fn(font_id_any) {
    let font_id = to_int(number_or(font_id_any, -1))
    let entry = map_get(state.assets.fonts, @js.any(font_id))
    if host_is_nullish(entry) {
      0
    } else {
      let bytes = entry._get("bytes")
      if host_is_nullish(bytes) {
        0
      } else {
        let len = to_int(number_or(bytes._get("length"), 0))
        if len > 0 {
          report_debug_once(
            state,
            "font_bytes_len_" + font_id.to_string(),
            "asset_font_bytes_len: font_id=" +
            font_id.to_string() +
            " len=" +
            len.to_string(),
          )
        }
        len
      }
    }
  })
  let asset_font_bytes_get = @js.from_fn2(fn(font_id_any, index_any) {
    let font_id = to_int(number_or(font_id_any, -1))
    let index = to_int(number_or(index_any, -1))
    let entry = map_get(state.assets.fonts, @js.any(font_id))
    if host_is_nullish(entry) || index < 0 {
      0
    } else {
      let bytes = entry._get("bytes")
      if host_is_nullish(bytes) {
        0
      } else {
        uint8array_get_u8(bytes, index)
      }
    }
  })
  let asset_font_bytes_get_u32 = @js.from_fn2(fn(font_id_any, index_any) {
    let font_id = to_int(number_or(font_id_any, -1))
    let index = to_int(number_or(index_any, -1))
    let entry = map_get(state.assets.fonts, @js.any(font_id))
    if host_is_nullish(entry) || index < 0 {
      0
    } else {
      let bytes = entry._get("bytes")
      if host_is_nullish(bytes) {
        0
      } else {
        let b0 = uint8array_get_u8(bytes, index)
        let b1 = uint8array_get_u8(bytes, index + 1)
        let b2 = uint8array_get_u8(bytes, index + 2)
        let b3 = uint8array_get_u8(bytes, index + 3)
        b0 | (b1 << 8) | (b2 << 16) | (b3 << 24)
      }
    }
  })
  let asset_load_bytes = @js.from_fn1(fn(path_any) {
    let id = state.assets.next_blob_id
    state.assets.next_blob_id = id + 1
    map_set(state.assets.blobs, @js.any(id), js_null())
    let path_text = string_from_id_required(state, path_any, "asset_load_bytes")
    @js.run_async(async fn() noraise {
      if path_text == "" {
        return
      }
      let url = resolve_asset_url(state, @js.any(path_text)) catch {
        err => {
          let message = "Bytes load error: " + err.to_string()
          console_error(@js.any(message))
          dispatch_asset_error(message)
          ""
        }
      }
      if url == "" {
        return
      }
      let response_opt : @http.Response? = Some(@http.fetch(url, method_="GET")) catch {
        err => {
          let message = "Bytes load error: " + err.to_string()
          console_error(@js.any(message))
          dispatch_asset_error(message)
          None
        }
      }
      if response_opt is Some(response) {
        if response.ok {
          let promise : @js.Promise[@arraybuffer.ArrayBuffer] = response_array_buffer(
            response.as_any(),
          )
          let buffer_opt : @arraybuffer.ArrayBuffer? = Some(promise.wait()) catch {
            err => {
              let message = "Bytes load error: " + err.to_string()
              console_error(@js.any(message))
              dispatch_asset_error(message)
              None
            }
          }
          if buffer_opt is Some(buffer) {
            let bytes = uint8array_from_array_buffer(buffer)
            map_set(state.assets.blobs, @js.any(id), bytes)
          }
        } else {
          dispatch_asset_error(
            "Bytes load error: fetch failed (" +
            response.status.to_string() +
            ") (path: " +
            path_text +
            ")",
          )
        }
      }
    })
    id
  })
  let asset_bytes_len = @js.from_fn1(fn(blob_id_any) {
    let blob_id = to_int(number_or(blob_id_any, -1))
    let blob = map_get(state.assets.blobs, @js.any(blob_id))
    if host_is_nullish(blob) {
      0
    } else {
      to_int(number_or(blob._get("length"), 0))
    }
  })
  let asset_bytes_get_u32 = @js.from_fn2(fn(blob_id_any, index_any) {
    let blob_id = to_int(number_or(blob_id_any, -1))
    let index = to_int(number_or(index_any, -1))
    let blob = map_get(state.assets.blobs, @js.any(blob_id))
    if host_is_nullish(blob) || index < 0 {
      0
    } else {
      let b0 = uint8array_get_u8(blob, index)
      let b1 = uint8array_get_u8(blob, index + 1)
      let b2 = uint8array_get_u8(blob, index + 2)
      let b3 = uint8array_get_u8(blob, index + 3)
      b0 | (b1 << 8) | (b2 << 16) | (b3 << 24)
    }
  })
  fn texture_mip_dimension(size : Int, mip_level : Int) -> Int {
    let mut dim = if size > 0 { size } else { 1 }
    let mut level = if mip_level > 0 { mip_level } else { 0 }
    while level > 0 && dim > 1 {
      dim = dim / 2
      if dim < 1 {
        dim = 1
      }
      level = level - 1
    }
    dim
  }
  fn texture_max_mip_level_count(width : Int, height : Int) -> Int {
    let mut max_dim = if width > height { width } else { height }
    if max_dim < 1 {
      max_dim = 1
    }
    let mut count = 1
    while max_dim > 1 {
      max_dim = max_dim / 2
      count = count + 1
    }
    count
  }
  let asset_set_texture_sampler = @js.from_fn2(fn(texture_id, sampler_kind) {
    let id = to_int(number_or(texture_id, -1))
    let kind = to_int(number_or(sampler_kind, 0))
    map_set(state.assets.texture_sampler_overrides, @js.any(id), @js.any(kind))
    let entry = map_get(state.gpu.textures, @js.any(id))
    if host_is_nullish(entry) {
      return
    }
    let sampler = create_sampler(state, kind)
    if sampler is Some(sampler_value) {
      entry._set("sampler", sampler_value.as_any()) |> ignore
      entry._set("bindGroup", js_null()) |> ignore
      entry._set("meshBindGroup", js_null()) |> ignore
      entry._set("mesh3dBindGroup", js_null()) |> ignore
      entry._set("uiBindGroup", js_null()) |> ignore
      ensure_bind_group_for_texture(state, entry)
      ensure_mesh_bind_group_for_texture(state, entry)
      ensure_mesh3d_bind_group_for_texture(state, entry)
      ensure_ui_bind_group_for_texture(state, entry)
    }
  })
  let asset_create_dynamic_texture = @js.from_fn3(fn(width, height, nearest) {
    if state.gpu.device is None {
      throw_error("GPU device not ready")
      return 0
    }
    ensure_pipeline_resources(state)
    let id = state.gpu.next_texture_id
    state.gpu.next_texture_id = id + 1
    map_set(
      state.assets.texture_paths,
      @js.any(id),
      @js.any("<dynamic-texture>"),
    )
    let width_value = number_or(width, 1)
    let height_value = number_or(height, 1)
    let safe_width = if width_value > 0 { to_int(width_value) } else { 1 }
    let safe_height = if height_value > 0 { to_int(height_value) } else { 1 }
    if state.gpu.device is Some(device) {
      let texture_usage = @webgpu.combine_flags(
        @webgpu.combine_flags(
          @webgpu.combine_flags(
            @webgpu.texture_usage_texture_binding(),
            @webgpu.texture_usage_copy_dst(),
          ),
          @webgpu.texture_usage_copy_src(),
        ),
        @webgpu.texture_usage_render_attachment(),
      )
      let texture_desc = @webgpu.texture_descriptor(
        @webgpu.texture_size(safe_width, safe_height),
        @webgpu.TextureFormat::Rgba8Unorm,
        texture_usage,
      )
      let texture = device.create_texture(texture_desc.to_js())
      // Match Bevy font-atlas behavior: dynamic textures start fully transparent.
      let clear_data = create_zero_rgba_data(safe_width, safe_height)
      write_texture_region(
        device.queue().as_any(),
        texture.as_any(),
        clear_data,
        safe_width,
        safe_height,
        0,
        0,
      )
      let sampler = create_sampler(
        state,
        sampler_kind_from_nearest(number_or(nearest, 0) != 0),
      )
      if sampler is Some(sampler_value) {
        let entry = @js.from_entries([
          ("id", @js.any(id)),
          ("texture", texture.as_any()),
          ("view", texture.create_view().as_any()),
          ("sampler", sampler_value.as_any()),
          ("bindGroup", js_null()),
          ("meshBindGroup", js_null()),
          ("mesh3dBindGroup", js_null()),
          ("uiBindGroup", js_null()),
          ("width", @js.any(safe_width)),
          ("height", @js.any(safe_height)),
          ("format", @js.any(@webgpu.TextureFormat::Rgba8Unorm.to_js_string())),
        ])
        map_set(state.gpu.textures, @js.any(id), entry)
        ensure_bind_group_for_texture(state, entry)
      }
    }
    id
  })
  let asset_create_dynamic_texture_mipped = wrap_variadic(
    @js.from_fn1(fn(args) {
      let width_value = arg_number(args, 0, 1)
      let height_value = arg_number(args, 1, 1)
      let mip_level_count_value = arg_number(args, 2, 1)
      let nearest_value = arg_number(args, 3, 0)
      if state.gpu.device is None {
        throw_error("GPU device not ready")
        return 0
      }
      ensure_pipeline_resources(state)
      let id = state.gpu.next_texture_id
      state.gpu.next_texture_id = id + 1
      map_set(
        state.assets.texture_paths,
        @js.any(id),
        @js.any("<dynamic-texture-mipped>"),
      )
      let safe_width = if width_value > 0 { to_int(width_value) } else { 1 }
      let safe_height = if height_value > 0 { to_int(height_value) } else { 1 }
      let requested_mips = to_int(mip_level_count_value)
      let mut safe_mip_level_count = if requested_mips > 0 {
        requested_mips
      } else {
        1
      }
      let max_mip_level_count = texture_max_mip_level_count(
        safe_width, safe_height,
      )
      if safe_mip_level_count > max_mip_level_count {
        safe_mip_level_count = max_mip_level_count
      }
      if state.gpu.device is Some(device) {
        let texture_usage = @webgpu.combine_flags(
          @webgpu.combine_flags(
            @webgpu.combine_flags(
              @webgpu.texture_usage_texture_binding(),
              @webgpu.texture_usage_copy_dst(),
            ),
            @webgpu.texture_usage_copy_src(),
          ),
          @webgpu.texture_usage_render_attachment(),
        )
        let texture_desc = @webgpu.texture_descriptor(
          @webgpu.texture_size(safe_width, safe_height),
          @webgpu.TextureFormat::Rgba8Unorm,
          texture_usage,
        ).to_js()
        texture_desc._set("mipLevelCount", @js.any(safe_mip_level_count))
        |> ignore
        let texture = device.create_texture(texture_desc)
        let queue = device.queue().as_any()
        for mip_level in 0..<safe_mip_level_count {
          let mip_width = texture_mip_dimension(safe_width, mip_level)
          let mip_height = texture_mip_dimension(safe_height, mip_level)
          let clear_data = create_zero_rgba_data(mip_width, mip_height)
          write_texture_region_mip(
            queue,
            texture.as_any(),
            clear_data,
            mip_width,
            mip_height,
            0,
            0,
            mip_level,
          )
        }
        let sampler = create_sampler(
          state,
          sampler_kind_from_nearest(nearest_value != 0),
        )
        if sampler is Some(sampler_value) {
          let entry = @js.from_entries([
            ("id", @js.any(id)),
            ("texture", texture.as_any()),
            ("view", texture.create_view().as_any()),
            ("sampler", sampler_value.as_any()),
            ("bindGroup", js_null()),
            ("meshBindGroup", js_null()),
            ("mesh3dBindGroup", js_null()),
            ("uiBindGroup", js_null()),
            ("width", @js.any(safe_width)),
            ("height", @js.any(safe_height)),
            (
              "format",
              @js.any(@webgpu.TextureFormat::Rgba8Unorm.to_js_string()),
            ),
            ("mipLevelCount", @js.any(safe_mip_level_count)),
          ])
          map_set(state.gpu.textures, @js.any(id), entry)
          ensure_bind_group_for_texture(state, entry)
        }
      }
      id
    }),
  )
  let asset_update_texture_region = wrap_variadic(
    @js.from_fn1(fn(args) {
      let texture_id = to_int(arg_number(args, 0, -1))
      let x = to_int(arg_number(args, 1, 0))
      let y = to_int(arg_number(args, 2, 0))
      let width = to_int(arg_number(args, 3, 0))
      let height = to_int(arg_number(args, 4, 0))
      let glyph_id = to_int(arg_number(args, 5, -1))
      let texture_entry = map_get(state.gpu.textures, @js.any(texture_id))
      if host_is_nullish(texture_entry) {
        dispatch_asset_error("Texture update error: texture id not found")
        return
      }
      let glyph_entry = map_get(state.assets.glyphs, @js.any(glyph_id))
      if host_is_nullish(glyph_entry) {
        dispatch_asset_error("Texture update error: glyph id not found")
        return
      }
      let glyph_width = to_int(number_or(glyph_entry._get("width"), 0))
      let glyph_height = to_int(number_or(glyph_entry._get("height"), 0))
      let target_width = if width > 0 { width } else { glyph_width }
      let target_height = if height > 0 { height } else { glyph_height }
      if target_width <= 0 || target_height <= 0 {
        return
      }
      if state.gpu.queue is Some(queue) && state.gpu.device is Some(device) {
        device.push_error_scope("validation")
        let data = glyph_entry._get("data")
        write_texture_region(
          queue.as_any(),
          texture_entry._get("texture"),
          data,
          target_width,
          target_height,
          x,
          y,
        )
        let promise = device.pop_error_scope()
        @js.run_async(async fn() noraise {
          let err_any : @js.Any = promise.wait() catch { _ => js_null() }
          if !host_is_nullish(err_any) {
            report_asset_error_once(
              state,
              "texture_update_glyph_validation_error",
              "Texture update (glyph) validation error: " +
              any_to_string(err_any),
            )
          }
        })
      }
    }),
  )
  let asset_update_texture_region_bytes = wrap_variadic(
    @js.from_fn1(fn(args) {
      let texture_id = to_int(arg_number(args, 0, -1))
      let x = to_int(arg_number(args, 1, 0))
      let y = to_int(arg_number(args, 2, 0))
      let width = to_int(arg_number(args, 3, 0))
      let height = to_int(arg_number(args, 4, 0))
      let bytes_id = to_int(arg_number(args, 5, -1))
      if width <= 0 || height <= 0 {
        return
      }
      let texture_entry = map_get(state.gpu.textures, @js.any(texture_id))
      if host_is_nullish(texture_entry) {
        dispatch_asset_error("Texture update error: texture id not found")
        return
      }
      let blob = map_get(state.assets.blobs, @js.any(bytes_id))
      if host_is_nullish(blob) {
        dispatch_asset_error("Texture update error: bytes id not found")
        return
      }
      if state.gpu.queue is Some(queue) && state.gpu.device is Some(device) {
        device.push_error_scope("validation")
        write_texture_region(
          queue.as_any(),
          texture_entry._get("texture"),
          blob,
          width,
          height,
          x,
          y,
        )
        let promise = device.pop_error_scope()
        @js.run_async(async fn() noraise {
          let err_any : @js.Any = promise.wait() catch { _ => js_null() }
          if !host_is_nullish(err_any) {
            report_asset_error_once(
              state,
              "texture_update_validation_error",
              "Texture update validation error: " + any_to_string(err_any),
            )
          }
        })
      }
    }),
  )
  let asset_update_texture_region_mip_bytes = wrap_variadic(
    @js.from_fn1(fn(args) {
      let texture_id = to_int(arg_number(args, 0, -1))
      let x = to_int(arg_number(args, 1, 0))
      let y = to_int(arg_number(args, 2, 0))
      let width = to_int(arg_number(args, 3, 0))
      let height = to_int(arg_number(args, 4, 0))
      let mip_level = to_int(arg_number(args, 5, 0))
      let bytes_id = to_int(arg_number(args, 6, -1))
      if width <= 0 || height <= 0 || mip_level < 0 {
        return
      }
      let texture_entry = map_get(state.gpu.textures, @js.any(texture_id))
      if host_is_nullish(texture_entry) {
        dispatch_asset_error("Texture update error: texture id not found")
        return
      }
      let blob = map_get(state.assets.blobs, @js.any(bytes_id))
      if host_is_nullish(blob) {
        dispatch_asset_error("Texture update error: bytes id not found")
        return
      }
      if state.gpu.queue is Some(queue) && state.gpu.device is Some(device) {
        device.push_error_scope("validation")
        write_texture_region_mip(
          queue.as_any(),
          texture_entry._get("texture"),
          blob,
          width,
          height,
          x,
          y,
          mip_level,
        )
        let promise = device.pop_error_scope()
        @js.run_async(async fn() noraise {
          let err_any : @js.Any = promise.wait() catch { _ => js_null() }
          if !host_is_nullish(err_any) {
            report_asset_error_once(
              state,
              "texture_update_mip_validation_error",
              "Texture mip update validation error: " + any_to_string(err_any),
            )
          }
        })
      }
    }),
  )
  let asset_create_texture_mip_view = @js.from_fn2(fn(
    texture_id_any : @js.Any,
    mip_level_any : @js.Any,
  ) {
    let texture_id = to_int(number_or(texture_id_any, -1))
    let mip_level = to_int(number_or(mip_level_any, 0))
    if texture_id < 0 || mip_level < 0 {
      return 0
    }
    let source_entry = map_get(state.gpu.textures, @js.any(texture_id))
    if host_is_nullish(source_entry) {
      dispatch_asset_error("Texture mip view error: texture id not found")
      return 0
    }
    let source_width = to_int(number_or(source_entry._get("width"), 1))
    let source_height = to_int(number_or(source_entry._get("height"), 1))
    let mip_width = texture_mip_dimension(source_width, mip_level)
    let mip_height = texture_mip_dimension(source_height, mip_level)
    let descriptor = @js.from_entries([
      ("baseMipLevel", @js.any(mip_level)),
      ("mipLevelCount", @js.any(1)),
    ])
    let texture : @webgpu.GPUTexture = source_entry._get("texture").cast()
    let id = state.gpu.next_texture_id
    state.gpu.next_texture_id = id + 1
    let entry = @js.from_entries([
      ("id", @js.any(id)),
      ("texture", texture.as_any()),
      ("view", texture.create_view(descriptor~).as_any()),
      ("sampler", source_entry._get("sampler")),
      ("bindGroup", js_null()),
      ("meshBindGroup", js_null()),
      ("mesh3dBindGroup", js_null()),
      ("uiBindGroup", js_null()),
      ("width", @js.any(mip_width)),
      ("height", @js.any(mip_height)),
      ("format", source_entry._get("format")),
      ("mipLevelCount", @js.any(1)),
    ])
    map_set(state.gpu.textures, @js.any(id), entry)
    let path_entry = map_get(state.assets.texture_paths, @js.any(texture_id))
    if !host_is_nullish(path_entry) {
      map_set(state.assets.texture_paths, @js.any(id), path_entry)
    }
    ensure_bind_group_for_texture(state, entry)
    id
  })
  let asset_texture_width = @js.from_fn1(fn(texture_id) {
    let id = to_int(number_or(texture_id, -1))
    let entry = map_get(state.gpu.textures, @js.any(id))
    if host_is_nullish(entry) {
      0
    } else {
      to_int(number_or(entry._get("width"), 0))
    }
  })
  let asset_texture_height = @js.from_fn1(fn(texture_id) {
    let id = to_int(number_or(texture_id, -1))
    let entry = map_get(state.gpu.textures, @js.any(id))
    if host_is_nullish(entry) {
      0
    } else {
      to_int(number_or(entry._get("height"), 0))
    }
  })
  let asset_is_texture_loaded = @js.from_fn1(fn(texture_id) {
    let id = to_int(number_or(texture_id, -1))
    if id < 0 {
      return false
    }
    if set_has(state.assets.loading_textures, @js.any(id)) {
      return false
    }
    let entry = map_get(state.gpu.textures, @js.any(id))
    !host_is_nullish(entry)
  })
  let asset_supported_formats = @js.from_fn0(fn() {
    if state.gpu.device is Some(device) {
      let features = device.as_any()._get("features")
      if host_is_nullish(features) {
        return 0
      }
      let mut gpu_feature_mask = 0
      if set_has(features, @js.any("texture-compression-astc")) {
        gpu_feature_mask = gpu_feature_mask + 1
      }
      if set_has(features, @js.any("texture-compression-bc")) {
        gpu_feature_mask = gpu_feature_mask + 2
      }
      if set_has(features, @js.any("texture-compression-etc2")) {
        gpu_feature_mask = gpu_feature_mask + 4
      }
      // Runtime decoder supports direct KTX2 upload for ASTC/BC/ETC2 payloads.
      let runtime_decoder_mask = 1 | 2 | 4
      gpu_feature_mask & runtime_decoder_mask
    } else {
      0
    }
  })
  let asset_copy_texture_to_texture = wrap_variadic(
    @js.from_fn1(fn(args) {
      if state.gpu.device is None || state.gpu.queue is None {
        dispatch_asset_error("Texture copy error: GPU device not ready")
        return
      }
      let dst_id = to_int(arg_number(args, 0, -1))
      let x = to_int(arg_number(args, 1, 0))
      let y = to_int(arg_number(args, 2, 0))
      let src_id = to_int(arg_number(args, 3, -1))
      if dst_id < 0 || src_id < 0 {
        return
      }
      if x < 0 || y < 0 {
        return
      }
      let src_entry = map_get(state.gpu.textures, @js.any(src_id))
      let dst_entry = map_get(state.gpu.textures, @js.any(dst_id))
      if host_is_nullish(src_entry) {
        dispatch_asset_error("Texture copy error: source texture id not found")
        return
      }
      if host_is_nullish(dst_entry) {
        dispatch_asset_error(
          "Texture copy error: destination texture id not found",
        )
        return
      }
      let width = to_int(number_or(src_entry._get("width"), 0))
      let height = to_int(number_or(src_entry._get("height"), 0))
      if width <= 0 || height <= 0 {
        return
      }
      let dst_width = to_int(number_or(dst_entry._get("width"), 0))
      let dst_height = to_int(number_or(dst_entry._get("height"), 0))
      if dst_width <= 0 || dst_height <= 0 {
        return
      }
      if x + width > dst_width || y + height > dst_height {
        dispatch_asset_error("Texture copy error: destination out of bounds")
        return
      }
      if state.gpu.device is Some(device) && state.gpu.queue is Some(queue) {
        copy_texture_to_texture_region(
          device.as_any(),
          queue.as_any(),
          src_entry._get("texture"),
          dst_entry._get("texture"),
          width,
          height,
          x,
          y,
        )
      }
    }),
  )
  let asset_load_folder = @js.from_fn1(fn(_path : @js.Any) {
    let id = state.assets.next_folder_id
    state.assets.next_folder_id = id + 1
    let empty_handles : Array[Int] = []
    map_set(state.assets.folders, @js.any(id), @js.any(empty_handles))
    let path_text = string_from_id_required(state, _path, "asset_load_folder")
    @js.run_async(async fn() noraise {
      let handles : Array[Int] = []
      if path_text != "" {
        let manifest_path = join_asset_path(path_text, "folder.txt")
        let url = resolve_asset_url(state, @js.any(manifest_path)) catch {
          err => {
            let message = "Folder load error: " + err.to_string()
            console_error(@js.any(message))
            dispatch_asset_error(message)
            ""
          }
        }
        if url != "" {
          let manifest = fetch_text_from_url(url) catch {
            err => {
              let message = "Folder load error: " + err.to_string()
              console_error(@js.any(message))
              dispatch_asset_error(message)
              ""
            }
          }
          if manifest != "" {
            for entry in split_trimmed_lines(manifest) {
              let asset_path = join_asset_path(path_text, entry)
              let tex_id = state.gpu.next_texture_id
              state.gpu.next_texture_id = tex_id + 1
              set_add(state.assets.loading_textures, @js.any(tex_id))
              if asset_path != "" {
                map_set(
                  state.assets.texture_paths,
                  @js.any(tex_id),
                  @js.any(asset_path),
                )
              }
              let result = load_texture_from_path(
                state,
                tex_id,
                @js.any(asset_path),
                false,
              ) catch {
                err => {
                  let message = "Texture load error: " + err.to_string()
                  console_error(@js.any(message))
                  dispatch_asset_error(message)
                  set_delete(state.assets.loading_textures, @js.any(tex_id))
                  |> ignore
                }
              }
              result |> ignore
              handles.push(tex_id)
            }
          }
        }
      }
      map_set(state.assets.folders, @js.any(id), @js.any(handles))
      if state.assets.folder_events_pos >= state.assets.folder_events.length() {
        state.assets.folder_events = []
        state.assets.folder_events_pos = 0
      }
      state.assets.folder_events.push(3)
      state.assets.folder_events.push(id)
    })
    id
  })
  let asset_poll_loaded_folder_event_kind = @js.from_fn0(fn() {
    let pos = state.assets.folder_events_pos
    if pos >= state.assets.folder_events.length() {
      -1
    } else {
      state.assets.folder_events[pos]
    }
  })
  let asset_poll_loaded_folder_event_id = @js.from_fn0(fn() {
    let pos = state.assets.folder_events_pos
    if pos + 1 >= state.assets.folder_events.length() {
      state.assets.folder_events = []
      state.assets.folder_events_pos = 0
      -1
    } else {
      let id = state.assets.folder_events[pos + 1]
      let next_pos = pos + 2
      if next_pos >= state.assets.folder_events.length() {
        state.assets.folder_events = []
        state.assets.folder_events_pos = 0
      } else {
        state.assets.folder_events_pos = next_pos
      }
      id
    }
  })
  let asset_loaded_folder_handles_len = @js.from_fn1(fn(folder_id) {
    let id = to_int(number_or(folder_id, -1))
    let entry = map_get(state.assets.folders, @js.any(id))
    if host_is_nullish(entry) {
      0
    } else {
      let handles : Array[Int] = entry.cast()
      handles.length()
    }
  })
  let asset_loaded_folder_handles_get = @js.from_fn2(fn(folder_id, index) {
    let id = to_int(number_or(folder_id, -1))
    let idx = to_int(number_or(index, -1))
    let entry = map_get(state.assets.folders, @js.any(id))
    if host_is_nullish(entry) {
      -1
    } else {
      let handles : Array[Int] = entry.cast()
      if idx < 0 || idx >= handles.length() {
        -1
      } else {
        handles[idx]
      }
    }
  })
  let gpu_create_render_target = @js.from_fn3(fn(width, height, nearest) {
    if state.gpu.device is None {
      throw_error("GPU device not ready")
      return 0
    }
    ensure_pipeline_resources(state)
    let id = state.gpu.next_texture_id
    state.gpu.next_texture_id = id + 1
    map_set(state.assets.texture_paths, @js.any(id), @js.any("<render-target>"))
    let width_value = number_or(width, 1)
    let height_value = number_or(height, 1)
    let safe_width = if width_value > 0 { to_int(width_value) } else { 1 }
    let safe_height = if height_value > 0 { to_int(height_value) } else { 1 }
    if state.gpu.device is Some(device) {
      let format = state.gpu.format.unwrap_or(@webgpu.TextureFormat::Bgra8Unorm)
      let texture_usage = @webgpu.combine_flags(
        @webgpu.combine_flags(
          @webgpu.combine_flags(
            @webgpu.texture_usage_texture_binding(),
            @webgpu.texture_usage_render_attachment(),
          ),
          @webgpu.texture_usage_copy_src(),
        ),
        @webgpu.texture_usage_copy_dst(),
      )
      let texture_desc = @webgpu.texture_descriptor(
        @webgpu.texture_size(safe_width, safe_height),
        format,
        texture_usage,
      )
      let texture = device.create_texture(texture_desc.to_js())
      let sampler = create_sampler(
        state,
        sampler_kind_from_nearest(number_or(nearest, 0) != 0),
      )
      if sampler is Some(sampler_value) {
        let entry = @js.from_entries([
          ("id", @js.any(id)),
          ("texture", texture.as_any()),
          ("view", texture.create_view().as_any()),
          ("sampler", sampler_value.as_any()),
          ("bindGroup", js_null()),
          ("meshBindGroup", js_null()),
          ("mesh3dBindGroup", js_null()),
          ("uiBindGroup", js_null()),
          ("width", @js.any(safe_width)),
          ("height", @js.any(safe_height)),
          ("format", @js.any(format.to_js_string())),
        ])
        map_set(state.gpu.textures, @js.any(id), entry)
        ensure_bind_group_for_texture(state, entry)
      }
    }
    id
  })
  let gpu_create_render_target_rgba16f = @js.from_fn3(fn(
    width,
    height,
    nearest,
  ) {
    if state.gpu.device is None {
      throw_error("GPU device not ready")
      return 0
    }
    ensure_pipeline_resources(state)
    let id = state.gpu.next_texture_id
    state.gpu.next_texture_id = id + 1
    map_set(
      state.assets.texture_paths,
      @js.any(id),
      @js.any("<render-target-rgba16f>"),
    )
    let width_value = number_or(width, 1)
    let height_value = number_or(height, 1)
    let safe_width = if width_value > 0 { to_int(width_value) } else { 1 }
    let safe_height = if height_value > 0 { to_int(height_value) } else { 1 }
    if state.gpu.device is Some(device) {
      let format = @webgpu.TextureFormat::Other("rgba16float")
      let texture_usage = @webgpu.combine_flags(
        @webgpu.combine_flags(
          @webgpu.combine_flags(
            @webgpu.texture_usage_texture_binding(),
            @webgpu.texture_usage_render_attachment(),
          ),
          @webgpu.texture_usage_copy_src(),
        ),
        @webgpu.texture_usage_copy_dst(),
      )
      let texture_desc = @webgpu.texture_descriptor(
        @webgpu.texture_size(safe_width, safe_height),
        format,
        texture_usage,
      )
      let texture = device.create_texture(texture_desc.to_js())
      let sampler = create_sampler(
        state,
        sampler_kind_from_nearest(number_or(nearest, 0) != 0),
      )
      if sampler is Some(sampler_value) {
        let entry = @js.from_entries([
          ("id", @js.any(id)),
          ("texture", texture.as_any()),
          ("view", texture.create_view().as_any()),
          ("sampler", sampler_value.as_any()),
          ("bindGroup", js_null()),
          ("meshBindGroup", js_null()),
          ("mesh3dBindGroup", js_null()),
          ("uiBindGroup", js_null()),
          ("width", @js.any(safe_width)),
          ("height", @js.any(safe_height)),
          ("format", @js.any(format.to_js_string())),
        ])
        map_set(state.gpu.textures, @js.any(id), entry)
        ensure_bind_group_for_texture(state, entry)
      }
    }
    id
  })
  let gpu_create_mesh_capsule = @js.from_fn3(fn(radius, half_length, segments) {
    if state.gpu.device is None {
      throw_error("GPU device not ready")
      return 0
    }
    ensure_mesh_pipeline(state)
    let id = state.gpu.next_mesh_id
    state.gpu.next_mesh_id = id + 1
    let vertices = create_capsule_mesh_data(
      number_or(radius, 0.5),
      number_or(half_length, 0.5),
      to_int(number_or(segments, 16)),
    )
    if state.gpu.device is Some(device) {
      let vertex_size : Int = vertices._get("byteLength").cast()
      let vertex_usage = @webgpu.combine_flags(
        @webgpu.buffer_usage_vertex(),
        @webgpu.buffer_usage_copy_dst(),
      )
      let vertex_desc = @webgpu.buffer_descriptor(vertex_size, vertex_usage)
      let vertex_buffer = device.create_buffer(vertex_desc.to_js())
      device.queue().write_buffer(vertex_buffer, 0, vertices)
      let vertex_len : Double = vertices._get("length").cast()
      let vertex_count = to_int(vertex_len / 8)
      let entry = @js.from_entries([
        ("id", @js.any(id)),
        ("vertexBuffer", vertex_buffer.as_any()),
        ("vertexCount", @js.any(vertex_count)),
        ("vertexLayoutKind", @js.any(1)),
      ])
      map_set(state.gpu.meshes, @js.any(id), entry)
    }
    id
  })
  let gpu_create_mesh_rectangle = @js.from_fn2(fn(width, height) {
    if state.gpu.device is None {
      throw_error("GPU device not ready")
      return 0
    }
    ensure_mesh_pipeline(state)
    let id = state.gpu.next_mesh_id
    state.gpu.next_mesh_id = id + 1
    let vertices = create_rectangle_mesh_data(
      number_or(width, 1),
      number_or(height, 1),
    )
    if state.gpu.device is Some(device) {
      let vertex_size : Int = vertices._get("byteLength").cast()
      let vertex_usage = @webgpu.combine_flags(
        @webgpu.buffer_usage_vertex(),
        @webgpu.buffer_usage_copy_dst(),
      )
      let vertex_desc = @webgpu.buffer_descriptor(vertex_size, vertex_usage)
      let vertex_buffer = device.create_buffer(vertex_desc.to_js())
      device.queue().write_buffer(vertex_buffer, 0, vertices)
      let vertex_len : Double = vertices._get("length").cast()
      let vertex_count = to_int(vertex_len / 8)
      let entry = @js.from_entries([
        ("id", @js.any(id)),
        ("vertexBuffer", vertex_buffer.as_any()),
        ("vertexCount", @js.any(vertex_count)),
        ("vertexLayoutKind", @js.any(1)),
      ])
      map_set(state.gpu.meshes, @js.any(id), entry)
    }
    id
  })
  let gpu_create_mesh_triangles = @js.from_fn1(fn(vertices_xy) {
    if state.gpu.device is None {
      throw_error("GPU device not ready")
      return 0
    }
    ensure_mesh_pipeline(state)
    let id = state.gpu.next_mesh_id
    state.gpu.next_mesh_id = id + 1
    let vertices = float32array_from_csv(
      string_from_id_required(state, vertices_xy, "gpu_create_mesh_triangles"),
    )
    if state.gpu.device is Some(device) {
      let vertex_size : Int = vertices._get("byteLength").cast()
      let vertex_usage = @webgpu.combine_flags(
        @webgpu.buffer_usage_vertex(),
        @webgpu.buffer_usage_copy_dst(),
      )
      let vertex_desc = @webgpu.buffer_descriptor(vertex_size, vertex_usage)
      let vertex_buffer = device.create_buffer(vertex_desc.to_js())
      device.queue().write_buffer(vertex_buffer, 0, vertices)
      let vertex_len : Double = vertices._get("length").cast()
      let vertex_count = to_int(vertex_len / 8)
      if vertex_count <= 0 {
        report_asset_error_once(
          state,
          "mesh_create_empty_vertices_" + id.to_string(),
          "Mesh create error: empty vertex data (mesh id " +
          id.to_string() +
          ")",
        )
      }
      let entry = @js.from_entries([
        ("id", @js.any(id)),
        ("vertexBuffer", vertex_buffer.as_any()),
        ("vertexCount", @js.any(vertex_count)),
        ("vertexLayoutKind", @js.any(1)),
      ])
      map_set(state.gpu.meshes, @js.any(id), entry)
    }
    id
  })
  let gpu_create_mesh3d_impl = fn(
    vertices_xyzuvrgba : @js.Any,
    primitive_topology : Int,
  ) -> Int {
    if state.gpu.device is None {
      throw_error("GPU device not ready")
      return 0
    }
    let id = state.gpu.next_mesh_id
    state.gpu.next_mesh_id = id + 1
    let vertices = float32array_from_csv(
      string_from_id_required(state, vertices_xyzuvrgba, "gpu_create_mesh3d"),
    )
    if state.gpu.device is Some(device) {
      let vertex_size : Int = vertices._get("byteLength").cast()
      let vertex_usage = @webgpu.combine_flags(
        @webgpu.buffer_usage_vertex(),
        @webgpu.buffer_usage_copy_dst(),
      )
      let vertex_desc = @webgpu.buffer_descriptor(vertex_size, vertex_usage)
      let vertex_buffer = device.create_buffer(vertex_desc.to_js())
      device.queue().write_buffer(vertex_buffer, 0, vertices)
      let vertex_len : Double = vertices._get("length").cast()
      let vertex_count = to_int(vertex_len / 9)
      if vertex_count <= 0 {
        report_asset_error_once(
          state,
          "mesh3d_create_empty_vertices_" + id.to_string(),
          "Mesh3d create error: empty vertex data (mesh id " +
          id.to_string() +
          ")",
        )
      }
      let entry = @js.from_entries([
        ("id", @js.any(id)),
        ("vertexBuffer", vertex_buffer.as_any()),
        ("vertexCount", @js.any(vertex_count)),
        ("vertexLayoutKind", @js.any(2)),
        ("primitiveTopologyKind", @js.any(primitive_topology)),
      ])
      map_set(state.gpu.meshes, @js.any(id), entry)
    }
    id
  }
  let gpu_create_mesh3d = @js.from_fn2(fn(
    vertices_xyzuvrgba,
    primitive_topology_any,
  ) {
    gpu_create_mesh3d_impl(
      vertices_xyzuvrgba,
      to_int(number_or(primitive_topology_any, 0)),
    )
  })
  let gpu_create_mesh_triangles3d = @js.from_fn1(fn(vertices_xyzuvrgba) {
    gpu_create_mesh3d_impl(vertices_xyzuvrgba, 0)
  })
  let gpu_begin_frame = @js.from_fn1(fn(_ : @js.Any) { begin_frame(state) })
  let gpu_begin_pass = wrap_variadic(
    @js.from_fn1(fn(args) {
      let start_ms = if state.gpu.profile_enabled {
        performance_now()
      } else {
        0.0
      }
      begin_pass(
        state,
        to_int(arg_number(args, 0, -1)),
        arg_number(args, 1, 1),
        arg_number(args, 2, 1),
        arg_number(args, 3, 0),
        arg_number(args, 4, 0),
        arg_number(args, 5, 0),
        arg_number(args, 6, 1),
        arg_number(args, 7, 0),
        arg_number(args, 8, 0),
        arg_number(args, 9, 0),
        arg_number(args, 10, 1),
        false,
        0.0,
        0.0,
        0.0,
        0.0,
        1.0,
        1.5707963267948966,
        0.1,
        1000.0,
        arg_number(args, 11, 0),
        arg_number(args, 12, 0),
        arg_number(args, 13, 0),
        arg_number(args, 14, 0),
        arg_number(args, 15, 0),
        arg_number(args, 16, 1),
        1.0,
        1.0,
        1.0,
        0.0,
        0.0,
        -1.0,
        0.0,
        1.0,
        1.0,
        1.0,
        0.0,
        0.0,
        0.0,
        0.0,
        1.0,
        1.0,
        1.0,
        0.0,
        1.0,
        0.0,
        0.0,
        0.0,
        0.0,
        -1.0,
        0.0,
        1.0,
        1.0,
        1.0,
        0.0,
        1.0,
        0.6,
        0.8,
        1.0,
        1.0,
        0.0,
        0.0,
        arg_number(args, 7, 0.0),
        arg_number(args, 8, 0.0),
        0.0,
        0.0,
        0.0,
        0.0,
        1.0,
        0.0,
        arg_number(args, 17, 1),
      )
      if state.gpu.profile_enabled {
        let elapsed_ms = performance_now() - start_ms
        state.gpu.profile_api_begin_pass_ms_accum = state.gpu.profile_api_begin_pass_ms_accum +
          elapsed_ms
      }
    }),
  )
  let gpu_begin_pass_3d = wrap_variadic(
    @js.from_fn1(fn(args) {
      let camera_rot_x = arg_number(args, 10, 0)
      let camera_rot_y = arg_number(args, 11, 0)
      let camera_rot_z = arg_number(args, 12, 0)
      let camera_rot_w = arg_number(args, 13, 1)
      let siny_cosp = 2.0 *
        (camera_rot_w * camera_rot_z + camera_rot_x * camera_rot_y)
      let cosy_cosp = 1.0 -
        2.0 * (camera_rot_y * camera_rot_y + camera_rot_z * camera_rot_z)
      begin_pass(
        state,
        to_int(arg_number(args, 0, -1)),
        arg_number(args, 1, 1),
        arg_number(args, 2, 1),
        arg_number(args, 3, 0),
        arg_number(args, 4, 0),
        arg_number(args, 5, 0),
        arg_number(args, 6, 1),
        arg_number(args, 7, 0),
        arg_number(args, 8, 0),
        math_atan2(siny_cosp, cosy_cosp),
        1.0,
        true,
        arg_number(args, 9, 0),
        camera_rot_x,
        camera_rot_y,
        camera_rot_z,
        camera_rot_w,
        arg_number(args, 14, 1.5707963267948966),
        arg_number(args, 15, 0.1),
        arg_number(args, 16, 1000.0),
        arg_number(args, 17, 0),
        arg_number(args, 18, 0),
        arg_number(args, 19, 0),
        arg_number(args, 20, 0),
        0.0,
        1.0,
        arg_number(args, 21, 1),
        arg_number(args, 22, 1),
        arg_number(args, 23, 1),
        arg_number(args, 24, 0),
        arg_number(args, 25, 0),
        arg_number(args, 26, -1),
        arg_number(args, 27, 0),
        arg_number(args, 28, 1),
        arg_number(args, 29, 1),
        arg_number(args, 30, 1),
        arg_number(args, 31, 0),
        arg_number(args, 32, 0),
        arg_number(args, 33, 0),
        arg_number(args, 34, 0),
        arg_number(args, 35, 1),
        arg_number(args, 36, 1),
        arg_number(args, 37, 1),
        arg_number(args, 38, 0),
        arg_number(args, 39, 1),
        arg_number(args, 40, 0),
        arg_number(args, 41, 0),
        arg_number(args, 42, 0),
        arg_number(args, 43, 0),
        arg_number(args, 44, -1),
        arg_number(args, 45, 0),
        arg_number(args, 46, 1),
        arg_number(args, 47, 1),
        arg_number(args, 48, 1),
        arg_number(args, 49, 0),
        arg_number(args, 50, 1),
        arg_number(args, 51, 0.6),
        arg_number(args, 52, 0.8),
        arg_number(args, 53, 1.0),
        arg_number(args, 54, 1.0),
        arg_number(args, 55, 0.0),
        arg_number(args, 56, 0.0),
        arg_number(args, 57, arg_number(args, 7, 0.0)),
        arg_number(args, 58, arg_number(args, 8, 0.0)),
        arg_number(args, 59, arg_number(args, 9, 0.0)),
        arg_number(args, 60, camera_rot_x),
        arg_number(args, 61, camera_rot_y),
        arg_number(args, 62, camera_rot_z),
        arg_number(args, 63, camera_rot_w),
        arg_number(args, 64, 0.0),
        arg_number(args, 65, 1),
      )
    }),
  )
  let gpu_set_scissor = wrap_variadic(
    @js.from_fn1(fn(args) {
      if state.gpu.profile_enabled {
        state.gpu.profile_scissor_set_calls_accum = state.gpu.profile_scissor_set_calls_accum +
          1
      }
      if state.gpu.current_pass is None {
        return
      }
      flush_ui_shadow_batches(state)
      flush_ui_slice_batches(state)
      flush_ui_batches(state)
      flush_sprite_batches(state)
      if state.gpu.current_pass is Some(pass) {
        pass.set_scissor_rect(
          to_int(arg_number(args, 0, 0)),
          to_int(arg_number(args, 1, 0)),
          to_int(arg_number(args, 2, 0)),
          to_int(arg_number(args, 3, 0)),
        )
      }
    }),
  )
  let gpu_clear_scissor = @js.from_fn0(fn() {
    if state.gpu.profile_enabled {
      state.gpu.profile_scissor_clear_calls_accum = state.gpu.profile_scissor_clear_calls_accum +
        1
    }
    if state.gpu.current_pass is None || state.gpu.current_pass_info is None {
      return
    }
    flush_ui_shadow_batches(state)
    flush_ui_slice_batches(state)
    flush_ui_batches(state)
    flush_sprite_batches(state)
    if state.gpu.current_pass is Some(pass) &&
      state.gpu.current_pass_info is Some(info) {
      pass.set_scissor_rect(
        to_int(info.viewport_x),
        to_int(info.viewport_y),
        to_int(info.viewport_width),
        to_int(info.viewport_height),
      )
    }
  })
  let gpu_draw_sprite = wrap_variadic(
    @js.from_fn1(fn(args) {
      draw_sprite(
        state,
        to_int(arg_number(args, 0, 0)),
        arg_number(args, 1, 0),
        arg_number(args, 2, 0),
        arg_number(args, 3, 0),
        arg_number(args, 4, 1),
        arg_number(args, 5, 1),
        arg_number(args, 6, 1),
        arg_number(args, 7, 1),
        arg_number(args, 8, 1),
        arg_number(args, 9, 1),
      )
    }),
  )
  let gpu_draw_sprite_uv = wrap_variadic(
    @js.from_fn1(fn(args) {
      let start_ms = if state.gpu.profile_enabled {
        performance_now()
      } else {
        0.0
      }
      draw_sprite_uv(
        state,
        to_int(arg_number(args, 0, 0)),
        arg_number(args, 1, 0),
        arg_number(args, 2, 0),
        arg_number(args, 3, 0),
        arg_number(args, 4, 1),
        arg_number(args, 5, 1),
        arg_number(args, 6, 1),
        arg_number(args, 7, 1),
        arg_number(args, 8, 1),
        arg_number(args, 9, 1),
        arg_number(args, 10, 0),
        arg_number(args, 11, 0),
        arg_number(args, 12, 1),
        arg_number(args, 13, 1),
      )
      if state.gpu.profile_enabled {
        let elapsed_ms = performance_now() - start_ms
        state.gpu.profile_api_draw_sprite_uv_ms_accum = state.gpu.profile_api_draw_sprite_uv_ms_accum +
          elapsed_ms
      }
    }),
  )
  let gpu_draw_ui_rect = wrap_variadic(
    @js.from_fn1(fn(args) {
      draw_ui_rect(
        state,
        to_int(arg_number(args, 0, 0)),
        arg_number(args, 1, 0),
        arg_number(args, 2, 0),
        arg_number(args, 3, 0),
        arg_number(args, 4, 1),
        arg_number(args, 5, 1),
        arg_number(args, 6, 1),
        arg_number(args, 7, 1),
        arg_number(args, 8, 1),
        arg_number(args, 9, 1),
        arg_number(args, 10, 0),
        arg_number(args, 11, 0),
        arg_number(args, 12, 1),
        arg_number(args, 13, 1),
        arg_number(args, 14, 0),
        arg_number(args, 15, 0),
        arg_number(args, 16, 0),
        arg_number(args, 17, 0),
        arg_number(args, 18, 0),
        arg_number(args, 19, 0),
        arg_number(args, 20, 0),
        arg_number(args, 21, 0),
        arg_number(args, 22, 0),
      )
    }),
  )
  let gpu_draw_ui_texture_slice = wrap_variadic(
    @js.from_fn1(fn(args) {
      draw_ui_texture_slice(
        state,
        to_int(arg_number(args, 0, 0)),
        arg_number(args, 1, 0),
        arg_number(args, 2, 0),
        arg_number(args, 3, 0),
        arg_number(args, 4, 1),
        arg_number(args, 5, 1),
        arg_number(args, 6, 1),
        arg_number(args, 7, 1),
        arg_number(args, 8, 1),
        arg_number(args, 9, 1),
        arg_number(args, 10, 0),
        arg_number(args, 11, 0),
        arg_number(args, 12, 0),
        arg_number(args, 13, 0),
        arg_number(args, 14, 0),
        arg_number(args, 15, 0),
        arg_number(args, 16, 0),
        arg_number(args, 17, 0),
        arg_number(args, 18, 0),
        arg_number(args, 19, 0),
        arg_number(args, 20, 0),
        arg_number(args, 21, 0),
        arg_number(args, 22, 0),
        arg_number(args, 23, 0),
        arg_number(args, 24, 1),
        arg_number(args, 25, 1),
      )
    }),
  )
  let gpu_draw_ui_box_shadow = wrap_variadic(
    @js.from_fn1(fn(args) {
      draw_ui_box_shadow(
        state,
        to_int(arg_number(args, 0, 0)),
        arg_number(args, 1, 0),
        arg_number(args, 2, 0),
        arg_number(args, 3, 0),
        arg_number(args, 4, 1),
        arg_number(args, 5, 1),
        arg_number(args, 6, 1),
        arg_number(args, 7, 1),
        arg_number(args, 8, 1),
        arg_number(args, 9, 1),
        arg_number(args, 10, 0),
        arg_number(args, 11, 0),
        arg_number(args, 12, 0),
        arg_number(args, 13, 0),
        arg_number(args, 14, 0),
        arg_number(args, 15, 0),
        arg_number(args, 16, 0),
        arg_number(args, 17, 4),
      )
    }),
  )
  let gpu_draw_mesh = wrap_variadic(
    @js.from_fn1(fn(args) {
      draw_mesh(
        state,
        to_int(arg_number(args, 0, 0)),
        arg_number(args, 1, 0),
        arg_number(args, 2, 0),
        arg_number(args, 3, 0),
        arg_number(args, 4, 1),
        arg_number(args, 5, 1),
        arg_number(args, 6, 1),
        arg_number(args, 7, 1),
        arg_number(args, 8, 1),
        arg_number(args, 9, 1),
        to_int(arg_number(args, 10, -1)),
        arg_number(args, 11, 0),
        arg_number(args, 12, 0),
        arg_number(args, 13, 1),
        arg_number(args, 14, 1),
      )
    }),
  )
  let gpu_draw_mesh3d = wrap_variadic(
    @js.from_fn1(fn(args) {
      draw_mesh3d(
        state,
        to_int(arg_number(args, 0, 0)),
        arg_number(args, 1, 0),
        arg_number(args, 2, 0),
        arg_number(args, 3, 0),
        arg_number(args, 4, 0),
        arg_number(args, 5, 0),
        arg_number(args, 6, 0),
        arg_number(args, 7, 1),
        arg_number(args, 8, 1),
        arg_number(args, 9, 1),
        arg_number(args, 10, 1),
        arg_number(args, 11, arg_number(args, 1, 0.0)),
        arg_number(args, 12, arg_number(args, 2, 0.0)),
        arg_number(args, 13, arg_number(args, 3, 0.0)),
        arg_number(args, 14, arg_number(args, 4, 0.0)),
        arg_number(args, 15, arg_number(args, 5, 0.0)),
        arg_number(args, 16, arg_number(args, 6, 0.0)),
        arg_number(args, 17, arg_number(args, 7, 1.0)),
        arg_number(args, 18, arg_number(args, 8, 1.0)),
        arg_number(args, 19, arg_number(args, 9, 1.0)),
        arg_number(args, 20, arg_number(args, 10, 1.0)),
        arg_number(args, 21, 1),
        arg_number(args, 22, 1),
        arg_number(args, 23, 1),
        arg_number(args, 24, 1),
        to_int(arg_number(args, 25, -1)),
        arg_number(args, 26, 0),
        arg_number(args, 27, 0),
        arg_number(args, 28, 1),
        arg_number(args, 29, 1),
        to_int(arg_number(args, 30, -1)),
        to_int(arg_number(args, 31, -1)),
        to_int(arg_number(args, 32, -1)),
        to_int(arg_number(args, 33, -1)),
        to_int(arg_number(args, 34, -1)),
        arg_number(args, 35, 0),
        arg_number(args, 36, 0),
        arg_number(args, 37, 0),
        arg_number(args, 38, 0),
        arg_number(args, 39, 0),
        arg_number(args, 40, 0.5),
        arg_number(args, 41, 0.5),
        arg_number(args, 42, 0),
        arg_number(args, 43, 0),
        arg_number(args, 44, 0),
        to_int(arg_number(args, 45, -1)),
        arg_number(args, 46, 0),
        arg_number(args, 47, 0),
        to_int(arg_number(args, 48, -1)),
        arg_number(args, 49, 1),
        arg_number(args, 50, 1),
        arg_number(args, 51, 1),
        arg_number(args, 52, 0),
        arg_number(args, 53, 0),
        arg_number(args, 54, 0),
        arg_number(args, 55, 1.5),
        to_int(arg_number(args, 56, -1)),
        arg_number(args, 57, 0),
        arg_number(args, 58, 0),
      )
    }),
  )
  let gpu_draw_motion_blur = wrap_variadic(
    @js.from_fn1(fn(args) {
      draw_motion_blur(
        state,
        to_int(arg_number(args, 0, -1)),
        to_int(arg_number(args, 1, -1)),
        arg_number(args, 2, 0.0),
        to_int(arg_number(args, 3, 0)),
      )
    }),
  )
  let gpu_draw_bloom2d = wrap_variadic(
    @js.from_fn1(fn(args) {
      draw_bloom2d(
        state,
        to_int(arg_number(args, 0, -1)),
        to_int(arg_number(args, 1, 1)),
        arg_number(args, 2, 0.15),
        arg_number(args, 3, 0.7),
        arg_number(args, 4, 0.95),
        arg_number(args, 5, 1.0),
        arg_number(args, 6, 0.0),
        arg_number(args, 7, 0.0),
        to_int(arg_number(args, 8, 0)),
        to_int(arg_number(args, 9, 512)),
        arg_number(args, 10, 1.0),
        arg_number(args, 11, 1.0),
        to_int(arg_number(args, 12, 0)),
        to_int(arg_number(args, 13, 0)),
        to_int(arg_number(args, 14, 1)),
        to_int(arg_number(args, 15, 1)),
        to_int(arg_number(args, 16, -1)),
        to_int(arg_number(args, 17, -1)),
        to_int(arg_number(args, 18, -1)),
      )
    }),
  )
  let gpu_draw_gizmo_line = wrap_variadic(
    @js.from_fn1(fn(args) {
      push_gizmo_line(
        state.gpu.gizmo_lines,
        arg_number(args, 0, 0),
        arg_number(args, 1, 0),
        arg_number(args, 2, 1),
        arg_number(args, 3, 1),
        arg_number(args, 4, 1),
        arg_number(args, 5, 1),
        arg_number(args, 6, 0),
        arg_number(args, 7, 0),
        arg_number(args, 8, 1),
        arg_number(args, 9, 1),
        arg_number(args, 10, 1),
        arg_number(args, 11, 1),
        arg_number(args, 12, 2),
        to_int(arg_number(args, 13, 0)),
        arg_number(args, 14, 1),
        arg_number(args, 15, 1),
      )
    }),
  )
  let gpu_end_pass = @js.from_fn0(fn() {
    let start_ms = if state.gpu.profile_enabled {
      performance_now()
    } else {
      0.0
    }
    if state.gpu.current_pass is Some(_) {
      flush_ui_shadow_batches(state)
      flush_ui_slice_batches(state)
      flush_ui_batches(state)
      flush_sprite_batches(state)
      draw_gizmo_lines(state, state.gpu.gizmo_lines)
    }
    if state.gpu.current_pass is Some(pass) {
      pass.end()
    }
    state.gpu.current_pass = None
    state.gpu.current_pass_info = None
    state.gpu.gizmo_lines = new_array()
    if state.gpu.profile_enabled {
      let elapsed_ms = performance_now() - start_ms
      state.gpu.profile_api_end_pass_ms_accum = state.gpu.profile_api_end_pass_ms_accum +
        elapsed_ms
    }
  })
  let gpu_end_frame = @js.from_fn1(fn(_ : @js.Any) {
    let start_ms = if state.gpu.profile_enabled {
      performance_now()
    } else {
      0.0
    }
    if state.gpu.device is None ||
      state.gpu.queue is None ||
      state.gpu.encoder is None {
      if state.gpu.profile_enabled {
        let elapsed_ms = performance_now() - start_ms
        state.gpu.profile_api_end_frame_ms_accum = state.gpu.profile_api_end_frame_ms_accum +
          elapsed_ms
      }
      return
    }
    if state.gpu.current_pass is Some(pass) {
      flush_ui_shadow_batches(state)
      flush_ui_slice_batches(state)
      flush_ui_batches(state)
      flush_sprite_batches(state)
      pass.end()
    }
    if state.gpu.encoder is Some(encoder) &&
      state.gpu.queue is Some(queue) &&
      state.gpu.device is Some(device) {
      queue.submit([encoder.finish()])
      let frame_error_promise = device.pop_error_scope()
      @js.run_async(async fn() noraise {
        let err_any : @js.Any = frame_error_promise.wait() catch {
          _ => js_null()
        }
        if !host_is_nullish(err_any) {
          report_asset_error_once(
            state,
            "frame_validation_error",
            "WebGPU frame validation error: " + any_to_string(err_any),
          )
        }
      })
    }
    if state.gpu.profile_enabled {
      let frame_end_ms = performance_now()
      state.gpu.profile_frames_accum = state.gpu.profile_frames_accum + 1
      if state.gpu.profile_frame_begin_ms > 0.0 &&
        frame_end_ms >= state.gpu.profile_frame_begin_ms {
        state.gpu.profile_frame_cpu_ms_accum = state.gpu.profile_frame_cpu_ms_accum +
          (frame_end_ms - state.gpu.profile_frame_begin_ms)
      }
      profile_log_if_needed(state)
    }
    state.gpu.encoder = None
    state.gpu.current_texture = None
    state.gpu.current_pass = None
    state.gpu.current_pass_info = None
    if state.gpu.profile_enabled {
      let elapsed_ms = performance_now() - start_ms
      state.gpu.profile_api_end_frame_ms_accum = state.gpu.profile_api_end_frame_ms_accum +
        elapsed_ms
    }
  })
  let mgstudio_host = @js.from_entries([
    ("window_create", window_create),
    ("window_poll_events", window_poll_events),
    ("window_get_width", window_get_width),
    ("window_get_height", window_get_height),
    ("window_get_scale_factor", window_get_scale_factor),
    ("window_should_close", window_should_close),
    ("window_request_close", window_request_close),
    ("window_run_loop", window_run_loop),
    ("window_set_title", window_set_title),
    ("window_set_size", window_set_size),
    ("window_set_resizable", window_set_resizable),
    ("window_set_cursor_visible", window_set_cursor_visible),
    ("window_set_cursor_grab_mode", window_set_cursor_grab_mode),
    ("window_set_mode", window_set_mode),
    ("window_set_position", window_set_position),
    ("window_get_position_x", window_get_position_x),
    ("window_get_position_y", window_get_position_y),
    ("time_now", time_now),
    ("input_gamepad_poll", input_gamepad_poll),
    ("input_gamepad_count", input_gamepad_count),
    ("input_gamepad_id", input_gamepad_id),
    ("input_gamepad_connected", input_gamepad_connected),
    ("input_gamepad_name_len", input_gamepad_name_len),
    ("input_gamepad_name_code_unit", input_gamepad_name_code_unit),
    ("input_gamepad_vendor_id", input_gamepad_vendor_id),
    ("input_gamepad_product_id", input_gamepad_product_id),
    ("input_gamepad_button_value", input_gamepad_button_value),
    ("input_gamepad_button_pressed", input_gamepad_button_pressed),
    ("input_gamepad_axis_value", input_gamepad_axis_value),
    ("input_is_key_down", input_is_key_down),
    ("input_is_key_just_pressed", input_is_key_just_pressed),
    ("input_is_key_just_released", input_is_key_just_released),
    ("input_is_key_repeated", input_is_key_repeated),
    ("input_text_event_count", input_text_event_count),
    ("input_text_event_len", input_text_event_len),
    ("input_text_event_code_unit", input_text_event_code_unit),
    ("input_finish_frame", input_finish_frame),
    ("input_is_mouse_button_down", input_is_mouse_button_down),
    ("input_is_mouse_button_just_pressed", input_is_mouse_button_just_pressed),
    ("input_is_mouse_button_just_released", input_is_mouse_button_just_released),
    ("input_mouse_x", input_mouse_x),
    ("input_mouse_y", input_mouse_y),
    ("input_wheel_x", input_wheel_x),
    ("input_wheel_y", input_wheel_y),
    ("input_has_cursor", input_has_cursor),
    ("input_touch_event_count", input_touch_event_count),
    ("input_touch_event_id", input_touch_event_id),
    ("input_touch_event_phase", input_touch_event_phase),
    ("input_touch_event_x", input_touch_event_x),
    ("input_touch_event_y", input_touch_event_y),
    ("debug_string", debug_string),
    ("a11y_begin_update", a11y_begin_update),
    ("a11y_push_node", a11y_push_node),
    ("a11y_end_update", a11y_end_update),
    ("a11y_apply_update", a11y_apply_update),
    ("a11y_actions_len", a11y_actions_len),
    ("a11y_action_target", a11y_action_target),
    ("a11y_action_kind", a11y_action_kind),
    ("a11y_action_value_len", a11y_action_value_len),
    ("a11y_action_value_code_unit", a11y_action_value_code_unit),
    ("a11y_actions_clear", a11y_actions_clear),
    ("gpu_request_device", gpu_request_device),
    ("gpu_get_queue", gpu_get_queue),
    ("gpu_create_surface", gpu_create_surface),
    ("gpu_configure_surface", gpu_configure_surface),
    ("gpu_set_scissor", gpu_set_scissor),
    ("gpu_clear_scissor", gpu_clear_scissor),
    ("string_sink_reset", string_sink_reset),
    (
      "string_sink_push",
      @js.from_fn1(fn(code_unit) {
        string_sink_push(to_int(number_or(code_unit, 0)))
        0
      }),
    ),
    ("string_sink_take", string_sink_take),
    ("string_drop", string_drop),
    ("bytes_sink_reset", bytes_sink_reset),
    (
      "bytes_sink_push",
      @js.from_fn1(fn(byte_any) {
        bytes_sink_push_js(to_int(number_or(byte_any, 0)))
        0
      }),
    ),
    (
      "bytes_sink_push_u32",
      @js.from_fn1(fn(word_any) {
        bytes_sink_push_u32_js(to_int(number_or(word_any, 0)))
        0
      }),
    ),
    ("bytes_sink_take", bytes_sink_take),
    ("bytes_drop", bytes_drop),
    ("asset_load_texture", asset_load_texture),
    ("asset_load_texture_bytes", asset_load_texture_bytes),
    ("asset_load_wgsl", asset_load_wgsl),
    ("asset_load_font", asset_load_font),
    ("asset_load_bytes", asset_load_bytes),
    ("asset_font_bytes_len", asset_font_bytes_len),
    ("asset_font_bytes_get", asset_font_bytes_get),
    ("asset_font_bytes_get_u32", asset_font_bytes_get_u32),
    ("asset_bytes_len", asset_bytes_len),
    ("asset_bytes_get_u32", asset_bytes_get_u32),
    ("font_rasterize_glyph", font_rasterize_glyph),
    ("font_glyph_width", font_glyph_width),
    ("font_glyph_height", font_glyph_height),
    ("font_glyph_offset_x", font_glyph_offset_x),
    ("font_glyph_offset_y", font_glyph_offset_y),
    ("font_measure_advance", font_measure_advance),
    ("asset_set_texture_sampler", asset_set_texture_sampler),
    ("asset_create_dynamic_texture", asset_create_dynamic_texture),
    ("asset_create_dynamic_texture_mipped", asset_create_dynamic_texture_mipped),
    ("asset_update_texture_region", asset_update_texture_region),
    ("asset_update_texture_region_bytes", asset_update_texture_region_bytes),
    (
      "asset_update_texture_region_mip_bytes", asset_update_texture_region_mip_bytes,
    ),
    ("asset_create_texture_mip_view", asset_create_texture_mip_view),
    ("asset_texture_width", asset_texture_width),
    ("asset_texture_height", asset_texture_height),
    ("asset_is_texture_loaded", asset_is_texture_loaded),
    ("asset_supported_compressed_image_formats", asset_supported_formats),
    ("asset_copy_texture_to_texture", asset_copy_texture_to_texture),
    ("asset_load_folder", asset_load_folder),
    ("asset_poll_loaded_folder_event_kind", asset_poll_loaded_folder_event_kind),
    ("asset_poll_loaded_folder_event_id", asset_poll_loaded_folder_event_id),
    ("asset_loaded_folder_handles_len", asset_loaded_folder_handles_len),
    ("asset_loaded_folder_handles_get", asset_loaded_folder_handles_get),
    ("gpu_create_render_target", gpu_create_render_target),
    ("gpu_create_render_target_rgba16f", gpu_create_render_target_rgba16f),
    ("gpu_create_mesh_capsule", gpu_create_mesh_capsule),
    ("gpu_create_mesh_rectangle", gpu_create_mesh_rectangle),
    ("gpu_create_mesh_triangles", gpu_create_mesh_triangles),
    ("gpu_create_mesh3d", gpu_create_mesh3d),
    ("gpu_create_mesh_triangles3d", gpu_create_mesh_triangles3d),
    ("gpu_begin_frame", gpu_begin_frame),
    ("gpu_begin_pass", gpu_begin_pass),
    ("gpu_begin_pass_3d", gpu_begin_pass_3d),
    ("gpu_draw_sprite", gpu_draw_sprite),
    ("gpu_draw_sprite_uv", gpu_draw_sprite_uv),
    ("gpu_draw_ui_rect", gpu_draw_ui_rect),
    ("gpu_draw_ui_texture_slice", gpu_draw_ui_texture_slice),
    ("gpu_draw_ui_box_shadow", gpu_draw_ui_box_shadow),
    ("gpu_draw_mesh", gpu_draw_mesh),
    ("gpu_draw_mesh3d", gpu_draw_mesh3d),
    ("gpu_draw_motion_blur", gpu_draw_motion_blur),
    ("gpu_draw_bloom2d", gpu_draw_bloom2d),
    ("gpu_draw_gizmo_line", gpu_draw_gizmo_line),
    ("gpu_end_pass", gpu_end_pass),
    ("gpu_end_frame", gpu_end_frame),
  ])
  let init = @js.from_fn0(fn() {
    @js.Promise::new(async fn(resolve, reject) {
      let target = default_canvas
      // Ensure async host initialization completes before the guest starts.
      // Some examples (mesh2d/text2d) create GPU resources during startup; if the
      // device isn't ready yet, host imports throw and the guest will crash.
      init_webgpu(state, target) catch {
        err => {
          let msg = "mgstudio-runtime-web init_webgpu failed: " +
            err.to_string()
          console_error(@js.any(msg))
          dispatch_asset_error(msg)
          reject(err)
          return
        }
      }
      init_input(state)
      init_data_source(state)
      if state.data_db is Some(_) {
        @js.log(@js.any("mgstudio-runtime-web data-source ready (IndexedDB)"))
      }
      resolve(())
    })
  })
  @js.from_entries([("mgstudio_host", mgstudio_host), ("init", init)])
}
