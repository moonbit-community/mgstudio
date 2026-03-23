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
  let tick = world.advance_sequence()
  let virtual_ref = try! world
    .get_resource_ref_mut(@time.virtual_time_resource_key(), tick)
    .unwrap()
  let default_ref = try! world
    .get_resource_ref_mut(@time.default_time_resource_key(), tick)
    .unwrap()
  let next_virtual = virtual_ref.val.pause()
  virtual_ref.val = next_virtual
  default_ref.val = next_virtual.as_generic()
}

///|
fn read_log_diagnostics_state_test_resource(
  app : @app.App[@ecs.World],
) -> LogDiagnosticsState {
  try! app.world().get_resource(log_diagnostics_state_resource_key).unwrap()
}

///|
test "diagnostics: log diagnostics timer advances with real time" {
  let mut app = @app.App::new(@ecs.World::new()).add_plugins([
    @time.time_plugin, diagnostics_plugin, log_diagnostics_plugin,
  ])
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

  inspect(
    read_log_diagnostics_state_test_resource(app).timer.is_finished(),
    content="true",
  )
}
