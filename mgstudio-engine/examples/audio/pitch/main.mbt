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
struct PlayPitch {}

///|
struct PitchFrequency {
  mut value : Float
}

///|
let play_pitch_message_key : @ecs.MessageKey[PlayPitch] = @ecs.register_message(
  debug_name="examples.audio.pitch.PlayPitch",
)

///|
let pitch_frequency_resource_key : @ecs.ResourceKey[PitchFrequency] = @ecs.register_resource(
  debug_name="examples.audio.pitch.PitchFrequency",
)

///|
pub impl @ecs.Message for PlayPitch with message() {
  play_pitch_message_key
}

///|
pub impl Default for PlayPitch with default() {
  PlayPitch::{  }
}

///|
pub impl @app.Resource for PitchFrequency with resource() {
  pitch_frequency_resource_key
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.default_plugins())
  .add_message(play_pitch_message_key)
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(@app.Update, @app.system(@app.system_param4(play_pitch)))
  .add_systems(
    @app.Update,
    @app.system(@app.system_param3(keyboard_input_system)),
  )
  .run()
}

///|
fn setup(world : @ecs.World) -> Unit {
  world.insert_resource(PitchFrequency::resource(), PitchFrequency::{
    value: 220.0F,
  })
}

///|
fn play_pitch(
  pitch_assets : @app.ResMut[@audio.PitchAssets],
  frequency : @app.Res[PitchFrequency],
  play_pitch_reader : @ecs.MessageReader[PlayPitch],
  commands : @app.Commands,
) -> Unit {
  for _ in (try! play_pitch_reader.read()) {
    let current_frequency = frequency.get().value
    @app.log_info("playing pitch with frequency: \{current_frequency}")
    let handle = pitch_assets.get_ref().val.add(
      @audio.Pitch::new(current_frequency, 1.0F),
    )
    commands.spawn(
      (@audio.AudioPlayer::new(handle), @audio.PlaybackSettings::despawn()),
    )
    |> ignore
  }
}

///|
fn keyboard_input_system(
  keyboard_input : @input.ButtonInput[@window.KeyCode],
  frequency : @app.ResMut[PitchFrequency],
  play_pitch_writer : @ecs.MessageWriter[PlayPitch],
) -> Unit {
  let semitone_ratio = @math.pow(2.0F, 1.0F / 12.0F)
  let frequency_ref = frequency.get_ref()
  if keyboard_input.just_pressed(@window.KeyCode::ArrowUp) {
    frequency_ref.val.value = frequency_ref.val.value * semitone_ratio
  }
  if keyboard_input.just_pressed(@window.KeyCode::ArrowDown) {
    frequency_ref.val.value = frequency_ref.val.value / semitone_ratio
  }
  if keyboard_input.just_pressed(@window.KeyCode::Space) {
    play_pitch_writer.write_default() |> ignore
  }
}
