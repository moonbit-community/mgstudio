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
// Bevy source: `bevy/crates/bevy_dev_tools/src/ci_testing/mod.rs`.

///|
const CI_TESTING_PLUGIN_NAME : String = "mgstudio.dev_tools.CiTestingPlugin"

///|
pub struct CiTestingPlugin {}

///|
pub fn CiTestingPlugin::default() -> CiTestingPlugin {
  CiTestingPlugin::{  }
}

///|
pub impl @app.PluginReplacement for CiTestingPlugin with plugin_name(_self) {
  CI_TESTING_PLUGIN_NAME
}

///|
pub impl @app.PluginReplacement for CiTestingPlugin with world_plugin(self) {
  fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
    ci_testing_plugin_with(app, self)
  }
}

///|
priv struct CiTestingPluginMarker {}

///|
let ci_testing_plugin_marker_resource_key : @ecs.ResourceKey[
  CiTestingPluginMarker,
] = @ecs.register_resource(
  debug_name="mgstudio_dev_tools::CiTestingPluginMarker",
)

///|
fn ci_testing_env_parse_int(key : String) -> Int? {
  match @sys.get_env_var(key) {
    Some(raw) => Some(@string.parse_int(raw[:], base=10)) catch { _ => None }
    None => None
  }
}

///|
fn ci_testing_config_from_env() -> CiTestingConfig {
  let mut config = CiTestingConfig::default()
  if ci_testing_env_parse_int("CI_TESTING_SCREENSHOT_FRAME")
    is Some(capture_frame) {
    config = config.with_event(capture_frame, Screenshot)
  }
  if ci_testing_env_parse_int("CI_TESTING_SCREENSHOT_AND_EXIT_FRAME")
    is Some(capture_and_exit_frame) {
    config = config.with_event(capture_and_exit_frame, ScreenshotAndExit)
  }
  if ci_testing_env_parse_int("CI_TESTING_EXIT_FRAME") is Some(exit_frame) {
    config = config.with_event(exit_frame, AppExit)
  }
  if ci_testing_env_parse_int("CI_TESTING_FIXED_FRAME_TIME_MS")
    is Some(frame_time_ms) {
    if frame_time_ms > 0 {
      config = config.with_setup(
        config.setup.with_fixed_frame_time(
          @core.Duration::from_millis(frame_time_ms.to_int64()),
        ),
      )
    }
  }
  config
}

///|
fn ci_testing_apply_time_update_strategy(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  guard (try! app.world().get_resource(ci_testing_config_resource_key))
    is Some(config) else {
    return app
  }
  guard config.setup.fixed_frame_time is Some(fixed_frame_time) else {
    return app
  }
  app.insert_resource(
    @time.TimeUpdateStrategy::ManualDuration(fixed_frame_time),
  )
}

///|
pub fn ci_testing_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  ci_testing_plugin_with(app, CiTestingPlugin::default())
}

///|
pub fn ci_testing_plugin_with(
  app : @app.App[@ecs.World],
  plugin : CiTestingPlugin,
) -> @app.App[@ecs.World] {
  ignore(plugin)
  if app.contains_resource(ci_testing_plugin_marker_resource_key) {
    return app
  }
  let mut next = app.insert_world_resource(
    ci_testing_plugin_marker_resource_key,
    CiTestingPluginMarker::{  },
  )
  if !next.contains_resource(ci_testing_config_resource_key) {
    next = next.insert_world_resource(
      ci_testing_config_resource_key,
      ci_testing_config_from_env(),
    )
  }
  if !next.contains_resource(ci_testing_runtime_state_resource_key) {
    next = next.insert_world_resource(
      ci_testing_runtime_state_resource_key,
      CiTestingRuntimeState::default(),
    )
  }
  ci_testing_apply_time_update_strategy(next).add_system(
    ci_testing_send_events_system,
  )
}
