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
test "audio source asset registry stores bytes" {
  let app = audio_plugin(@app.App::new(@ecs.World::new()))
  let world = app.world()
  let source = AudioSource::new(b"abc")
  let handle = audio_source_add(world, source)
  inspect(audio_source_get(world, handle) is Some(_), content="true")
}

///|
test "pitch asset registry stores pitch data" {
  let app = audio_plugin(@app.App::new(@ecs.World::new()))
  let world = app.world()
  let handle = pitch_add(world, Pitch::new(440.0F, 1.0F))
  inspect(pitch_get(world, handle) is Some(_), content="true")
}
