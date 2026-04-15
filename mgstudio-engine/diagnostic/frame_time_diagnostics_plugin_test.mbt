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
fn read_frame_time_diagnostic_value(
  app : @app.App[@ecs.World],
  path : DiagnosticPath,
) -> Float {
  let store = try! app
    .world()
    .get_resource(DiagnosticsStore::resource())
    .unwrap()
  store.get(path).unwrap().value().unwrap()
}

///|
test "diagnostics: frame time diagnostics use real time instead of virtual time" {
  let mut app = @app.App::new(@ecs.World::new())
    .add_plugins(@time.TimePlugin::default())
    .add_plugins(DiagnosticsPlugin::default())
    .add_plugins(FrameCountPlugin::default())
    .add_plugins(FrameTimeDiagnosticsPlugin::default())

  app = app
    .insert_resource(
      @time.TimeUpdateStrategy::ManualDuration(
        @core.Duration::from_secs_f32(1.0F),
      ),
    )
    .run_once()
  app = app
    .insert_resource(
      @time.TimeUpdateStrategy::ManualDuration(
        @core.Duration::from_secs_f32(1.0F),
      ),
    )
    .run_once()

  debug_inspect(
    read_frame_time_diagnostic_value(app, frame_time_diagnostic_frame_time),
    content="1000",
  )
  debug_inspect(
    read_frame_time_diagnostic_value(app, frame_time_diagnostic_fps),
    content="1",
  )
}
