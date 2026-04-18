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
test "windowing_native wbtest: gesture event queues expose host deltas and clear per frame" {
  input_finish_frame()

  push_pinch_gesture_event(101, 1.5)
  push_rotation_gesture_event(102, -0.75)
  push_pan_gesture_event(103, 3.25, -2.5)
  push_double_tap_gesture_event(104)

  assert_eq(input_pinch_gesture_event_count(), 1)
  assert_eq(input_pinch_gesture_event_window(index=0), 101)
  assert_eq(input_pinch_gesture_event_delta(index=0), 1.5)

  assert_eq(input_rotation_gesture_event_count(), 1)
  assert_eq(input_rotation_gesture_event_window(index=0), 102)
  assert_eq(input_rotation_gesture_event_delta(index=0), -0.75)

  assert_eq(input_pan_gesture_event_count(), 1)
  assert_eq(input_pan_gesture_event_window(index=0), 103)
  assert_eq(input_pan_gesture_event_x(index=0), 3.25)
  assert_eq(input_pan_gesture_event_y(index=0), -2.5)

  assert_eq(input_double_tap_gesture_event_count(), 1)
  assert_eq(input_double_tap_gesture_event_window(index=0), 104)

  input_finish_frame()

  assert_eq(input_pinch_gesture_event_count(), 0)
  assert_eq(input_rotation_gesture_event_count(), 0)
  assert_eq(input_pan_gesture_event_count(), 0)
  assert_eq(input_double_tap_gesture_event_count(), 0)
}

///|
test "windowing_native wbtest: cursor grab mode setter reports unknown window failure" {
  debug_inspect(
    set_cursor_grab_mode(-1, mode=@window_core.CursorGrabMode::Locked),
    content="false",
  )
  debug_inspect(
    set_cursor_grab_mode(-1, mode=@window_core.CursorGrabMode::Confined),
    content="false",
  )
}

///|
test "windowing_native wbtest: raw winit event snapshots preserve typed payloads" {
  ignore(take_raw_winit_window_events())

  process_window_event(
    7,
    ScaleFactorChanged(
      2.0,
      @window_core.SurfaceSizeWriter::new(
        @window_dpi.PhysicalSize::new(640, 360),
      ),
    ),
  )
  process_window_event(
    9,
    DragEntered(
      ["/tmp/winit_a.txt", "/tmp/winit_b.txt"],
      @window_dpi.PhysicalPositionF64::new(10.0, 20.0),
    ),
  )
  process_window_event(
    9,
    DragMoved(@window_dpi.PhysicalPositionF64::new(12.0, 22.0)),
  )

  let events = take_raw_winit_window_events()
  assert_eq(events.length(), 3)
  assert_eq(events[0].window_id, 7)
  match events[0].event {
    ScaleFactorChanged(scale_factor, surface_size) => {
      assert_eq(scale_factor, 2.0)
      assert_eq(surface_size, @window_dpi.PhysicalSize::new(640, 360))
    }
    _ => abort("expected ScaleFactorChanged snapshot")
  }

  assert_eq(events[1].window_id, 9)
  match events[1].event {
    HoveredFile(path) => debug_inspect(path, content="\"/tmp/winit_a.txt\"")
    _ => abort("expected first HoveredFile snapshot")
  }

  assert_eq(events[2].window_id, 9)
  match events[2].event {
    HoveredFile(path) => debug_inspect(path, content="\"/tmp/winit_b.txt\"")
    _ => abort("expected second HoveredFile snapshot")
  }

  assert_eq(take_raw_winit_window_events().length(), 0)
}

///|
test "windowing_native wbtest: clear-all-keys resets pressed and transition state" {
  let key_id = input_key_id_from_key_code(KeyA)
  bool_state_set(key_down_ref.val, key_id, true)
  bool_state_set(key_just_pressed_ref.val, key_id, true)
  bool_state_set(key_just_released_ref.val, key_id, true)
  bool_state_set(key_repeated_ref.val, key_id, true)

  input_clear_all_keys()

  assert_false(input_is_key_down_by_id(key_id))
  assert_false(input_is_key_just_pressed_by_id(key_id))
  assert_false(input_is_key_just_released_by_id(key_id))
  assert_false(input_is_key_repeated_by_id(key_id))
}

///|
test "windowing_native wbtest: any-thread preference is applied on event loop creation" {
  match native_event_loop_ref.val {
    Some(event_loop) => {
      event_loop.drop()
      native_event_loop_ref.val = None
    }
    None => ()
  }

  set_event_loop_any_thread(true)
  debug_inspect(event_loop_any_thread_requested(), content="true")
  ignore(ensure_native_event_loop())
  debug_inspect(event_loop_any_thread_applied(), content="true")

  match native_event_loop_ref.val {
    Some(event_loop) => {
      event_loop.drop()
      native_event_loop_ref.val = None
    }
    None => ()
  }
  set_event_loop_any_thread(false)
}
