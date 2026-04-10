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
// Bevy source: `bevy/crates/bevy_ui/src/widget/mod.rs`.
pub using @ui_widgets {type Interaction}

///|
pub let ecs_key_interaction : @ecs.ComponentKey[@ui_widgets.Interaction] = @ui_widgets.ecs_key_interaction

///|
pub let ui_widgets_set_interaction : @app.SystemSet = @ui_widgets.ui_widgets_set_interaction

///|
pub fn ui_interaction_system(world : @ecs.World) -> Unit {
  @ui_widgets.ui_interaction_system(world)
}

///|
pub fn ui_widgets_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  @ui_widgets.ui_widgets_plugin(app)
}
