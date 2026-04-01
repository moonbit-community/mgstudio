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
fn rapier_debugdump_include_system(name : String) -> Bool {
  !name.has_prefix("pbr.") &&
  !name.has_prefix("render.") &&
  !name.has_prefix("gizmos.") &&
  !name.has_prefix("window.") &&
  !name.has_prefix("sprite.")
}

///|
fn main {
  let app = @app.App::new(@ecs.World::new()).add_plugins(
    @rapier_examples.rapier2d_default_plugins(),
  )
  let settings = @app.ScheduleGraphSettings::default().with_include_system_name(
    rapier_debugdump_include_system,
  )
  let dot = app.schedule_graph_dot(@app.PostUpdate, settings~)
  println(dot)
}
