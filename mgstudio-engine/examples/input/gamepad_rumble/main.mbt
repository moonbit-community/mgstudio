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
/// Port of `bevy/examples/input/gamepad_rumble.rs`.
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Update, @app.system(@app.system_param2(gamepad_system)))
  .run()
}

///|
fn gamepad_system(
  gamepads : @ecs.Query1[@input.Gamepad],
  rumble_requests : @ecs.MessageWriter[@input.GamepadRumbleRequest],
) -> Unit {
  try! gamepads.view(fn(entity, gamepad) {
    if gamepad.just_pressed(@input.GamepadButton::North) {
      log_line(
        "North face button: strong (low-frequency) with low intensity for rumble for 5 seconds. Press multiple times to increase intensity.",
      )
      ignore(
        rumble_requests.write(
          @input.GamepadRumbleRequest::Add(
            gamepad=entity,
            intensity=@input.GamepadRumbleIntensity::strong_motor(0.1F),
            duration=@core.Duration::from_secs(5L),
          ),
        ),
      )
    }

    if gamepad.just_pressed(@input.GamepadButton::East) {
      log_line("East face button: maximum rumble on both motors for 5 seconds")
      ignore(
        rumble_requests.write(
          @input.GamepadRumbleRequest::Add(
            gamepad=entity,
            duration=@core.Duration::from_secs(5L),
            intensity=@input.GamepadRumbleIntensity::max(),
          ),
        ),
      )
    }

    if gamepad.just_pressed(@input.GamepadButton::South) {
      log_line(
        "South face button: low-intensity rumble on the weak motor for 0.5 seconds",
      )
      ignore(
        rumble_requests.write(
          @input.GamepadRumbleRequest::Add(
            gamepad=entity,
            duration=@core.Duration::from_secs_f32(0.5F),
            intensity=@input.GamepadRumbleIntensity::weak_motor(0.25F),
          ),
        ),
      )
    }

    if gamepad.just_pressed(@input.GamepadButton::West) {
      log_line("West face button: custom rumble intensity for 5 second")
      ignore(
        rumble_requests.write(
          @input.GamepadRumbleRequest::Add(
            gamepad=entity,
            intensity=@input.GamepadRumbleIntensity::{
              strong_motor: 0.5F,
              weak_motor: 0.25F,
            },
            duration=@core.Duration::from_secs(5L),
          ),
        ),
      )
    }

    if gamepad.just_pressed(@input.GamepadButton::Start) {
      log_line("Start button: Interrupt the current rumble")
      ignore(
        rumble_requests.write(@input.GamepadRumbleRequest::Stop(gamepad=entity)),
      )
    }
  })
}

///|
fn log_line(text : String) -> Unit {
  @window.host_debug_string(value="[gamepad_rumble] " + text)
}
