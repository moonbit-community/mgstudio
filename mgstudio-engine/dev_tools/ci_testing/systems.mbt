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
// Bevy source: `bevy/crates/bevy_dev_tools/src/ci_testing/systems.rs`.

///|
pub const CI_TESTING_SYSTEMS_STAGE : String = "mgstudio.dev_tools.ci_testing.systems"

///|
pub fn dev_tools_ci_testing_stage() -> String {
  CI_TESTING_SYSTEMS_STAGE
}

///|
pub(all) struct CiTestingRuntimeState {
  mut current_frame : Int
}

///|
pub fn CiTestingRuntimeState::CiTestingRuntimeState() -> CiTestingRuntimeState {
  CiTestingRuntimeState::{ current_frame: 0 }
}

///|
let ci_testing_runtime_state_resource_key : @ecs.ResourceKey[
  CiTestingRuntimeState,
] = @ecs.register_resource(
  debug_name="mgstudio_dev_tools::CiTestingRuntimeState",
)

///|
pub impl @app.Resource for CiTestingRuntimeState with fn resource() {
  ci_testing_runtime_state_resource_key
}

///|
fn ci_testing_screenshot_path_for_frame(frame : Int) -> String {
  "./screenshot-\{frame.to_string()}.png"
}

///|
fn ci_testing_screenshot_path_for_name(name : String) -> String {
  "./screenshot-\{name}.png"
}

///|
fn ci_testing_queue_screenshot(
  world : @ecs.World,
  path : String,
  exit_after_capture? : Bool = false,
) -> Unit {
  let screenshot_entity = world.spawn()
  let observer = if exit_after_capture {
    fn(event : @ecs.ComponentOn[@ecs.Insert, @window.ScreenshotCaptured]) {
      @window.save_to_disk(path)(event)
      ignore(
        event
        .world()
        .send_message(@app.AppExit::message(), @app.AppExit::Success),
      )
    }
  } else {
    @window.save_to_disk(path)
  }
  ignore(world.add_entity_component_observer(screenshot_entity, observer))
  try! world.set_by_key(
    screenshot_entity,
    @window.ecs_key_screenshot,
    @window.Screenshot::primary_window(),
  )
}

///|
fn ci_testing_apply_camera_pose(
  world : @ecs.World,
  translation : @math.Vec3,
  rotation : @math.Quat,
) -> Unit {
  let query : @ecs.QueryState[
    @ecs.Mut[@transform.Transform],
    @ecs.With[@camera.Camera],
  ] = world.query_filtered(@ecs.With::new(@camera.Camera::component()))
  let cameras = query.iter(world)
  guard (cameras.fetch_next() catch { _ => None })
    is Some((_, camera_transform)) else {
    return
  }
  let transform = camera_transform.value()
  transform.translation = translation
  transform.rotation = rotation
  camera_transform.set(transform)
}

///|
pub fn ci_testing_send_events_system(world : @ecs.World) -> Unit {
  guard world.get_resource_mut(ci_testing_config_resource_key)
    is Some(config_mut) else {
    return
  }
  guard world.get_resource_mut(ci_testing_runtime_state_resource_key)
    is Some(state_mut) else {
    return
  }

  state_mut.modify(fn(state) {
    let frame = state.current_frame
    let to_run : Array[CiTestingEvent] = []
    let remaining : Array[CiTestingEventOnFrame] = []
    config_mut.modify(fn(config) {
      for event_on_frame in config.events {
        if event_on_frame.frame == frame {
          to_run.push(event_on_frame.event)
        } else {
          remaining.push(event_on_frame)
        }
      }
      config.events = remaining
    })

    for event in to_run {
      match event {
        Screenshot =>
          ci_testing_queue_screenshot(
            world,
            ci_testing_screenshot_path_for_frame(frame),
          )
        ScreenshotAndExit =>
          ci_testing_queue_screenshot(
            world,
            ci_testing_screenshot_path_for_frame(frame),
            exit_after_capture=true,
          )
        NamedScreenshot(name) =>
          ci_testing_queue_screenshot(
            world,
            ci_testing_screenshot_path_for_name(name),
          )
        AppExit =>
          ignore(
            world.send_message(@app.AppExit::message(), @app.AppExit::Success),
          )
        MoveCamera(translation, rotation) =>
          ci_testing_apply_camera_pose(world, translation, rotation)
        Custom(payload) =>
          ignore(
            world.send_message(
              ci_testing_custom_event_message_key,
              CiTestingCustomEvent::new(payload),
            ),
          )
      }
    }
    state.current_frame = frame + 1
  })
}
