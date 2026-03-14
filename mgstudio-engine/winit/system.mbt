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
fn winit_write_raw_winit_window_events(
  world : @ecs.World,
  events : Array[@windowing.RawWinitWindowEventSnapshot],
) -> Unit {
  if events.length() == 0 {
    return
  }
  let writer = world.message_writer(ecs_key_raw_winit_window_event)
  for event in events {
    ignore(
      writer.write(RawWinitWindowEvent::{
        window_id: event.window_id,
        event: event.event,
      }),
    )
  }
}

///|
pub fn winit_window_backend_sync_system(world : @ecs.World) -> Unit {
  @window.window_backend_prepare_system(world)
  winit_write_raw_winit_window_events(
    world,
    @windowing.take_raw_winit_window_events(),
  )
}

///|
pub fn winit_changed_windows_system(world : @ecs.World) -> Unit {
  @window.window_backend_apply_requested_system(world)
}

///|
pub fn winit_check_keyboard_focus_lost_system(world : @ecs.World) -> Unit {
  @input.input_check_keyboard_focus_lost_system(world)
}

///|
pub fn winit_runner_builder(app : @app.App[@ecs.World]) -> @app.RunnerFn {
  @window.window_runner_builder(app)
}
