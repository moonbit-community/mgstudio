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
// Bevy source: `bevy/crates/bevy_ui_render/src/lib.rs`.
pub fn ui_render_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  @render.with_render_app(app, fn(render_app) {
    let stage = @render.render_schedule_stage()
    @render.configure_base_render_sets(render_app)
    .add_systems(
      stage,
      @app.system(ui_render_extract_system_in_render_app).in_set(
        ui_render_set_extract,
      ),
    )
    .configure_set(stage, ui_render_set_extract, before=[
      @sprite_render.render2d_set_extract,
    ])
  })
}
