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

// Bevy source-shape anchor: bevy/examples/showcase/stepping.rs

///|
fn font_color() -> @color.Color {
  @color.Color::srgb(0.5F, 0.5F, 0.5F)
}

///|
pub struct SteppingPlugin {
  schedule_labels : Array[@app.ScheduleStage]
  top : @ui.Val
  left : @ui.Val
}

///|
pub fn SteppingPlugin::SteppingPlugin() -> SteppingPlugin {
  { schedule_labels: [], top: @ui.auto(), left: @ui.auto() }
}

///|
pub fn SteppingPlugin::add_schedule(
  self : SteppingPlugin,
  label : @app.ScheduleStage,
) -> SteppingPlugin {
  self.schedule_labels.push(label)
  self
}

///|
pub fn SteppingPlugin::at(
  self : SteppingPlugin,
  left : @ui.Val,
  top : @ui.Val,
) -> SteppingPlugin {
  { ..self, top, left }
}

///|
pub impl @app.Plugin for SteppingPlugin with fn name(_self) {
  "mgstudio.examples.showcase.stepping.SteppingPlugin"
}

///|
pub impl @app.Plugin for SteppingPlugin with fn build(self, app) {
  ignore(self.schedule_labels)
  ignore(self.top)
  ignore(self.left)
  app.add_systems_param(Startup, build_stepping_hint)
}

///|
fn build_stepping_hint(commands : @app.Commands) -> Unit {
  let hint_text = "mgstudio was compiled without stepping support. Enable debug stepping support to use stepping."
  @app.log_info(hint_text)
  ignore(
    commands.spawn(
      (
        @text.Text::new(hint_text),
        @text.TextFont::TextFont().with_font_size(@text.FontSize::Px(15.0F)),
        @text.TextColor::new(font_color()),
        @ui.Node::Node()
        .with_position_type(Absolute)
        .with_bottom(@ui.px(5.0F))
        .with_left(@ui.px(5.0F)),
      ),
    ),
  )
}
