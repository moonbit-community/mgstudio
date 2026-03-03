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
/// Port of `bevy/examples/app/externally_driven_headless_renderer.rs`.

///|
priv struct CaptureState {
  mut target : @asset.Handle[@asset.Image]?
  mut frame : Int
}

///|
let capture_state_resource_ref : Ref[@core.Resource[CaptureState]] = Ref::new(
  @core.Resource::new(),
)

///|
impl @app.Resource for CaptureState with resource() {
  capture_state_resource_ref.val
}

///|
fn setup(world : @ecs.World) -> Unit {
  let target = @render2d.render2d_create_render_target_ecs(500, 500, false)
  let tick = world.read_change_tick()
  if capture_state_resource_ref.val.get_ref_mut(tick) is Some(state) {
    state.val.target = Some(target)
  }

  // Keep minimal scene entities on the ECS world path until render3d ECS
  // bundle/runtime parity lands.
  let scene_entity = world.spawn_empty()
  try! world.set(
    scene_entity,
    @math.ecs_key_transform,
    @math.Transform::from_xyz(0.0F, 0.0F, -5.0F),
  )

  @render2d.Camera2dBundle::new(
    @render2d.Camera::default().with_order(-1),
    @math.Transform::identity(),
  ).spawn(world)
  |> ignore

  // Keep a visible camera on screen for web runtime.
  @render2d.Camera2dBundle::new(
    @render2d.Camera::default(),
    @math.Transform::identity(),
  ).spawn(world)
  |> ignore
}

///|
fn capture_system(
  state : @app.ResMut[CaptureState],
  app_exit : @core.MessageWriter[@app.AppExit],
) -> Unit {
  let state_ref = state.get_ref()
  if state_ref.val.target is Some(target) {
    if state_ref.val.frame < 10 {
      let path = "test_images/screenshot" +
        state_ref.val.frame.to_string() +
        ".png"
      @asset.asset_save_texture_png(target, path)
    }
    state_ref.val.frame = state_ref.val.frame + 1
    if state_ref.val.frame >= 12 {
      app_exit.write(@app.AppExit::Success)
    }
  }
}

///|
fn externally_driven_runner_builder(
  app : @app.App[@ecs.World],
) -> @app.RunnerFn {
  fn() {
    let window = @window.host_window_create(
      width=800,
      height=600,
      title="Moon Game Studio (Externally Driven Renderer)",
    )
    @window.window_set_handle(window)
    let device = @window.host_gpu_request_device()
    let surface = @window.host_gpu_create_surface(window)
    let width = @window.host_window_get_width(window)
    let height = @window.host_window_get_height(window)
    @window.host_gpu_configure_surface(device~, surface~, width~, height~)

    let mut runtime_app = app.run_startup()
    for _ in 0..<120 {
      @window.host_window_poll_events(window)
      let frame = @window.host_gpu_begin_frame(surface)
      runtime_app = runtime_app.run_once()
      @window.host_gpu_end_frame(frame)
      if runtime_app.should_exit() is Some(_) {
        break
      }
      if @window.host_window_should_close(window) {
        break
      }
    }
    @window.host_window_request_close(window)
  }
}

///|
pub fn game_app() -> Unit {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .insert_resource(CaptureState::{ target: None, frame: 0 })
  .add_startup_system(setup)
  .add_system_param2(capture_system)
  .set_runner(externally_driven_runner_builder)
  .run()
}
