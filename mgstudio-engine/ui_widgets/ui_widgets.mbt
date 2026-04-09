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
/// UI-widgets API boundary aligned with Bevy crate responsibilities.
/// Keep the boundary file non-empty by anchoring the root runtime plugin.
fn _ui_widgets_runtime_anchor(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  @ui.ui_plugin(app)
}
