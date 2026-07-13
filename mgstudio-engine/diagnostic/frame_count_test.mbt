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
  let lifecycle_world_15_0 = @ecs.World::new()
  defer lifecycle_world_15_0.close()
  let app = @app.App::new(lifecycle_world_15_0)
    .add_plugins(DiagnosticsPlugin::DiagnosticsPlugin())
    .add_plugins(FrameCountPlugin::FrameCountPlugin())
  debug_inspect(
    app.world().get_resource(FrameCount::resource()).unwrap().value,
    content="0",
  )
  app.run_once() |> ignore
  debug_inspect(
    app.world().get_resource(FrameCount::resource()).unwrap().value,
    content="1",
  )
}

///|
test "diagnostics: entity count plugin records spawned entities" {
  let lifecycle_world_31_0 = @ecs.World::new()
  defer lifecycle_world_31_0.close()
  let app = @app.App::new(lifecycle_world_31_0)
  app
  .add_plugins(DiagnosticsPlugin::DiagnosticsPlugin())
  .add_plugins(EntityCountDiagnosticsPlugin::EntityCountDiagnosticsPlugin())
  .add_startup_system(fn(world : @ecs.World) {
    world.spawn() |> ignore
    world.spawn() |> ignore
  })
  .run_startup()
  .run_once()
  |> ignore

  let store = app.world().get_resource(DiagnosticsStore::resource()).unwrap()
  let diagnostic = store.get(entity_count_diagnostic_path).unwrap()
  debug_inspect(diagnostic.value().unwrap(), content="2")
}
