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
fn pause_virtual_time_for_diagnostics_test(app : @app.App[@ecs.World]) -> Unit {
  let world = app.world()
  let tick = world.increment_change_tick()
  ignore(tick)
  let virtual_mut = world
    .get_resource_mut(@time.virtual_time_resource_key)
    .unwrap()
  let default_mut = world
    .get_resource_mut(@time.default_time_resource_key)
    .unwrap()
  let current_virtual = virtual_mut.peek()
  let next_virtual = current_virtual.pause()
  virtual_mut.set(next_virtual)
  default_mut.set(next_virtual.as_generic())
}

///|
fn read_log_diagnostics_state_test_resource(
  app : @app.App[@ecs.World],
) -> LogDiagnosticsState {
  app.world().get_resource(log_diagnostics_state_resource_key).unwrap()
}

///|
test "diagnostics: log diagnostics timer advances with real time" {
  let mut app = @app.App::new(@ecs.World::new())
    .add_plugins(@time.TimePlugin::TimePlugin())
    .add_plugins(DiagnosticsPlugin::DiagnosticsPlugin())
    .add_plugins(LogDiagnosticsPlugin::LogDiagnosticsPlugin())
  pause_virtual_time_for_diagnostics_test(app)

  app = app
    .insert_resource(
      @time.TimeUpdateStrategy::ManualDuration(
        @core.Duration::from_secs_f32(2.0F),
      ),
    )
    .run_once()
  app = app
    .insert_resource(
      @time.TimeUpdateStrategy::ManualDuration(
        @core.Duration::from_secs_f32(2.0F),
      ),
    )
    .run_once()

  debug_inspect(
    read_log_diagnostics_state_test_resource(app).timer.is_finished(),
    content="true",
  )
}

///|
test "diagnostics: log diagnostics sorts output by path lexicographically" {
  let app = register_diagnostic(
    register_diagnostic(
      @app.App::new(@ecs.World::new()).add_plugins(
        DiagnosticsPlugin::DiagnosticsPlugin(),
      ),
      Diagnostic::new(DiagnosticPath::const_new("z.path")),
    ),
    Diagnostic::new(DiagnosticPath::const_new("a.path")),
  )
  let store = app.world().get_resource(DiagnosticsStore::resource()).unwrap()
  let sorted = log_diagnostics_sorted(store)
  debug_inspect(sorted[0].path().as_str(), content="\"a.path\"")
  debug_inspect(sorted[1].path().as_str(), content="\"z.path\"")
}
