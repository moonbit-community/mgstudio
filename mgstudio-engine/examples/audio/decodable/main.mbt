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
const AUDIO_PATH : String = "sounds/Windless Slopes.ogg"

///|
struct DecodableState {
  blob : @asset.Handle[@asset.Blob]
  played : Bool
}

///|
let decodable_state_resource_key : @ecs.ResourceKey[DecodableState] = @ecs.register_resource(
  debug_name="examples.audio.decodable.DecodableState",
)

///|
pub impl @app.Resource for DecodableState with resource() {
  decodable_state_resource_key
}

///|
fn setup(
  asset_server : @app.Res[@asset.AssetServer],
  commands : @app.Commands,
) -> Unit {
  commands.insert_resource(DecodableState::{
    blob: asset_server.get().load_bytes(AUDIO_PATH),
    played: false,
  })
  commands.spawn((@sprite.Camera2d::default(), @sprite.Camera::default()))
  |> ignore
}

///|
fn play_when_decoded(
  state : @app.ResMut[DecodableState],
  audio_sources : @app.ResMut[@asset.Assets[@audio.AudioSource]],
  commands : @app.Commands,
) -> Unit {
  let state_value = state.get()
  if state_value.played {
    return
  }
  guard @audio.audio_source_from_blob(state_value.blob) is Some(source) else {
    return
  }
  let handle = audio_sources.modify(fn(value) { value.add(source) })
  commands.spawn(
    (@audio.AudioPlayer::new(handle), @audio.PlaybackSettings::despawn()),
  )
  |> ignore
  state.set(DecodableState::{ ..state_value, played: true })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_systems(@app.Startup, @app.system(@app.system_param2(setup)))
  .add_systems(@app.Update, @app.system(@app.system_param3(play_when_decoded)))
  .run()
}
