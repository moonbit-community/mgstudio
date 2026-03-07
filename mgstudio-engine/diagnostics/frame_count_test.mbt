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
test "diagnostics: frame count plugin increments during Last" {
  let app = @app.App::new(@ecs.World::new()).add_plugins([
    diagnostics_plugin, frame_count_plugin,
  ])
  inspect(
    try! app.world().get_resource(FrameCount::resource()).unwrap().value,
    content="0",
  )
  app.run_once() |> ignore
  inspect(
    try! app.world().get_resource(FrameCount::resource()).unwrap().value,
    content="1",
  )
}

///|
test "diagnostics: entity count plugin records spawned entities" {
  let app = @app.App::new(@ecs.World::new())
  app
  .add_plugins([diagnostics_plugin, entity_count_diagnostics_plugin])
  .add_startup_system(fn(world : @ecs.World) {
    world.spawn() |> ignore
    world.spawn() |> ignore
  })
  .run_startup()
  .run_once()
  |> ignore

  let store = try! app
    .world()
    .get_resource(DiagnosticsStore::resource())
    .unwrap()
  let diagnostic = store.get(entity_count_diagnostic_path).unwrap()
  inspect(diagnostic.value().unwrap(), content="2")
}
