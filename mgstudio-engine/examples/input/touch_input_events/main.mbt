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
/// Port of `bevy/examples/input/touch_input_events.rs`.
///
/// Baseline parity:
/// - Uses `MessageReader<TouchInput>` with Bevy-like event iteration.
/// - Runtime touch host events are not wired yet, so no touch events are emitted.

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_system(@app.system_param(touch_event_system))
  .run()
}

///|
fn touch_event_system(
  touch_inputs : @ecs.MessageReader[@input.TouchInput],
) -> Unit {
  for touch_input in (try! touch_inputs.read()) {
    log_line(format_touch_input(touch_input))
  }
}

///|
fn format_touch_input(touch_input : @input.TouchInput) -> String {
  "TouchInput { id: \{touch_input.id}, phase: \{format_touch_phase(touch_input.phase)}, position: \{format_vec2(touch_input.position)} }"
}

///|
fn format_touch_phase(phase : @input.TouchPhase) -> String {
  match phase {
    @input.TouchPhase::Started => "Started"
    @input.TouchPhase::Moved => "Moved"
    @input.TouchPhase::Ended => "Ended"
    @input.TouchPhase::Canceled => "Canceled"
  }
}

///|
fn format_vec2(v : @math.Vec2) -> String {
  "(\{v.x}, \{v.y})"
}

///|
fn log_line(text : String) -> Unit {
  @window.host_debug_string(value="[touch_input_events] " + text)
}
