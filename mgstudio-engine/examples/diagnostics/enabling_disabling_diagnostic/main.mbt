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
/// Port of `bevy/examples/diagnostics/enabling_disabling_diagnostic.rs`.

///|
const TOGGLE_INTERVAL_SECONDS : Float = 10.0F

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.default_plugins())
  .add_plugin(@diagnostics.frame_time_diagnostics_plugin)
  .add_plugin(@diagnostics.log_diagnostics_plugin)
  .add_systems(
    @app.Update,
    @app.system(@app.system_param(toggle)).run_if(
      @time.on_timer(@core.Duration::from_secs_f32(TOGGLE_INTERVAL_SECONDS)),
    ),
  )
  .run()
}

///|
fn toggle(store : @app.ResMut[@diagnostics.DiagnosticsStore]) -> Unit {
  for diagnostic in store.get_ref().val.iter_mut() {
    let message = "toggling diagnostic " + diagnostic.val.path().as_str()
    @app.log_record(@app.Info, message~)
    diagnostic.val.set_enabled(!diagnostic.val.is_enabled())
  }
}
