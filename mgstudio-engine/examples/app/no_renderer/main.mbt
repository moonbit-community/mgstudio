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
    guard @window.window_ensure_primary_host(app.world()) is Some(window) else {
      app.run_startup().update() |> ignore
      return
    }
    let app_ref : Ref[@app.App[@ecs.World]] = Ref::new(app.run_startup())
    runner_state_ref.val.tick = Some(fn() {
      @window.window_poll_host_events(app_ref.val.world())
      app_ref.val = app_ref.val.update()
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
  @window.window_plugin(app).set_runner(no_renderer_runner_builder)
}

///|
fn main {
  @app.App::new(@ecs.World::new()).add_plugins([no_renderer_plugin]).run()
}
