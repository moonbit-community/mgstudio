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
test "ui_widgets boundary re-exports widget markers and interaction" {
  @ui_widgets.Button::default() |> ignore
  @ui_widgets.Label::default() |> ignore
  inspect(
    @ui_widgets.Interaction::Hovered.to_json().to_string(),
    content="String(\"Hovered\")",
  )
}

///|
test "ui_widgets boundary re-exports interaction set and ecs keys" {
  inspect(
    @ui_widgets.ui_widgets_set_interaction == @ui.ui_set_interaction,
    content="true",
  )
  let app = @app.App::new(@ecs.World::new())
  @ui_widgets.ui_widgets_plugin(app) |> ignore
  inspect(true, content="true")
}
