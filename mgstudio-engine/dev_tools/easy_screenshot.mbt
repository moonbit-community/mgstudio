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
// Bevy source: `bevy/crates/bevy_dev_tools/src/easy_screenshot.rs`.

///|
pub struct EasyScreenshotConfig {
  enabled : Bool
  delay_frames : Int
}

///|
pub fn EasyScreenshotConfig::default() -> EasyScreenshotConfig {
  EasyScreenshotConfig::{ enabled: true, delay_frames: 0 }
}

///|
pub fn dev_tools_easy_screenshot_enabled(config : EasyScreenshotConfig) -> Bool {
  config.enabled
}

///|
pub(all) struct EasyScreenshotState {
  mut next_capture_index : Int
  mut pending_capture_frames : Int
}

///|
fn EasyScreenshotState::default() -> EasyScreenshotState {
  EasyScreenshotState::{ next_capture_index: 0, pending_capture_frames: -1 }
}

///|
pub impl @app.Resource for EasyScreenshotConfig with resource() {
  ecs_res_key_easy_screenshot_config
}

///|
pub impl @app.Resource for EasyScreenshotState with resource() {
  ecs_res_key_easy_screenshot_state
}

///|
priv struct EasyScreenshotPluginMarker {}

///|
let ecs_res_key_easy_screenshot_config : @ecs.ResourceKey[EasyScreenshotConfig] = @ecs.register_resource(
  debug_name="mgstudio_dev_tools::EasyScreenshotConfig",
)

///|
let ecs_res_key_easy_screenshot_state : @ecs.ResourceKey[EasyScreenshotState] = @ecs.register_resource(
  debug_name="mgstudio_dev_tools::EasyScreenshotState",
)

///|
let ecs_res_key_easy_screenshot_plugin_marker : @ecs.ResourceKey[
  EasyScreenshotPluginMarker,
] = @ecs.register_resource(
  debug_name="mgstudio_dev_tools::EasyScreenshotPluginMarker",
)

///|
fn easy_screenshot_default_path(index : Int) -> String {
  "./easy-screenshot-\{index.to_string()}.png"
}

///|
fn easy_screenshot_schedule_capture_system(
  input : @input.ButtonInput[@window.KeyCode],
  config : @app.Res[EasyScreenshotConfig],
  state : @app.ResMut[EasyScreenshotState],
) -> Unit {
  if !config.get().enabled {
    return
  }
  if state.peek().pending_capture_frames >= 0 {
    return
  }
  if !input.just_pressed(@window.KeyCode::F12) {
    return
  }
  let delay = if config.get().delay_frames < 0 {
    0
  } else {
    config.get().delay_frames
  }
  state.modify(fn(value) { value.pending_capture_frames = delay })
}

///|
fn easy_screenshot_flush_capture_system(
  config : @app.Res[EasyScreenshotConfig],
  state : @app.ResMut[EasyScreenshotState],
) -> Unit {
  if !config.get().enabled {
    return
  }
  let state_value = state.peek()
  let pending = state_value.pending_capture_frames
  if pending < 0 {
    return
  }
  if pending > 0 {
    state.modify(fn(value) { value.pending_capture_frames = pending - 1 })
    return
  }
  guard @app.current_world() is Some(world) else { return }
  let path = easy_screenshot_default_path(state_value.next_capture_index)
  let screenshot_entity = world.spawn()
  ignore(
    world.add_entity_component_observer(
      screenshot_entity,
      @window.save_to_disk(path),
    ),
  )
  try! world.set_by_key(
    screenshot_entity,
    @window.ecs_key_screenshot,
    @window.Screenshot::primary_window(),
  )
  state.modify(fn(value) {
    value.next_capture_index = value.next_capture_index + 1
    value.pending_capture_frames = -1
  })
}

///|
pub fn dev_tools_easy_screenshot_plugin(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  if app.contains_resource(ecs_res_key_easy_screenshot_plugin_marker) {
    return app
  }
  let mut next = app.insert_world_resource(
    ecs_res_key_easy_screenshot_plugin_marker,
    EasyScreenshotPluginMarker::{  },
  )
  if !next.contains_resource(ecs_res_key_easy_screenshot_config) {
    next = next.insert_world_resource(
      ecs_res_key_easy_screenshot_config,
      EasyScreenshotConfig::default(),
    )
  }
  if !next.contains_resource(ecs_res_key_easy_screenshot_state) {
    next = next.insert_world_resource(
      ecs_res_key_easy_screenshot_state,
      EasyScreenshotState::default(),
    )
  }
  next
  .add_system_param3(easy_screenshot_schedule_capture_system)
  .add_system_param2(easy_screenshot_flush_capture_system)
}
