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
// Bevy source: `bevy/crates/bevy_audio/src/lib.rs`.

///|
pub fn audio_package_bevy_source() -> String {
  "bevy/crates/bevy_audio/src/lib.rs"
}

///|
pub fn audio_default_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  audio_plugin(app)
}

///|
pub fn audio_playback_once() -> PlaybackSettings {
  PlaybackSettings::once()
}
