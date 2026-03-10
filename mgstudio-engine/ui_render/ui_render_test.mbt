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
test "ui_render boundary re-exports anti-alias and box shadow samples" {
  inspect(
    @ui_render.UiAntiAlias::On.to_json().to_string(),
    content="String(\"On\")",
  )
  inspect(@ui_render.BoxShadowSamples::default().samples, content="4")
}

///|
test "ui_render boundary re-exports render extract set" {
  inspect(
    @ui_render.ui_render_set_extract == @ui.ui_set_render_extract,
    content="true",
  )
  inspect(
    @ui_render.ui_render_set_extract ==
    @app.system_set("bevy.ui.render.extract"),
    content="true",
  )
}
