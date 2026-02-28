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
fn setup(world : @ecs_world.World) -> Unit {
  let target = @render2d.render2d_create_render_target(world, 500, 500, false)
  let tick = world.read_change_tick()
  if capture_state_resource_ref.val.get_ref_mut(tick) is Some(state) {
    state.val.target = Some(target)
  }

  let material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(1.0F, 1.0F, 1.0F, 1.0F),
    ).with_unlit(true),
  )
  @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_cuboid(2.0F, 2.0F, 2.0F),
    @render3d.MeshMaterial3d::new(material),
    @math.Transform::from_xyz(0.0F, 0.0F, -5.0F),
  ).spawn(world)
  |> ignore

  let camera_offscreen = @render3d.Camera3dBundle::new(
    @render2d.Camera::default(),
    @math.Transform::identity(),
  ).spawn(world)
  world
  .get_render_target_store()
  .insert(camera_offscreen, @render2d.RenderTarget::Image(target), tick)

  // Keep a visible camera on screen for web runtime.
  @render3d.Camera3dBundle::new(
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
  app : @app.App[@ecs_world.World],
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
  let plugins : Array[@app.Plugin[@ecs_world.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs_world.World::new())
  .add_plugins(plugins)
  .insert_resource(CaptureState::{ target: None, frame: 0 })
  .add_startup_system(setup)
  .add_system_param2(capture_system)
  .set_runner(externally_driven_runner_builder)
  .run()
}
