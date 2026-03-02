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
/// Port of `bevy/examples/app/no_renderer.rs`.
///
/// This runner opens a window and drives ECS updates, but intentionally skips
/// GPU device/surface setup and frame rendering.

///|
priv struct RunnerState {
  mut tick : @app.RunnerFn?
}

///|
let runner_state_ref : Ref[RunnerState] = Ref::new(RunnerState::{ tick: None })

///|
fn runner_tick() -> Unit {
  if runner_state_ref.val.tick is Some(tick) {
    tick()
  }
}

///|
fn no_renderer_runner_builder(app : @app.App[@ecs.World]) -> @app.RunnerFn {
  fn() {
    let window = @window.host_window_create(
      width=800,
      height=600,
      title="Moon Game Studio (No Renderer)",
    )
    @window.window_set_handle(window)
    let app_ref : Ref[@app.App[@ecs.World]] = Ref::new(app.run_startup())
    runner_state_ref.val.tick = Some(fn() {
      @window.host_window_poll_events(window)
      app_ref.val = app_ref.val.run_once()
      if @window.host_window_should_close(window) {
        @window.host_window_request_close(window)
        runner_state_ref.val.tick = None
      }
    })
    let tick_ref : FuncRef[() -> Unit] = fn() { runner_tick() }
    @window.host_window_run_loop(tick_ref)
  }
}

///|
fn no_renderer_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  app
  .set_runner(no_renderer_runner_builder)
  .add_pre_update_system(@window.window_poll_resize_system)
}

///|
pub fn game_app() -> Unit {
  @app.App::new(@ecs.World::new()).add_plugins([no_renderer_plugin]).run()
}
