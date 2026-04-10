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
  debug_inspect(audio_source_get(world, handle) is Some(_), content="true")
}

///|
test "audio source AssetServer loader registers direct handle flow" {
  let loaded_handle_ids : Array[Int] = []
  let loaded_lengths : Array[Int] = []
  let mut app = @asset.asset_plugin(@app.App::new(@ecs.World::new()))
  app = audio_plugin(app)
  app = app.add_systems(
    @app.Startup,
    @app.system(fn(world : @ecs.World) {
      let asset_server = @asset.AssetServer::new()
      let first : @asset.Handle[AudioSource] = asset_server.load(
        "textures/rpg/folder.txt",
      )
      let second : @asset.Handle[AudioSource] = asset_server.load(
        "textures/rpg/folder.txt",
      )
      loaded_handle_ids.push(first.id())
      loaded_handle_ids.push(second.id())
      guard audio_source_get(world, first) is Some(source) else {
        abort("missing audio source after AssetServer::load")
      }
      loaded_lengths.push(source.bytes().length())
    }),
  )

  app = app.update()

  debug_inspect(loaded_handle_ids.length(), content="2")
  debug_inspect(loaded_handle_ids[0] == loaded_handle_ids[1], content="true")
  debug_inspect(loaded_lengths.length(), content="1")
  debug_inspect(loaded_lengths[0] > 0, content="true")
}

///|
test "pitch asset registry stores pitch data" {
  let app = audio_plugin(@app.App::new(@ecs.World::new()))
  let world = app.world()
  let handle = pitch_add(world, Pitch::new(440.0F, 1.0F))
  debug_inspect(pitch_get(world, handle) is Some(_), content="true")
}
