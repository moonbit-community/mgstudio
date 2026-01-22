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
pub type SystemFn = () -> Unit

///|
pub type Plugin = (App) -> App

///|
pub(open) trait SystemParam {
  get() -> Self
}

///|
pub fn[P : SystemParam] system_param(system : (P) -> Unit) -> SystemFn {
  fn() {
    let param : P = SystemParam::get()
    system(param)
  }
}

///|
pub type RunnerFn = () -> Unit

///|
pub type RunnerBuilder = (App) -> RunnerFn

///|
pub struct Schedule {
  startup : Array[SystemFn]
  update : Array[SystemFn]
  post_update : Array[SystemFn]
}

///|
pub struct App {
  schedule : Schedule
  runner : RunnerFn?
}

///|
pub fn App::new() -> App {
  App::{
    schedule: Schedule::{ startup: [], update: [], post_update: [] },
    runner: None,
  }
}

///|
pub fn App::add_plugins(self : App, plugins : Array[Plugin]) -> App {
  let mut app = self
  for plugin in plugins {
    app = plugin(app)
  }
  app
}

///|
pub fn App::add_startup_system(self : App, system : SystemFn) -> App {
  self.schedule.startup.push(system)
  self
}

///|
pub fn[P : SystemParam] App::add_startup_system_param(
  self : App,
  system : (P) -> Unit,
) -> App {
  self.schedule.startup.push(system_param(system))
  self
}

///|
pub fn App::add_system(self : App, system : SystemFn) -> App {
  self.schedule.update.push(system)
  self
}

///|
pub fn[P : SystemParam] App::add_system_param(
  self : App,
  system : (P) -> Unit,
) -> App {
  self.schedule.update.push(system_param(system))
  self
}

///|
pub fn App::add_post_update_system(self : App, system : SystemFn) -> App {
  self.schedule.post_update.push(system)
  self
}

///|
pub fn[P : SystemParam] App::add_post_update_system_param(
  self : App,
  system : (P) -> Unit,
) -> App {
  self.schedule.post_update.push(system_param(system))
  self
}

///|
fn run_systems(systems : Array[SystemFn]) -> Unit {
  for system in systems {
    system()
  }
}

///|
pub fn App::run_startup(self : App) -> App {
  run_systems(self.schedule.startup)
  self
}

///|
pub fn App::run_once(self : App) -> App {
  run_systems(self.schedule.update)
  run_systems(self.schedule.post_update)
  self
}

///|
pub fn App::run(self : App) -> Unit {
  if self.runner is Some(runner) {
    runner()
  } else {
    self.run_startup().run_once() |> ignore
  }
}

///|
pub fn App::set_runner(self : App, builder : RunnerBuilder) -> App {
  let runner = builder(self)
  App::{ ..self, runner: Some(runner) }
}
